#!/bin/bash
# manage.sh

set -e

# Функция для вывода помощи
usage() {
    local exit_code=${1:-0}
    echo "Usage: $0 <dev|prod> [command]"
    echo "       $0 <dev|prod> init [back|front]"
    echo "       $0 <dev|prod> exec <front|back|proxy>"
    echo "       $0 <dev|prod> npm-install <front|back> [npm install args...]"
    echo "ps                  - List running containers"
    echo ""
    echo "Mode (dev or prod) must be specified first for all others commands."
    echo ""
    echo "Commands:"
    echo "  init [back|front] - Initialize project (folders, .env.local secrets) for the given mode"
    echo "  up                - Start containers (detached)"
    echo "  build             - Build images"
    echo "  down              - Stop containers"
    echo "  restart           - Restart containers"
    echo "  pull              - Pull latest images (PROD only)"
    echo "  logs              - Show logs (tail 100)"
    echo "  exec              - Exec into container or run a one-off command (front|back|proxy)"
    echo "  npm-install       - Run 'npm install' inside a temporary Node container (in back|front dir)"
    exit "$exit_code"
}

# 2. Определение режима и команды
if [[ "$1" == "dev" || "$1" == "prod" ]]; then
    MODE=$1
    shift
    COMMAND=$1
elif [[ "$1" =~ ^(help|--help|-h)$ ]] || [ -z "$1" ]; then
    usage 0
elif [[ "$1" =~ ^(ps)$ ]] || [ -z "$1" ]; then
    docker ps
    exit 0
else
    echo "Error: First argument must be 'dev' or 'prod' (or 'help')."
    echo "Usage: $0 <dev|prod> <command>"
    exit 1
fi

# Функция для получения переменной из файлов .env/.env.local (в стиле Docker Compose: последний найденный побеждает)
get_env_val() {
    local key=$1
    local val=""
    # Проверяем файлы в порядке переопределения
    for f in .env .env.local; do
        if [ -f "$f" ]; then
            # Ищем ключ, игнорируя комментарии, берем последнее вхождение
            local found
            found=$(grep -E "^${key}[:=]" "$f" | tail -n 1)
            if [ -n "$found" ]; then
                # Удаляем ключ, разделитель, пробелы и символ \r
                val=$(echo "$found" | sed -E "s/^${key}[:=]//" | tr -d '\r' | xargs)
            fi
        fi
    done
    echo "$val"
}

PROJECT_NAME=$(get_env_val PROJECT_NAME)
DOMAIN=$(get_env_val DOMAIN)
HTTP_PORT=$(get_env_val HTTP_PORT)
HTTPS_PORT=$(get_env_val HTTPS_PORT)
BACK_HTTP_PORT=$(get_env_val BACK_HTTP_PORT)
BACK_HTTP_PORT_EXT=$(get_env_val BACK_HTTP_PORT_EXT)

# Функция для вывода заголовка (аналогично Makefile)
print_header() {
    # Не выводим заголовок при помощи
    if [[ "$COMMAND" =~ ^(help|--help|-h)$ ]]; then return; fi
    
    echo "============================="
    echo "  PROJECT:       $PROJECT_NAME"
    echo "  MODE:          $MODE"
    echo "  DOMAIN:        http://$DOMAIN:$HTTP_PORT"
    echo "============================="
}

# Вывод заголовка при запуске (кроме вызова помощи)
print_header

# 3. Проверка наличия .env.local (обязательно для всех команд, кроме help и init)
if [[ ! "$COMMAND" =~ ^(help|--help|-h|init)$ ]]; then
    if [ ! -f .env.local ]; then
        echo "Error: .env.local not found. Please run './manage.sh init <dev|prod>' first."
        exit 1
    fi
fi

# 4. Формирование списка файлов docker compose
COMPOSE_FILES=""

if [ "$MODE" == "dev" ]; then
    # В режиме разработки подключаем базовый и dev файлы
    COMPOSE_FILES="-f compose.yaml -f compose.dev.yaml"
elif [ "$MODE" == "prod" ]; then
    # В режиме продакшена:
    # 1. Базовый и prod файл (локально или сервер)
    COMPOSE_FILES="-f compose.yaml -f compose.prod.yaml"
    
    # 2. Если папки .docker нет — это сервер (deploy)
    if [ ! -d ".docker" ]; then
        COMPOSE_FILES="$COMPOSE_FILES -f compose.deploy.yaml"
    fi
fi

# Функция для выполнения docker compose команд
run_compose() {
    # Собираем команду из бинарника и файлов, затем добавляем аргументы
    # shellcheck disable=SC2086
    docker compose --env-file .env --env-file .env.local $COMPOSE_FILES "$@"
}

