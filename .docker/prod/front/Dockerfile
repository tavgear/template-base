# Stage 1: Install dependencies
# =====================================================================================================================
FROM node:24-slim AS dependencies

ENV NODE_ENV=production

WORKDIR /app

COPY ./front/package.json ./front/package-lock.json ./

RUN --mount=type=cache,target=/root/.npm npm ci --include=dev --no-audit --no-fund

# Stage 2: Build
# =====================================================================================================================
FROM node:24-slim AS builder

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

ARG API_URL
ENV API_URL=${API_URL}

ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}


WORKDIR /app

COPY --from=dependencies /app/node_modules ./node_modules

COPY ./front ./

RUN --mount=type=cache,target=/app/.next/cache npm run build

# Stage 3: Run
# =====================================================================================================================
FROM node:24-slim AS runner

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN apt-get update \
    && apt-get install -y curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder --chown=node:node /app/public ./public
COPY --from=builder --chown=node:node /app/.next/standalone ./
COPY --from=builder --chown=node:node /app/.next/static ./.next/static

USER node

CMD ["node", "server.js"]
