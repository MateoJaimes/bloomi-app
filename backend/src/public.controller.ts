import { Controller, Get, Query } from '@nestjs/common';
import { DatabaseService } from './supabase/database.service';

@Controller()
export class PublicController {
  constructor(private readonly database: DatabaseService) {}

  @Get('centers')
  centers(@Query('city') city?: string, @Query('department') department?: string) {
    return this.database.asPublic(async (db) => {
      const result = await db.query(
        `select id, institution_id, name, description, address, city, department, latitude, longitude, phone, email, opening_hours
         from public.donation_centers
         where is_published = true and ($1::text is null or city ilike $1) and ($2::text is null or department ilike $2)
         order by city, name limit 100`,
        [city?.trim() || null, department?.trim() || null],
      );
      return result.rows;
    });
  }

  @Get('rewards')
  rewards() {
    return this.database.asPublic(async (db) => {
      const result = await db.query(
        `select id, institution_id, name, description, points_cost, inventory, terms, image_path, available_from, available_until
         from public.rewards
         where status = 'active' and (available_from is null or available_from <= now()) and (available_until is null or available_until > now())
         order by points_cost, name limit 100`,
      );
      return result.rows;
    });
  }
}