# Функция генерации секретов
generate_secrets() {
    # Для Strapi
    STRAPI_APP_KEYS=$(openssl rand -hex 16),$(openssl rand -hex 16),$(openssl rand -hex 16),$(openssl rand -hex 16)
    STRAPI_API_TOKEN_SALT=$(openssl rand -hex 16)
    STRAPI_ADMIN_JWT_SECRET=$(openssl rand -hex 16)
    STRAPI_JWT_SECRET=$(openssl rand -hex 24)
    STRAPI_TRANSFER_TOKEN_SALT=$(openssl rand -hex 16)
    STRAPI_ENCRYPTION_KEY=$(openssl rand -hex 16)
    # Preview (shared between Strapi and Next.js)
    PREVIEW_SECRET=$(openssl rand -hex 32)
    # Database
    DATABASE_PASSWORD=$(openssl rand -hex 16)
}

init_dev() {
    local target=${1:-all}
    echo "=== Initialization (DEV mode, target: $target) ==="
    
    # 0. Check if already initialized (only if target is all)
    if [ "$target" == "all" ]; then
        if [ -s ".env.local" ] && [ -d "back" ] && [ -d "front" ]; then
            echo "[!] Project is already initialized in DEV mode."
            echo "    - .env.local exists"
            echo "    - Directory 'back' exists"
            echo "    - Directory 'front' exists"
            echo "    If you want to re-init, please remove them manually (BE CAREFUL!)."
            exit 0
        fi
    fi

    if [ ! -f ".env" ]; then
        echo "[!] Error: .env file is missing. Please ensure it exists."
        exit 1
    fi

    # Системные файлы
    if [ ! -f .env.local ]; then
        touch .env.local
        echo "[+] Creating .env.local for DEV..."
        generate_secrets
        cat <<EOF >> .env.local

# --- REQUIRED: EDIT MANUALLY ---
PROJECT_NAME=

# Front network settings
HTTP_PORT=$HTTP_PORT
HTTPS_PORT=$HTTPS_PORT

# Back network setting
BACK_HTTP_PORT=$BACK_HTTP_PORT
BACK_HTTP_PORT_EXT=$BACK_HTTP_PORT_EXT

# --- AUTO-GENERATED SECRETS ---
STRAPI_APP_KEYS=$STRAPI_APP_KEYS
STRAPI_API_TOKEN_SALT=$STRAPI_API_TOKEN_SALT
STRAPI_ADMIN_JWT_SECRET=$STRAPI_ADMIN_JWT_SECRET
STRAPI_JWT_SECRET=$STRAPI_JWT_SECRET
STRAPI_TRANSFER_TOKEN_SALT=$STRAPI_TRANSFER_TOKEN_SALT
STRAPI_ENCRYPTION_KEY=$STRAPI_ENCRYPTION_KEY

# Preview (shared between Strapi and Next.js)
PREVIEW_SECRET=$PREVIEW_SECRET

# Database
DATABASE_PASSWORD=$DATABASE_PASSWORD
EOF
    fi

    # Создать директории для bind mounts (от текущего пользователя)
    echo "[+] Creating data directories..."
    mkdir -p data/postgres
    echo "[OK] data/ directories created"

    # Инициализация бэкенда
    if [ "$target" == "all" ] || [ "$target" == "back" ]; then
        if [ -d "back" ]; then
            echo "[!] Directory 'back' already exists. Skipping Strapi init."
        else
            echo "START init back (Strapi)"
            echo "==============="
            docker run --rm -t -v ".:/app" -w /app --user "$(id -u):$(id -g)" node:24-slim \
                sh -lc '
                    set -eu;
                    npx -y create-strapi-app@latest back --skip-cloud --no-run --typescript --non-interactive;
                    cd back;
                    npm uninstall better-sqlite3;
                    npm install pg;
                '
            echo "==============="
            echo "FINISH init back"
        fi
        mkdir -p back/public/uploads
    fi

    # Инициализация фронтенда
    if [ "$target" == "all" ] || [ "$target" == "front" ]; then
        if [ -d "front" ]; then
            echo "[!] Directory 'front' already exists. Skipping Next.js init."
        else
            echo "START init front (Next.js)"
            echo "===================================="
            docker run --rm -t -v ".:/app" -w /app --user "$(id -u):$(id -g)" node:24-slim \
                sh -lc '
                    set -eu;
                    npx -y create-next-app@latest front --yes;
                    cd front;
                    sed -i "s/const nextConfig: NextConfig = {/const nextConfig: NextConfig = {\\n  output: '\''standalone'\'',/" next.config.ts;
                '
            echo "===================================="
            echo "FINISH init front"
        fi
    fi
}

