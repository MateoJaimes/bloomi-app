import { BadRequestException, Injectable } from '@nestjs/common';
import { createHmac } from 'node:crypto';
import { ConfigService } from '@nestjs/config';
import type { Session } from '@supabase/supabase-js';
import { ApiDocumentType, LoginDto, RegisterDto } from './auth.dto';
import { SupabaseService } from '../supabase/supabase.service';
import { DatabaseService } from '../supabase/database.service';

@Injectable()
export class AuthService {
  private readonly supabaseUrl: string;
  private readonly anonKey: string;

  constructor(
    private readonly supabase: SupabaseService,
    private readonly database: DatabaseService,
    config: ConfigService,
  ) {
    this.supabaseUrl = config.getOrThrow<string>('SUPABASE_URL').replace(/\/$/, '');
    this.anonKey = config.getOrThrow<string>('SUPABASE_ANON_KEY');
  }

  async register(dto: RegisterDto) {
    const normalizedNumber = dto.documentNumber.normalize('NFKC').replace(/[\s.-]/g, '').toUpperCase();
    const documentHash = createHmac('sha256', this.supabase.documentHmacSecret)
      .update(`${dto.documentType}:${normalizedNumber}`)
      .digest('hex');

    const alreadyUsed = await this.database.queryAsSystem(
      'select 1 from public.identity_documents where document_hash = $1 limit 1',
      [documentHash],
    );
    if (alreadyUsed.rowCount) throw new BadRequestException('No fue posible registrar esos datos.');

    const { data, error } = await this.supabase.authClient.auth.signUp({
      email: dto.email.trim().toLowerCase(),
      password: dto.password,
    });
    if (error || !data.user || data.user.identities?.length === 0) {
      throw new BadRequestException('No fue posible crear la cuenta. Revisa los datos e inténtalo de nuevo.');
    }

    try {
      await this.database.queryAsSystem(
        'insert into public.identity_documents (user_id, document_type, document_hash) values ($1, $2, $3)',
        [data.user.id, dto.documentType, documentHash],
      );
    } catch (insertError) {
      await this.supabase.adminClient.auth.admin.deleteUser(data.user.id);
      if (isUniqueViolation(insertError)) {
        throw new BadRequestException('Ya existe una cuenta asociada a ese documento.');
      }
      throw insertError;
    }

    return {
      user: { id: data.user.id, email: data.user.email },
      session: data.session ? toSession(data.session) : null,
      emailConfirmationRequired: data.session === null,
    };
  }

  async login(dto: LoginDto) {
    const { data, error } = await this.supabase.authClient.auth.signInWithPassword({
      email: dto.email.trim().toLowerCase(),
      password: dto.password,
    });
    if (error || !data.session || !data.user) {
      throw new BadRequestException('Correo o contraseña incorrectos, o cuenta pendiente de confirmación.');
    }
    return { user: { id: data.user.id, email: data.user.email }, session: toSession(data.session) };
  }

  async refresh(refreshToken: string) {
    const { data, error } = await this.supabase.authClient.auth.refreshSession({ refresh_token: refreshToken });
    if (error || !data.session || !data.user) throw new BadRequestException('La sesión venció. Inicia sesión de nuevo.');
    return { user: { id: data.user.id, email: data.user.email }, session: toSession(data.session) };
  }

  async logout(accessToken: string): Promise<{ ok: true }> {
    const response = await fetch(`${this.supabaseUrl}/auth/v1/logout`, {
      method: 'POST',
      headers: { apikey: this.anonKey, Authorization: `Bearer ${accessToken}` },
    });
    if (!response.ok) throw new BadRequestException('No fue posible cerrar la sesión.');
    return { ok: true };
  }
}

function isUniqueViolation(error: unknown): boolean {
  return typeof error === 'object' && error !== null && 'code' in error && error.code === '23505';
}

function toSession(session: Session) {
  return {
    accessToken: session.access_token,
    refreshToken: session.refresh_token,
    expiresIn: session.expires_in,
    tokenType: session.token_type,
  };
}

export { ApiDocumentType };
