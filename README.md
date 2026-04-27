# Base Template (Strapi 5 + Next.js 16)

Шаблон для запуска проектов на стеке Strapi + Next.js в Docker.

## Стек

- **Frontend:** Next.js 16 (App Router), React 19, TypeScript 5, Tailwind 4
- **Backend:** Strapi 5, Node 24
- **БД:** PostgreSQL 17
- **Proxy:** Caddy (с автоматическим SSL на проде)
- **Orchestration:** Docker Compose, GitHub Actions + GHCR

## Быстрый старт

```bash
git clone <URL>
cd <project>
./manage.sh dev init    # создаст .env.local, скачает Strapi и Next.js
./manage.sh dev up      # поднимет контейнеры
```

После запуска:

- Frontend: http://localhost
- Strapi admin: http://localhost:1337/admin

## Управление

```bash
./manage.sh dev up                          # запуск
./manage.sh dev down                        # остановка
./manage.sh dev restart                     # перезапуск (down + up)
./manage.sh dev build                       # сборка образов
./manage.sh dev logs                        # логи (tail 100, follow)
./manage.sh ps                              # список контейнеров
./manage.sh dev exec <front|back|proxy>     # интерактивный shell в контейнере
./manage.sh dev exec <svc> <cmd...>         # одноразовая команда в контейнере
./manage.sh dev npm-install <front|back>    # npm install в одноразовом Node-контейнере
```

## Структура

```
back/           — Strapi backend
front/          — Next.js frontend
data/           — bind mounts: postgres, uploads (gitignored)
docs/           — документация → docs/README.md
.docker/        — Dockerfile'ы и Caddyfile'ы (dev/prod)
compose*.yaml   — Docker Compose
manage.sh       — CLI управления
.claude/rules/  — правила для AI-ассистента
```

## Архитектурные решения (вкратце)

- Frontend ходит к Strapi только server-side; `NEXT_PUBLIC_API_URL` не используется.
- Медиа (`/uploads/*`) раздаёт Caddy напрямую с диска, минуя Node.
- Bind mounts для всех персистентных данных — бэкап через `tar`.
- PostgreSQL в dev и prod (одна БД везде).
- Preview/Draft Mode настроен из коробки (`PREVIEW_SECRET`).

Подробнее — в [docs/architecture.md](docs/architecture.md).

## Инициализация на проде

На сервере достаточно `manage.sh` и `.env`. Деплой настроен через GitHub Actions (`.github/workflows/deploy.yml`): при push в `main` собираются образы в GHCR, на сервер копируются compose-файлы, поднимается стек.

```bash
# На сервере, в рабочей папке проекта:
chmod +x manage.sh
./manage.sh prod init     # сгенерирует .env.local, создаст data/postgres и data/uploads
# Заполнить REQUIRED-поля в .env.local (PROJECT_NAME, GITHUB_USER_NAME, DOMAIN)
```

Дальше прод обновляется автоматически по push в `main`.

### Настройка GitHub Secrets

В репозитории GitHub (Settings → Secrets and variables → Actions):

- `DOMAIN` — доменное имя сервера.
- `SSH_USER` — пользователь для SSH.
- `SSH_PRIVATE_KEY` — приватный ключ (содержимое `~/.ssh/id_rsa`).
- `REMOTE_TARGET` — путь к рабочей папке проекта на сервере.
- `CR_PAT` — Personal Access Token с правом `read:packages` (для pull из GHCR).
