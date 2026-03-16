## Base Template (Strapi + Next.js)

- **Backend:** Strapi (Node.js)
- **Frontend:** Next.js
- **Database:** SQLite
- **Proxy:** Caddy (с автоматическим SSL)
- **Orchestration:** Docker Compose

---

### Локальная разработка

Клонирование и инициализация

```bash
git clone <URL_репозитория>
cd <название_проекта>
./manage.sh dev init
```

Настройка окружения

`.env.local`

### Запуск в режиме разработки

```bash
./manage.sh dev up
```
---

### Управление проектом

Для удобства используется скрипт `manage.sh`. Основные команды:

- `./manage.sh dev init` — инициализация проекта для разработки (создаст `.env.local`, проинициализирует back/front при отсутствии).
- `./manage.sh dev init back` — инициализация только бэкенда (Strapi).
- `./manage.sh dev init front` — инициализация только фронтенда (Next.js).
- `./manage.sh dev up` — запуск контейнеров в фоновом режиме.
- `./manage.sh dev down` — остановка контейнеров.
- `./manage.sh dev build` — сборка образов.
- `./manage.sh dev logs` — просмотр логов.
- `./manage.sh dev ps` — статус запущенных контейнеров.
- `./manage.sh dev exec <front|back|proxy>` — интерактивный доступ в контейнеры (аналог `docker compose exec <service> sh`).
- `./manage.sh dev exec <front|back|proxy> <command...>` — выполнить команду внутри контейнера (аналог `docker compose exec <service> <command...>`), например: `./manage.sh dev exec front ls /app`.
- `./manage.sh prod pull` — скачивание свежих образов из Registry (только для PROD).

---

### Инициализация на проде

Скачать и сохранить в рабочую папку проекта файлы из корня репозитария:

- `.env`
- `manage.sh`

Сделать скрипт исполняемым

```bash
chmod +x manage.sh
```
Запустить инициализацию в режиме prod

```bash
./manage.sh prod init
```
Настроить `.env.local`

---

## Деплой

### Настройка GitHub Secrets

Добавить в репозиторий github (Settings -> Secrets and variables -> Actions) следующие секреты:

- `DOMAIN`: Доменное имя вашего сервера.
- `SSH_USER`: Имя пользователя для подключения по SSH.
- `SSH_PRIVATE_KEY`: Приватный SSH ключ (содержимое файла `~/.ssh/id_rsa`).
- `REMOTE_TARGET`: Путь к директории проекта на удаленном сервере (например, `/home/user/project`).
- `CR_PAT`: Personal Access Token (PAT) с правами на чтение пакетов (packages) из GitHub Container Registry.

