FROM node:22-alpine AS builder
WORKDIR /app
RUN corepack enable

# Copy workspace files for pnpm
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json tsconfig.base.json ./
COPY packages/api-kit/package.json packages/api-kit/
COPY barkey/api/package.json barkey/api/

# Install deps
RUN pnpm install --frozen-lockfile

# Copy source and build
COPY packages/api-kit/ packages/api-kit/
COPY barkey/api/ barkey/api/
RUN cd packages/api-kit && pnpm build
RUN cd barkey/api && pnpm build

# Prune dev dependencies
RUN pnpm prune --prod

FROM node:22-alpine AS runner
WORKDIR /app

# Keep full workspace structure so pnpm symlinks resolve
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/packages/api-kit/node_modules ./packages/api-kit/node_modules
COPY --from=builder /app/packages/api-kit/dist ./packages/api-kit/dist
COPY --from=builder /app/packages/api-kit/package.json ./packages/api-kit/
COPY --from=builder /app/barkey/api/node_modules ./barkey/api/node_modules
COPY --from=builder /app/barkey/api/dist ./barkey/api/dist
COPY --from=builder /app/barkey/api/package.json ./barkey/api/

# Data directory for SQLite
RUN mkdir -p /app/data
VOLUME ["/app/data"]

EXPOSE 3000
ENV NODE_ENV=production
WORKDIR /app/barkey/api
CMD ["node", "dist/index.js"]
