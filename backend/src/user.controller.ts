import { BadRequestException, Body, ConflictException, Controller, Get, NotFoundException, Patch, Post, UseGuards } from '@nestjs/common';
import { AuthGuard } from './auth/auth.guard';
import { CurrentUser } from './auth/current-user.decorator';
import { DatabaseService } from './supabase/database.service';
import { AnswerDto, RedeemRewardDto, SubmitQuestionnaireDto, UpdateMedicalProfileDto, UpdateProfileDto } from './user.dto';

@UseGuards(AuthGuard)
@Controller('me')
export class UserController {
  constructor(private readonly database: DatabaseService) {}

  @Get()
  async getMe(@CurrentUser() user: { id: string; email: string | undefined }) {
    return this.database.asUser(user.id, async (db) => {
      const result = await db.query(
        `select p.id, p.first_name, p.second_name, p.last_name, p.second_last_name, p.phone, p.birth_date, p.blood_type, p.gender,
                p.address, p.city, p.department, p.avatar_path, p.created_at, p.updated_at,
                coalesce((select sum(l.points) from public.points_ledger l where l.user_id = p.id), 0)::bigint as points_balance
         from public.profiles p where p.id = $1`,
        [user.id],
      );
      if (!result.rows[0]) throw new NotFoundException('No se encontró el perfil.');
      return { ...result.rows[0], email: user.email };
    });
  }

  @Patch()
  updateMe(@CurrentUser() user: { id: string }, @Body() dto: UpdateProfileDto) {
    const columns: Record<string, string> = {
      firstName: 'first_name', secondName: 'second_name', lastName: 'last_name', secondLastName: 'second_last_name', phone: 'phone', birthDate: 'birth_date',
      bloodType: 'blood_type', gender: 'gender', address: 'address', city: 'city', department: 'department',
    };
    const entries = Object.entries(dto).filter(([key, value]) => columns[key] && value !== undefined);
    if (!entries.length) throw new BadRequestException('Envía al menos un campo para actualizar.');
    const setClause = entries.map(([key], index) => `${columns[key]} = $${index + 2}`).join(', ');
    const values = entries.map(([, value]) => value);
    return this.database.asUser(user.id, async (db) => {
      const result = await db.query(
        `update public.profiles set ${setClause} where id = $1 returning id, first_name, second_name, last_name, second_last_name, phone, birth_date, blood_type, gender, address, city, department, avatar_path, updated_at`,
        [user.id, ...values],
      );
      if (!result.rows[0]) throw new NotFoundException('No se encontró el perfil.');
      const profile = result.rows[0];
      const requiredNames = ['first_name', 'second_name', 'last_name', 'second_last_name'];
      if (requiredNames.some((field) => typeof profile[field] !== 'string' || !(profile[field] as string).trim())) {
        throw new BadRequestException('Completa tus dos nombres y tus dos apellidos para guardar el perfil.');
      }
      return profile;
    });
  }

  @Get('medical')
  async getMedicalProfile(@CurrentUser() user: { id: string }) {
    return this.database.asUser(user.id, async (db) => {
      const result = await db.query(
        `select medications, conditions, allergies, is_completed, updated_at
         from public.medical_profiles where user_id = $1`, [user.id],
      );
      return result.rows[0] ?? { medications: '', conditions: '', allergies: '', is_completed: false };
    });
  }

  @Patch('medical')
  updateMedicalProfile(@CurrentUser() user: { id: string }, @Body() dto: UpdateMedicalProfileDto) {
    const columns: Record<string, string> = {
      medications: 'medications',
      conditions: 'conditions',
      allergies: 'allergies',
    };
    const entries = Object.entries(dto).filter(([key, value]) => columns[key] && value !== undefined);
    if (!entries.length) throw new BadRequestException('Envía los datos médicos que deseas guardar.');
    const assignments = entries.map(([key]) => `${columns[key]} = excluded.${columns[key]}`).join(', ');
    return this.database.asUser(user.id, async (db) => {
      const result = await db.query(
        `insert into public.medical_profiles (user_id, medications, conditions, allergies, is_completed)
         values ($1, $2, $3, $4, true)
         on conflict (user_id) do update set ${assignments}, is_completed = true
         returning medications, conditions, allergies, is_completed, updated_at`,
        [user.id, dto.medications ?? '', dto.conditions ?? '', dto.allergies ?? ''],
      );
      return result.rows[0];
    });
  }

  @Get('donations')
  donations(@CurrentUser() user: { id: string }) {
    return this.database.asUser(user.id, async (db) => {
      const result = await db.query(
        `select d.id, d.status, d.scheduled_at, d.donated_at, d.volume_ml, d.created_at,
                c.id as center_id, c.name as center_name, c.city as center_city
         from public.donations d left join public.donation_centers c on c.id = d.center_id
         where d.user_id = $1 order by d.created_at desc limit 100`, [user.id],
      );
      return result.rows;
    });
  }