init_prod() {
    echo "=== Initialization (PROD mode) ==="
    
    # 0. Check if already initialized
    if [ -f ".env.local" ]; then
        echo "[!] Project is already initialized (found .env.local)."
        echo "    If you want to re-init with new secrets, please remove .env.local manually."
        exit 0
    fi

    if [ ! -f ".env" ]; then
        echo "[!] Error: .env file is missing. Please ensure it exists."
        exit 1
    fi

    # 2. Сформировать .env.local с секретами и переменными для ручной правки
    if [ ! -f ".env.local" ]; then
        echo "[+] Generating .env.local for PROD..."
        generate_secrets
        
        cat <<EOF > ".env.local"
# --- REQUIRED: EDIT MANUALLY ---
PROJECT_NAME=
GITHUB_USER_NAME=
DOMAIN=

# Front network settings
HTTP_PORT=$HTTP_PORT
HTTPS_PORT=$HTTPS_PORT

# Back network setting
BACK_HTTP_PORT=$BACK_HTTP_PORT
BACK_HTTP_PORT_EXT=$BACK_HTTP_PORT_EXT

# --- AUTO-GENERATED SECRETS ---
STRAPI_APP_KEYS=$STRAPI_APP_KEYS
STRAPI_API_TOKEN_SALT=$STRAPI_API_TOKEN_SALT
STRAPI_ADMIN_JWT_SECRET=$STRAPI_ADMIN_JWT_SECRET
STRAPI_JWT_SECRET=$STRAPI_JWT_SECRET
STRAPI_TRANSFER_TOKEN_SALT=$STRAPI_TRANSFER_TOKEN_SALT
STRAPI_ENCRYPTION_KEY=$STRAPI_ENCRYPTION_KEY

# Preview (shared between Strapi and Next.js)
PREVIEW_SECRET=$PREVIEW_SECRET

# Database
DATABASE_PASSWORD=$DATABASE_PASSWORD
EOF
        echo "[OK] .env.local created. PLEASE EDIT REQUIRED FIELDS!"
    else
        echo "[!] .env.local already exists."
    fi

    # Создать директории для bind mounts
    echo "[+] Creating data directories..."
    mkdir -p data/postgres data/uploads
    # uploads — от node (UID 1000); postgres управляет правами сам
    chown -R 1000:1000 data/uploads
    echo "[OK] data/ directories created"
}

case "$COMMAND" in
    help|--help|-h)
        usage 0 ;;
    init)
        TARGET_ARG=${2:-all}

        if [ "$MODE" == "dev" ]; then
            init_dev "$TARGET_ARG"
        elif [ "$MODE" == "prod" ]; then
            if [ "$TARGET_ARG" != "all" ]; then
                echo "Error: 'prod init' does not accept a target argument."
                echo "Usage: $0 prod init"
                exit 1
            fi
            init_prod
        fi
        ;;
    up)
        run_compose up -d --remove-orphans ;;
    build)
        run_compose build ;;
    down)
        run_compose down ;;
    restart)
        run_compose down
        run_compose up -d --remove-orphans ;;
    pull)
        if [ "$MODE" == "dev" ]; then
            echo "[!] 'pull' command is disabled in DEV mode."
            echo "    Use 'build' to rebuild images locally or 'up' to start project."
            exit 0
        fi
        run_compose pull ;;
    logs)
        run_compose logs -f --tail=100 ;;
    exec)
        SERVICE=${2:-}
        if [[ -z "$SERVICE" ]]; then
            echo "Error: Service name is required."
            echo "Usage: $0 $MODE exec <front|back|proxy> [command...]"
            exit 1
        fi

        if [[ ! "$SERVICE" =~ ^(front|back|proxy)$ ]]; then
            echo "Error: Unsupported service '$SERVICE'."
            echo "Allowed services: front, back, proxy."
            exit 1
        fi
        
        shift 2
        if [ "$#" -eq 0 ]; then
            # No extra command provided — open interactive shell
            run_compose exec "$SERVICE" sh
        else
            # Pass the rest of the arguments as a command to run
            run_compose exec "$SERVICE" "$@"
        fi
        ;;
    npm-install)
        # Run `npm install` in a temporary Node container, mirroring current user,
        # inside either ./front or ./back
        TARGET_DIR=${2:-}

        if [[ -z "$TARGET_DIR" ]]; then
            echo "Error: Target directory is required."
            echo "Usage: $0 $MODE npm-install <front|back> [npm install args...]"
            exit 1
        fi

        if [[ ! "$TARGET_DIR" =~ ^(front|back)$ ]]; then
            echo "Error: Unsupported target '$TARGET_DIR'."
            echo "Allowed targets: front, back."
            exit 1
        fi

        if [ ! -d "$TARGET_DIR" ]; then
            echo "Error: Directory '$TARGET_DIR' does not exist."
            exit 1
        fi

        shift 2
        docker run --rm -it \
            -v ".:/app" \
            -w "/app/$TARGET_DIR" \
            --user "$(id -u):$(id -g)" \
            node:24-slim \
            sh -lc "npm install $*"
        ;;
    *)
        usage 1 ;;
esac
