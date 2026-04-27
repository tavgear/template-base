# Архитектура

<!--
Здесь фиксируются принятые архитектурные решения проекта.
То, что описано в этом файле, считается принятым — не предлагать
альтернативы без явного запроса пересмотра.
-->

## Стек
- **Frontend:** Next.js 16 (App Router), React 19, TypeScript 5, Tailwind 4
- **Backend:** Strapi 5, Node 24
- **БД:** PostgreSQL 17
- **Инфра:** Docker Compose, Caddy

## Ключевые решения

### Frontend ходит к Strapi только server-side
`API_URL=http://back:1337` через внутреннюю docker-сеть. `NEXT_PUBLIC_API_URL` сознательно не используется. Преимущества:
- порт Strapi не нужен на клиенте,
- нет CORS,
- лучше SEO (server-rendered),
- backend URL не утекает в клиентский бандл.

### Caddy раздаёт `/uploads/*` напрямую
Strapi пишет загрузки на диск, Caddy раздаёт их с `Cache-Control: public, max-age=31536000, immutable`. Никаких round-trip через Node для статики. Фронт ссылается на медиа относительными URL: `/uploads/...`.

### Bind mounts вместо named volumes
Все персистентные данные (`data/postgres`, `data/uploads`) — bind mounts. Бэкап = `tar` папки. На проде `manage.sh prod init` chown'ит `data/uploads` к 1000:1000 (UID `node` user в образе).

### PostgreSQL в dev и prod
SQLite не используется — чтобы не было сюрпризов с типами/миграциями при переходе в прод. Сервис `db` использует healthcheck, `back` ждёт `service_healthy`.

## Модели данных
<!-- Описать content-types Strapi по мере появления -->

## Маршруты Frontend
<!-- Описать структуру App Router по мере появления -->
