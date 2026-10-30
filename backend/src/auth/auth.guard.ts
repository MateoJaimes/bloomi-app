import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { Request } from 'express';
import { SupabaseService } from '../supabase/supabase.service';

export interface AuthenticatedRequest extends Request {
  user: { id: string; email: string | undefined };
}

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private readonly supabase: SupabaseService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const authorization = request.headers.authorization;
    const token = authorization?.startsWith('Bearer ') ? authorization.slice(7) : undefined;
    if (!token) throw new UnauthorizedException('Falta el token Bearer de Supabase Auth.');

    const { data, error } = await this.supabase.authClient.auth.getUser(token);
    if (error || !data.user) throw new UnauthorizedException('La sesión no es válida o ya expiró.');
    request.user = { id: data.user.id, email: data.user.email };
    return true;
  }
}
