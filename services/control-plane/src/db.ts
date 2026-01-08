import pg from 'pg';

const { Pool } = pg;

const DATABASE_URL = process.env['DATABASE_URL'] ?? 'postgresql://homeos:homeos_dev@localhost:5432/homeos';

let pool: pg.Pool | null = null;

export function getPool(): pg.Pool {
  if (!pool) {
    pool = new Pool({
      connectionString: DATABASE_URL,
    });

    pool.on('error', (err) => {
      console.error('Unexpected error on idle client', err);
    });
  }
  return pool;
}

export async function query<T>(text: string, params?: unknown[]): Promise<T[]> {
  const result = await getPool().query(text, params);
  return result.rows as T[];
}

export async function queryOne<T>(text: string, params?: unknown[]): Promise<T | null> {
  const result = await getPool().query(text, params);
  return (result.rows[0] as T) ?? null;
}

export async function execute(text: string, params?: unknown[]): Promise<number> {
  const result = await getPool().query(text, params);
  return result.rowCount ?? 0;
}
