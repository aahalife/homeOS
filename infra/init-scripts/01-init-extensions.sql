-- Enable required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create schemas
CREATE SCHEMA IF NOT EXISTS homeos;
CREATE SCHEMA IF NOT EXISTS temporal;

-- Grant permissions
GRANT ALL PRIVILEGES ON SCHEMA homeos TO homeos;
GRANT ALL PRIVILEGES ON SCHEMA temporal TO homeos;
