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

export async function runMigrations(): Promise<void> {
  const p = getPool();

  // Create composio_connections table if not exists
  await p.query(`
    CREATE TABLE IF NOT EXISTS homeos.composio_connections (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      workspace_id UUID NOT NULL REFERENCES homeos.workspaces(id) ON DELETE CASCADE,
      user_id UUID NOT NULL REFERENCES homeos.users(id) ON DELETE CASCADE,
      app_id VARCHAR(100) NOT NULL,
      app_name VARCHAR(255) NOT NULL,
      connection_id VARCHAR(255) NOT NULL,
      status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'revoked', 'pending')),
      scopes TEXT[],
      account_identifier VARCHAR(255),
      connected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      expires_at TIMESTAMPTZ,
      metadata JSONB DEFAULT '{}',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      UNIQUE(workspace_id, user_id, app_id)
    )
  `);

  await p.query(`CREATE INDEX IF NOT EXISTS idx_composio_connections_workspace ON homeos.composio_connections(workspace_id)`);
  await p.query(`CREATE INDEX IF NOT EXISTS idx_composio_connections_user ON homeos.composio_connections(user_id)`);
  await p.query(`CREATE INDEX IF NOT EXISTS idx_composio_connections_app ON homeos.composio_connections(app_id)`);

  // Create oauth_states table if not exists
  await p.query(`
    CREATE TABLE IF NOT EXISTS homeos.oauth_states (
      state_token VARCHAR(64) PRIMARY KEY,
      workspace_id UUID NOT NULL REFERENCES homeos.workspaces(id) ON DELETE CASCADE,
      user_id UUID NOT NULL REFERENCES homeos.users(id) ON DELETE CASCADE,
      app_id VARCHAR(100) NOT NULL,
      redirect_url TEXT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      expires_at TIMESTAMPTZ NOT NULL
    )
  `);

  await p.query(`CREATE INDEX IF NOT EXISTS idx_oauth_states_expires ON homeos.oauth_states(expires_at)`);

  console.log('Migrations completed successfully');
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
