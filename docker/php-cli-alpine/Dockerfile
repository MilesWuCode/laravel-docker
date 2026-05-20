FROM composer:2.9 AS vendor

FROM php:8.4-cli-alpine AS base

ARG APP_ENV
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG TZ=Asia/Taipei
ARG ENV_FILE

ENV TERM=xterm-color \
    TZ=${TZ} \
    LANG=C.UTF-8 \
    USER=laravel \
    ROOT=/var/www/html \
    APP_ENV=${APP_ENV} \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_FUND=0 \
    COMPOSER_MAX_PARALLEL_HTTP=24

WORKDIR ${ROOT}

# 使用 sh 作為默認 shell 以便執行較新的指令
SHELL ["/bin/sh", "-eou", "pipefail", "-c"]

# 設定時區
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone

# 安裝 PHP 擴展安裝器
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

#  安裝必要的套件
RUN apk update; \
    apk upgrade; \
    apk add --no-cache \
    curl \
    wget \
    vim \
    tzdata \
    unzip \
    # ncdu:這是一個磁碟使用分析工具。
    # ncdu \
    # procps:包含 ps, top 等進程管理工具。
    procps \
    ca-certificates \
    supervisor \
    bash \
    libsodium-dev \
    # bun:使用bun才打開
    # && curl -fsSL https://bun.sh/install | BUN_INSTALL=/usr bash \
    # Install PHP extensions
    && install-php-extensions \
    apcu \
    bz2 \
    pcntl \
    mbstring \
    bcmath \
    sockets \
    # pdo_pgsql:使用Postgres才打開
    # pdo_pgsql \
    opcache \
    exif \
    pdo_mysql \
    zip \
    uv \
    intl \
    gd \
    redis \
    # rdkafka \
    # ffi \
    # ldap \
    && docker-php-source delete \
    && rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

# 根據容器架構（armhf, aarch64, x86_64, x86）選擇對應的 supercronic 可執行檔名稱
# 如果架構不被支援則停止建置並輸出錯誤
# 然後從 GitHub 下載對應版本的 supercronic，放到 /usr/bin 並給予執行權限
# 接著建立 /etc/supercronic 資料夾，並新增一個排程檔 laravel
# 內容是每分鐘執行一次 Laravel 的排程任務 (php artisan schedule:run --no-interaction)
# supercronic 是輕量級的 cron 替代品，適合在容器中使用，因為它能處理 log 並維持前景執行（避免容器退出）
RUN arch="$(apk --print-arch)" \
    && case "$arch" in \
    armhf) _cronic_fname='supercronic-linux-arm' ;; \
    aarch64) _cronic_fname='supercronic-linux-arm64' ;; \
    x86_64) _cronic_fname='supercronic-linux-amd64' ;; \
    x86) _cronic_fname='supercronic-linux-386' ;; \
    *) echo >&2 "error: unsupported architecture: $arch"; exit 1 ;; \
    esac \
    && wget -q "https://github.com/aptible/supercronic/releases/download/v0.2.41/${_cronic_fname}" \
    -O /usr/bin/supercronic \
    && chmod +x /usr/bin/supercronic \
    && mkdir -p /etc/supercronic \
    && echo "*/1 * * * * php ${ROOT}/artisan schedule:run --no-interaction" > /etc/supercronic/laravel

# 建立指定使用者和群組
RUN addgroup -g ${GROUP_ID} ${USER} \
    && adduser -D -G ${USER} -u ${USER_ID} -s /bin/sh ${USER}

# 複製 php.ini
RUN cp ${PHP_INI_DIR}/php.ini-production ${PHP_INI_DIR}/php.ini

# 複製 composer
COPY --link --from=vendor /usr/bin/composer /usr/bin/composer

# 複製 supervisord 配置檔案
COPY --link docker/php-cli-alpine/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 客制化 php.ini 配置
COPY --link docker/php-cli-alpine/php.ini ${PHP_INI_DIR}/conf.d/99-php.ini

# 複製 啟動容器時執行的命令
COPY --link docker/php-cli-alpine/start-container /usr/local/bin/start-container

# 複製 composer.json, composer.lock
COPY --link composer.* ./

# 安裝 Composer 依賴套件（不含 autoloader，延後產生以便優化）
RUN composer install \
    --no-dev \
    --no-interaction \
    --no-autoloader \
    --no-ansi \
    --no-scripts \
    --no-progress \
    --audit

# 複製全部檔案
COPY --link . .

# 複製環境變數檔案
COPY --link ./envs/${ENV_FILE} .env

# 建立目錄權限
RUN mkdir -p \
    storage/framework/sessions \
    storage/framework/views \
    storage/framework/cache \
    storage/framework/testing \
    storage/logs \
    bootstrap/cache \
    && chmod +x /usr/local/bin/start-container

# 產生最佳化的 autoloader（使用 classmap 和 APCu 快取）
RUN composer dump-autoload \
    --optimize \
    --apcu \
    --no-dev

# 設定目錄擁有者，並移除所有 SUID/SGID bit 以防止提權攻擊
RUN chown -R ${USER_ID}:${GROUP_ID} ${ROOT} \
    && find / -perm /6000 -type f -exec chmod a-s {} + 2>/dev/null || true

# 切換使用者
USER ${USER}

# 設定 port
EXPOSE 8000

# 啟動容器時執行的命令
ENTRYPOINT ["start-container"]

# 健康檢查
# 這裡的 healthcheck 指令會在容器啟動後每 10 分鐘執行一次，並在 5 秒內超時。如果連續失敗 3 次，則認為容器不健康。
HEALTHCHECK --start-period=10s --interval=10m --timeout=5s --retries=3 CMD curl -f http://localhost:8000/up || exit 1