  @Get('points')
  points(@CurrentUser() user: { id: string }) {
    return this.database.asUser(user.id, async (db) => {
      const result = await db.query(
        `select coalesce(sum(points), 0)::bigint as balance,
                coalesce(jsonb_agg(jsonb_build_object('id', id, 'type', entry_type, 'points', points, 'description', description, 'createdAt', created_at) order by created_at desc) filter (where id is not null), '[]'::jsonb) as history
         from public.points_ledger where user_id = $1`, [user.id],
      );
      return result.rows[0];
    });
  }

  @Get('redemptions')
  redemptions(@CurrentUser() user: { id: string }) {
    return this.database.asUser(user.id, async (db) => {
      const result = await db.query(
        `select rr.id, rr.reward_id, r.name as reward_name, rr.points_spent, rr.status, rr.redemption_code, rr.expires_at, rr.created_at
         from public.reward_redemptions rr join public.rewards r on r.id = rr.reward_id
         where rr.user_id = $1 order by rr.created_at desc limit 100`, [user.id],
      );
      return result.rows;
    });
  }

  @Post('redemptions')
  async redeem(@CurrentUser() user: { id: string }, @Body() dto: RedeemRewardDto) {
    if ((dto.quantity ?? 1) !== 1) throw new BadRequestException('Por ahora cada canje se procesa de uno en uno.');
    try {
      return await this.database.asUser(user.id, async (db) => {
        const reward = await db.query(
          `select id, points_cost from public.rewards where id = $1 and status = 'active'
           and (available_from is null or available_from <= now()) and (available_until is null or available_until > now())`,
          [dto.rewardId],
        );
        if (!reward.rows[0]) throw new NotFoundException('La recompensa no existe o no está disponible.');
        const result = await db.query(
          `insert into public.reward_redemptions (user_id, reward_id, points_spent)
           values ($1, $2, $3)
           returning id, reward_id, points_spent, status, redemption_code, expires_at, created_at`,
          [user.id, dto.rewardId, reward.rows[0].points_cost],
        );
        return result.rows[0];
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : '';
      if (message.includes('Saldo insuficiente')) throw new BadRequestException('No tienes puntos suficientes para este canje.');
      if (message.includes('Recompensa agotada')) throw new ConflictException('La recompensa se agotó.');
      if (message.includes('La recompensa no está disponible')) throw new ConflictException('La recompensa ya no está disponible.');
      throw error;
    }
  }

  @Get('questionnaire')
  questionnaire(@CurrentUser() user: { id: string }) {
    return this.database.asUser(user.id, async (db) => {
      const active = await db.query(
        `select v.id, v.version, v.language, coalesce(jsonb_agg(jsonb_build_object('id', q.id, 'code', q.code, 'category', q.category, 'prompt', q.prompt, 'answerType', q.answer_type, 'options', q.options, 'required', q.is_required, 'order', q.display_order) order by q.display_order) filter (where q.id is not null), '[]'::jsonb) as questions
         from public.health_questionnaire_versions v left join public.health_questions q on q.version_id = v.id
         where v.status = 'active' group by v.id order by v.effective_at desc nulls last limit 1`,
      );
      const previous = await db.query(
        `select id, version_id, status, submitted_at, reviewed_at, created_at
         from public.health_questionnaire_submissions where user_id = $1 order by created_at desc limit 1`, [user.id],
      );
      return { active: active.rows[0] ?? null, latestSubmission: previous.rows[0] ?? null };
    });
  }

  @Post('questionnaire')
  submitQuestionnaire(@CurrentUser() user: { id: string }, @Body() dto: SubmitQuestionnaireDto) {
    if (dto.answers.length > 100) throw new BadRequestException('El cuestionario excede el número de respuestas permitido.');
    const unique = new Set(dto.answers.map((answer) => answer.questionId));
    if (unique.size !== dto.answers.length) throw new BadRequestException('No repitas preguntas en el mismo envío.');
    return this.database.asUser(user.id, async (db) => {
      const questions = await db.query(
        `select id, is_required from public.health_questions where version_id = $1`, [dto.versionId],
      );
      if (!questions.rows.length) throw new NotFoundException('Versión de cuestionario no disponible.');
      const validIds = new Set(questions.rows.map((question) => question.id as string));
      if (dto.answers.some((answer) => !validIds.has(answer.questionId))) throw new BadRequestException('El envío contiene preguntas que no pertenecen a esa versión.');
      const sentIds = new Set(dto.answers.map((answer) => answer.questionId));
      if (questions.rows.some((question) => question.is_required && !sentIds.has(question.id as string))) throw new BadRequestException('Responde todas las preguntas obligatorias.');

      const submission = await db.query(
        `insert into public.health_questionnaire_submissions (user_id, version_id, status)
         values ($1, $2, 'draft') returning id`, [user.id, dto.versionId],
      );
      const submissionId = submission.rows[0].id as string;
      for (const answer of dto.answers as AnswerDto[]) {
        await db.query(
          `insert into public.health_questionnaire_answers (submission_id, question_id, answer) values ($1, $2, $3::jsonb)`,
          [submissionId, answer.questionId, JSON.stringify(answer.answer)],
        );
      }
      const saved = await db.query(
        `update public.health_questionnaire_submissions set status = 'submitted', submitted_at = now() where id = $1 returning id, version_id, status, submitted_at`,
        [submissionId],
      );
      return saved.rows[0];
    });
  }
}
