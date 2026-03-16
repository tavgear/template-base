FROM node:24-slim AS dependencies

ENV NODE_ENV=production
ENV STRAPI_TELEMETRY_DISABLED=true

WORKDIR /app

COPY ./back/package.json ./back/package-lock.json ./

RUN --mount=type=cache,target=/root/.npm npm ci --include=dev --no-audit --no-fund

# Stage 2: Build
# =====================================================================================================================
FROM node:24-slim AS builder

ENV NODE_ENV=production
ENV STRAPI_TELEMETRY_DISABLED=true

WORKDIR /app

COPY --from=dependencies /app/node_modules ./node_modules

COPY ./back ./

RUN --mount=type=cache,target=/app/.next/cache npm run build

FROM node:24-slim AS runner

ENV NODE_ENV=production
ENV STRAPI_TELEMETRY_DISABLED=true

RUN apt-get update \
    && apt-get install -y curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app ./

CMD ["npm", "run", "start"]