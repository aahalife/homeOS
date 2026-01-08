-- HomeOS Feature Tables Migration
-- Add tables for: preferences, voice profiles, onboarding, phone numbers, calls, integrations

SET search_path TO homeos, public;

-- =====================================================
-- USER PREFERENCES
-- =====================================================
CREATE TABLE IF NOT EXISTS user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category VARCHAR(100) NOT NULL,
    preferences JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(workspace_id, user_id, category)
);

CREATE INDEX IF NOT EXISTS idx_user_preferences_workspace_user ON user_preferences(workspace_id, user_id);

-- Default preference categories:
-- 'notifications': { calls: true, tasks: true, approvals: true, quietHoursStart: null, quietHoursEnd: null }
-- 'privacy': { dataRetentionDays: 90, piiMaskingLevel: 'high', analyticsOptOut: false }
-- 'ai': { responseVerbosity: 'normal', personality: 'friendly', voiceProfileId: null }
-- 'approvals': { autoApproveBelow: 50, requireApprovalFor: ['calls', 'payments'], timeBasedApproval: false }

-- =====================================================
-- FAMILY MEMBERS
-- =====================================================
CREATE TABLE IF NOT EXISTS family_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    relationship VARCHAR(100),
    age INTEGER,
    preferences JSONB DEFAULT '{}',
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_family_members_workspace ON family_members(workspace_id);

-- =====================================================
-- VOICE PROFILES (Echo-TTS cloned voices)
-- =====================================================
CREATE TABLE IF NOT EXISTS voice_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    celebrity_name VARCHAR(255),
    youtube_url TEXT,
    audio_sample_url TEXT,
    model_path TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'processing' CHECK (status IN ('processing', 'ready', 'failed')),
    sample_duration_seconds INTEGER,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_voice_profiles_workspace ON voice_profiles(workspace_id);
CREATE INDEX IF NOT EXISTS idx_voice_profiles_status ON voice_profiles(status);

-- =====================================================
-- ONBOARDING SESSIONS
-- =====================================================
CREATE TABLE IF NOT EXISTS onboarding_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    current_step INTEGER NOT NULL DEFAULT 0,
    total_steps INTEGER NOT NULL DEFAULT 7,
    voice_profile_id UUID REFERENCES voice_profiles(id) ON DELETE SET NULL,
    responses JSONB DEFAULT '{}',
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(workspace_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_onboarding_sessions_workspace_user ON onboarding_sessions(workspace_id, user_id);

-- =====================================================
-- PHONE NUMBERS (Twilio)
-- =====================================================
CREATE TABLE IF NOT EXISTS phone_numbers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    phone_number VARCHAR(20) NOT NULL,
    twilio_sid VARCHAR(50) NOT NULL,
    friendly_name VARCHAR(255),
    capabilities JSONB DEFAULT '{"voice": true, "sms": true}',
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'released')),
    monthly_cost DECIMAL(10, 2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(phone_number)
);

CREATE INDEX IF NOT EXISTS idx_phone_numbers_workspace ON phone_numbers(workspace_id);

-- =====================================================
-- CALL HISTORY
-- =====================================================
CREATE TABLE IF NOT EXISTS call_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    phone_number_id UUID REFERENCES phone_numbers(id) ON DELETE SET NULL,
    twilio_call_sid VARCHAR(50) NOT NULL UNIQUE,
    direction VARCHAR(20) NOT NULL CHECK (direction IN ('outbound', 'inbound')),
    to_number VARCHAR(20) NOT NULL,
    from_number VARCHAR(20) NOT NULL,
    status VARCHAR(50) NOT NULL,
    duration_seconds INTEGER,
    transcript TEXT,
    live_transcript JSONB DEFAULT '[]',
    recording_url TEXT,
    outcome VARCHAR(50),
    purpose VARCHAR(100),
    business_name VARCHAR(255),
    metadata JSONB DEFAULT '{}',
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_call_history_workspace ON call_history(workspace_id);
CREATE INDEX IF NOT EXISTS idx_call_history_created_at ON call_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_call_history_status ON call_history(status);

-- =====================================================
-- COMPOSIO CONNECTIONS (OAuth integrations)
-- =====================================================
CREATE TABLE IF NOT EXISTS composio_connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
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
);

CREATE INDEX IF NOT EXISTS idx_composio_connections_workspace ON composio_connections(workspace_id);
CREATE INDEX IF NOT EXISTS idx_composio_connections_user ON composio_connections(user_id);
CREATE INDEX IF NOT EXISTS idx_composio_connections_app ON composio_connections(app_id);

-- OAuth state tokens for security
CREATE TABLE IF NOT EXISTS oauth_states (
    state_token VARCHAR(64) PRIMARY KEY,
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    app_id VARCHAR(100) NOT NULL,
    redirect_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_oauth_states_expires ON oauth_states(expires_at);

-- =====================================================
-- APPLY TRIGGERS
-- =====================================================
CREATE TRIGGER update_user_preferences_updated_at
    BEFORE UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_family_members_updated_at
    BEFORE UPDATE ON family_members
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_voice_profiles_updated_at
    BEFORE UPDATE ON voice_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_onboarding_sessions_updated_at
    BEFORE UPDATE ON onboarding_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_phone_numbers_updated_at
    BEFORE UPDATE ON phone_numbers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_composio_connections_updated_at
    BEFORE UPDATE ON composio_connections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- CLEANUP OLD OAUTH STATES (run periodically)
-- =====================================================
-- DELETE FROM oauth_states WHERE expires_at < NOW();
