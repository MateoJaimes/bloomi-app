import { createHmac } from 'node:crypto';
import { AuthService } from '../src/auth/auth.service';

describe('AuthService', () => {
  const secret = 'unit-test-document-hmac-secret-32';
  const signUp = jest.fn();
  const queryAsSystem = jest.fn();
  let service: AuthService;

  beforeEach(() => {
    jest.clearAllMocks();
    signUp.mockResolvedValue({
      data: { user: { id: 'user-1', email: 'donor@example.com' }, session: null },
      error: null,
    });
    queryAsSystem.mockResolvedValue({ rowCount: 0, rows: [] });
    const supabase = {
      documentHmacSecret: secret,
      authClient: { auth: { signUp } },
    } as never;
    const database = { queryAsSystem } as never;
    const config = { getOrThrow: (key: string) => ({ SUPABASE_URL: 'https://demo.supabase.co', SUPABASE_ANON_KEY: 'anon' })[key] } as never;
    service = new AuthService(supabase, database, config);
  });

  it('stores only a keyed hash of a normalized identity document', async () => {
    await service.register({
      email: ' DONOR@example.com ',
      password: 'password-not-recorded',
      documentType: 'cc' as never,
      documentNumber: ' 1.234.567-890 ',
    });

    const expected = createHmac('sha256', secret).update('cc:1234567890').digest('hex');
    expect(queryAsSystem).toHaveBeenCalledWith(
      'select 1 from public.identity_documents where document_hash = $1 limit 1',
      [expected],
    );
    expect(queryAsSystem).toHaveBeenCalledWith(
      'insert into public.identity_documents (user_id, document_type, document_hash) values ($1, $2, $3)',
      ['user-1', 'cc', expected],
    );
    expect(signUp).toHaveBeenCalledWith({ email: 'donor@example.com', password: 'password-not-recorded' });
  });

  it('does not attempt Supabase signup if that document hash is already used', async () => {
    queryAsSystem.mockResolvedValueOnce({ rowCount: 1, rows: [{}] });
    await expect(service.register({
      email: 'donor@example.com', password: 'password-not-recorded',
      documentType: 'cc' as never, documentNumber: '1234567890',
    })).rejects.toThrow('No fue posible registrar esos datos.');
    expect(signUp).not.toHaveBeenCalled();
  });
});
