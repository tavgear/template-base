# Проект — обзор

Шаблон Strapi 5 + Next.js 16 в Docker Compose, с Caddy в роли реверс-прокси и раздачи статики, PostgreSQL в качестве БД.

## Стек
- **Frontend:** Next.js 16 (App Router), React 19, TypeScript 5, Tailwind 4 → `front/`
- **Backend:** Strapi 5, Node 24 → `back/`
- **БД:** PostgreSQL 17
- **Инфра:** Docker Compose, Caddy, `./manage.sh`
- **CI/CD:** GitHub Actions + GHCR

## Структура репо
- `back/` — Strapi (content-types, controllers, routes, services в `back/src/api/`)
- `front/` — Next.js (App Router: `front/app/`, компоненты: `front/components/`, утилиты: `front/lib/`)
- `data/` — bind mounts: `data/postgres`, `data/uploads` (gitignored)
- `.docker/dev/`, `.docker/prod/` — Dockerfile'ы и Caddyfile'ы для двух режимов
- `compose.yaml`, `compose.dev.yaml`, `compose.prod.yaml`, `compose.deploy.yaml`
- `manage.sh` — CLI: init, up, down, build, logs, exec, npm-install
- `.env` — dev-дефолты; `.env.local` — overrides и секреты (gitignored, генерируется `manage.sh init`)
- `docs/` — документация проекта

## Архитектурные решения
- **Frontend ходит к Strapi только server-side** через `API_URL=http://back:1337` (внутренняя docker-сеть). `NEXT_PUBLIC_API_URL` сознательно отсутствует — порт Strapi не нужен на клиенте, нет CORS, лучше SEO.
- **Медиа отдаёт Caddy** напрямую с диска (`/uploads/*` с агрессивным immutable-кешем). Strapi не участвует в раздаче статики — экономит CPU и память Node.
- **Bind mounts** для всех персистентных данных (`data/postgres`, `data/uploads`). Бэкап = `tar` папки. На проде следить за UID (`init_prod` chown'ит `data/uploads` к 1000:1000).
- **PostgreSQL** в dev и в prod. Не SQLite — чтобы не было сюрпризов при переходе на прод.
