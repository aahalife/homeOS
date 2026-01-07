/**
 * Database utility for PostgreSQL with pgvector
 */

import pg from 'pg';

let dbPool: pg.Pool | null = null;

export function getDatabase(): pg.Pool | null {
  if (!dbPool && process.env['DATABASE_URL']) {
    dbPool = new pg.Pool({
      connectionString: process.env['DATABASE_URL'],
      max: 10,
      idleTimeoutMillis: 30000,
    });
  }
  return dbPool;
}

export async function closeDatabase(): Promise<void> {
  if (dbPool) {
    await dbPool.end();
    dbPool = null;
  }
}
