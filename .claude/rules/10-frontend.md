# Frontend (Next.js)

## Структура
```
front/app/          — маршруты App Router (layouts, pages)
front/components/   — переиспользуемые компоненты
front/lib/          — утилиты и API-обёртки
```

## Правила
- **App Router только.** Не использовать `pages/`, `getStaticProps`, `getServerSideProps`.
- Все запросы к Strapi — через server-side хелпер в `front/lib/` (например, `lib/strapi.ts`).
- **URL бэкенда:** `process.env.API_URL` (`http://back:1337` — внутренняя docker-сеть). Никаких клиентских запросов к Strapi — `NEXT_PUBLIC_API_URL` не используется.
- **Медиа** — относительные URL `/uploads/...`. Раздачу делает Caddy напрямую с диска. Не использовать абсолютный URL Strapi.
- **Кеширование:** для серверных fetch'ей — `next: { revalidate: <seconds> }` (ISR). Для preview-режима — `cache: 'no-store'`.
- **Build:** `output: 'standalone'` в `next.config.ts` (нужно для prod-Dockerfile).
- **Tailwind v4** — использовать его синтаксис (`@theme`, CSS-переменные), не v3.

## Preview / Draft Mode
- Route `/api/preview` (под `front/app/api/preview/route.ts`) принимает запрос с `secret` и `slug` от Strapi, валидирует через `PREVIEW_SECRET`, включает Draft Mode и редиректит на нужную страницу.
- На страницах в Draft Mode — fetch с `cache: 'no-store'` + публикация полей `pending_review`/`draft`.

## Пример server-side fetch
```ts
const apiUrl = process.env.API_URL ?? 'http://back:1337';
const res = await fetch(`${apiUrl}/api/...`, { next: { revalidate: 60 } });
```

## Что НЕ делать
- Не использовать `pages/`, `getStaticProps`, `getServerSideProps`. Только App Router.
- Не хардкодить URL бэкенда на клиенте.
- Не обращаться к Strapi с клиента — все запросы только server-side (Server Components, Route Handlers, Server Actions).
