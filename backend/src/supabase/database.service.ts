import { Injectable, OnModuleDestroy, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { Pool, PoolClient, QueryResult, QueryResultRow } from 'pg';

@Injectable()
export class DatabaseService implements OnModuleDestroy {
  private readonly pool: Pool;

  constructor(config: ConfigService) {
    const connectionString = config.get<string>('DATABASE_URL');
    if (!connectionString) throw new ServiceUnavailableException('Falta DATABASE_URL en backend/.env.');

    // pg-connection-string can replace the `ssl` option when sslmode is also in
    // the URL. Remove URL SSL parameters and trust Supabase's published root CA
    // while keeping certificate and hostname verification enabled.
    const parsedConnection = new URL(connectionString);
    for (const parameter of ['sslmode', 'sslrootcert', 'sslcert', 'sslkey']) {
      parsedConnection.searchParams.delete(parameter);
    }
    const caCertificatePath = config.get<string>('DATABASE_CA_CERT') ?? 'certs/supabase-prod-ca-2021.crt';
    const caCertificate = readFileSync(resolve(process.cwd(), caCertificatePath), 'utf8');

    this.pool = new Pool({
      connectionString: parsedConnection.toString(),
      max: 5,
      idleTimeoutMillis: 30_000,
      connectionTimeoutMillis: 8_000,
      ssl: { ca: caCertificate, rejectUnauthorized: true },
    });
  }

  async asUser<T>(userId: string, operation: (client: PoolClient) => Promise<T>): Promise<T> {
    const client = await this.pool.connect();
    try {
      await client.query('begin');
      await client.query("select set_config('request.jwt.claim.sub', $1, true)", [userId]);
      await client.query("select set_config('request.jwt.claims', $1, true)", [JSON.stringify({ sub: userId, role: 'authenticated' })]);
      await client.query('set local role authenticated');
      const result = await operation(client);
      await client.query('commit');
      return result;
    } catch (error) {
      await client.query('rollback');
      throw error;
    } finally {
      client.release();
    }
  }

  async asPublic<T>(operation: (client: PoolClient) => Promise<T>): Promise<T> {
    const client = await this.pool.connect();
    try {
      await client.query('begin');
      await client.query("select set_config('request.jwt.claims', $1, true)", [JSON.stringify({ role: 'anon' })]);
      await client.query('set local role anon');
      const result = await operation(client);
      await client.query('commit');
      return result;
    } catch (error) {
      await client.query('rollback');
      throw error;
    } finally {
      client.release();
    }
  }

  async queryAsSystem<Row extends QueryResultRow = QueryResultRow>(sql: string, values: unknown[] = []): Promise<QueryResult<Row>> {
    return this.pool.query<Row>(sql, values);
  }

  async onModuleDestroy(): Promise<void> {
    await this.pool.end();
  }
}
