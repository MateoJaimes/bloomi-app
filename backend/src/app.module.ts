import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthGuard } from './auth/auth.guard';
import { AuthController } from './auth/auth.controller';
import { AuthService } from './auth/auth.service';
import { HealthController } from './health.controller';
import { PublicController } from './public.controller';
import { UserController } from './user.controller';
import { DatabaseService } from './supabase/database.service';
import { SupabaseService } from './supabase/supabase.service';

@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true })],
  controllers: [HealthController, AuthController, PublicController, UserController],
  providers: [SupabaseService, DatabaseService, AuthService, AuthGuard],
})
export class AppModule {}
