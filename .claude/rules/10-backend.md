# Backend (Strapi 5)

## Структура
```
back/src/api/<name>/
  content-types/<name>/schema.json
  controllers/
  routes/
  services/
```

## Правила
- **TypeScript** для всего backend-кода.
- Content-types — только через файлы в `back/src/api/`, не через Strapi admin UI. Это нужно, чтобы изменения попадали в git.
- Следовать конвенциям и структуре папок Strapi 5.
- `back/types/generated/` — автогенерируется Strapi из `schema.json` при каждом старте. В git не коммитится, руками не править.

## Database
- БД — PostgreSQL. Параметры в `compose.yaml` через `DATABASE_*` env.
- Сервис `db` использует healthcheck (`pg_isready`); `back` ждёт `service_healthy` перед стартом.
- Данные хранятся в `data/postgres/` (bind mount, gitignored).

## Preview / Draft Mode
- `PREVIEW_SECRET` — общий секрет между Strapi и Next.js, генерируется в `.env.local`.
- `STRAPI_ADMIN_FRONTEND_URL` — URL фронта для preview-кнопки в админке.
- Реализация preview-флоу — на стороне фронта (route `/api/preview` + Draft Mode).

## Uploads
- Strapi пишет загрузки в `back/public/uploads` (dev) или в `/app/public/uploads` → bind mount `data/uploads` (prod).
- Раздачей занимается Caddy, не Strapi. См. `.docker/{dev,prod}/proxy/Caddyfile`.
