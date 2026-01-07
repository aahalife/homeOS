# Build stage - use Debian slim for Temporal SDK compatibility (requires glibc)
FROM node:22-slim AS builder

# Install pnpm
RUN corepack enable && corepack prepare pnpm@9.15.0 --activate

WORKDIR /app

# Copy workspace files
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json tsconfig.base.json ./
COPY packages/shared/package.json packages/shared/
COPY services/workflows/package.json services/workflows/

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy source files
COPY packages/shared/ packages/shared/
COPY services/workflows/ services/workflows/

# Build shared package first
RUN pnpm --filter @homeos/shared build

# Build workflows
RUN pnpm --filter @homeos/workflows build

# Production stage - must use glibc-based image for Temporal SDK
FROM node:22-slim AS runner

# Install CA certificates for TLS connections (required for Temporal Cloud)
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare pnpm@9.15.0 --activate

WORKDIR /app

# Copy built artifacts
COPY --from=builder /app/pnpm-lock.yaml /app/pnpm-workspace.yaml /app/package.json ./
COPY --from=builder /app/packages/shared/package.json packages/shared/
COPY --from=builder /app/packages/shared/dist packages/shared/dist/
COPY --from=builder /app/services/workflows/package.json services/workflows/
COPY --from=builder /app/services/workflows/dist services/workflows/dist/

# Install production dependencies only
RUN pnpm install --frozen-lockfile --prod

# Set environment
ENV NODE_ENV=production

WORKDIR /app/services/workflows

CMD ["node", "dist/worker.js"]
