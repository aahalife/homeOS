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

  // Create onboarding_inference table if not exists
  await p.query(`
    CREATE TABLE IF NOT EXISTS homeos.onboarding_inference (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      workspace_id UUID REFERENCES homeos.workspaces(id) ON DELETE SET NULL,
      user_id UUID NOT NULL REFERENCES homeos.users(id) ON DELETE CASCADE,
      payload JSONB NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);

  await p.query(`CREATE INDEX IF NOT EXISTS idx_onboarding_inference_workspace ON homeos.onboarding_inference(workspace_id)`);
  await p.query(`CREATE INDEX IF NOT EXISTS idx_onboarding_inference_user ON homeos.onboarding_inference(user_id)`);

  // Ensure workspace_secrets provider supports modal
  await p.query(`
    DO $$
    BEGIN
      IF to_regclass('homeos.workspace_secrets') IS NOT NULL THEN
        BEGIN
          ALTER TABLE homeos.workspace_secrets
            DROP CONSTRAINT IF EXISTS workspace_secrets_provider_check;
        EXCEPTION WHEN undefined_object THEN
          NULL;
        END;

        ALTER TABLE homeos.workspace_secrets
          ADD CONSTRAINT workspace_secrets_provider_check
          CHECK (provider IN ('openai', 'anthropic', 'modal'));
      END IF;
    END $$;
  `);

  // Ensure action_envelopes has workflow_id and signal_name columns
  await p.query(`
    DO $$
    BEGIN
      IF to_regclass('homeos.action_envelopes') IS NOT NULL THEN
        IF NOT EXISTS (
          SELECT 1 FROM information_schema.columns
          WHERE table_schema = 'homeos' AND table_name = 'action_envelopes' AND column_name = 'workflow_id'
        ) THEN
          ALTER TABLE homeos.action_envelopes ADD COLUMN workflow_id VARCHAR(255);
        END IF;

        IF NOT EXISTS (
          SELECT 1 FROM information_schema.columns
          WHERE table_schema = 'homeos' AND table_name = 'action_envelopes' AND column_name = 'signal_name'
        ) THEN
          ALTER TABLE homeos.action_envelopes ADD COLUMN signal_name VARCHAR(100) NOT NULL DEFAULT 'approval';
        END IF;
      END IF;
    END $$;
  `);

  await p.query(`CREATE INDEX IF NOT EXISTS idx_action_envelopes_workflow ON homeos.action_envelopes(workflow_id)`);

  // Create notifications table if not exists
  await p.query(`
    CREATE TABLE IF NOT EXISTS homeos.notifications (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      workspace_id UUID NOT NULL REFERENCES homeos.workspaces(id) ON DELETE CASCADE,
      user_id UUID REFERENCES homeos.users(id) ON DELETE SET NULL,
      type VARCHAR(100) NOT NULL,
      title TEXT NOT NULL,
      body TEXT NOT NULL,
      status VARCHAR(20) NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'delivered', 'read', 'failed')),
      deliver_at TIMESTAMPTZ,
      metadata JSONB DEFAULT '{}',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);

  await p.query(`CREATE INDEX IF NOT EXISTS idx_notifications_workspace ON homeos.notifications(workspace_id)`);
  await p.query(`CREATE INDEX IF NOT EXISTS idx_notifications_user ON homeos.notifications(user_id)`);
  await p.query(`CREATE INDEX IF NOT EXISTS idx_notifications_status ON homeos.notifications(status)`);

  // Create llm_usage table if not exists
  await p.query(`
    CREATE TABLE IF NOT EXISTS homeos.llm_usage (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      workspace_id UUID NOT NULL REFERENCES homeos.workspaces(id) ON DELETE CASCADE,
      user_id UUID REFERENCES homeos.users(id) ON DELETE SET NULL,
      provider VARCHAR(50) NOT NULL,
      model VARCHAR(100) NOT NULL,
      input_tokens INTEGER,
      output_tokens INTEGER,
      total_tokens INTEGER,
      estimated_cost_usd DECIMAL(10, 4),
      metadata JSONB DEFAULT '{}',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);

  await p.query(`CREATE INDEX IF NOT EXISTS idx_llm_usage_workspace ON homeos.llm_usage(workspace_id)`);
  await p.query(`CREATE INDEX IF NOT EXISTS idx_llm_usage_created_at ON homeos.llm_usage(created_at DESC)`);

  // Create workflow_runs table if not exists
  await p.query(`
    CREATE TABLE IF NOT EXISTS homeos.workflow_runs (
      workflow_id VARCHAR(255) PRIMARY KEY,
      run_id VARCHAR(255),
      workspace_id UUID NOT NULL REFERENCES homeos.workspaces(id) ON DELETE CASCADE,
      workflow_type VARCHAR(255) NOT NULL,
      trigger_type VARCHAR(50) NOT NULL DEFAULT 'manual',
      triggered_by UUID REFERENCES homeos.users(id) ON DELETE SET NULL,
      status VARCHAR(20) NOT NULL DEFAULT 'running'
        CHECK (status IN ('queued', 'running', 'retrying', 'succeeded', 'failed', 'canceled')),
      attempts INTEGER NOT NULL DEFAULT 1,
      max_attempts INTEGER,
      input JSONB DEFAULT '{}',
      result JSONB,
      error TEXT,
      started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      completed_at TIMESTAMPTZ,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);

  await p.query(`CREATE INDEX IF NOT EXISTS idx_workflow_runs_workspace ON homeos.workflow_runs(workspace_id)`);
  await p.query(`CREATE INDEX IF NOT EXISTS idx_workflow_runs_status ON homeos.workflow_runs(status)`);
  await p.query(`CREATE INDEX IF NOT EXISTS idx_workflow_runs_started_at ON homeos.workflow_runs(started_at DESC)`);
  await p.query(`CREATE INDEX IF NOT EXISTS idx_workflow_runs_type ON homeos.workflow_runs(workflow_type)`);

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
