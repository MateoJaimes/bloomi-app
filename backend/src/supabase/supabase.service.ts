import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService {
  readonly authClient: SupabaseClient;
  readonly adminClient: SupabaseClient;
  readonly documentHmacSecret: string;

  constructor(config: ConfigService) {
    const url = config.get<string>('SUPABASE_URL');
    const anonKey = config.get<string>('SUPABASE_ANON_KEY');
    const serviceRoleKey = config.get<string>('SUPABASE_SERVICE_ROLE_KEY');
    const documentSecret = config.get<string>('DOCUMENT_HMAC_SECRET');
    if (!url || !anonKey || !serviceRoleKey || !documentSecret || documentSecret.length < 32) {
      throw new ServiceUnavailableException('Falta configurar Supabase o DOCUMENT_HMAC_SECRET en backend/.env.');
    }
    const options = { auth: { autoRefreshToken: false, persistSession: false, detectSessionInUrl: false } };
    this.authClient = createClient(url, anonKey, options);
    this.adminClient = createClient(url, serviceRoleKey, options);
    this.documentHmacSecret = documentSecret;
  }
}
