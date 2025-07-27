FROM composer:2.8 AS vendor

FROM php:8.4-cli-bookworm AS base

ARG APP_ENV
ARG WWWUSER=1000
ARG WWWGROUP=1000
ARG TZ=Asia/Taipei

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-color \
    TZ=${TZ} \
    USER=laravel \
    APP_ENV=${APP_ENV} \
    ROOT=/var/www/html \
    COMPOSER_FUND=0 \
    COMPOSER_MAX_PARALLEL_HTTP=24

WORKDIR ${ROOT}

# 使用 bash 作為默認 shell 以便執行較新的指令
SHELL ["/bin/bash", "-eou", "pipefail", "-c"]

# 設定時區
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone

# 安裝 PHP 擴展安裝器
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

#  安裝必要的套件
RUN apt-get update; \
    apt-get upgrade -yqq; \
    apt-get install -yqq --no-install-recommends --show-progress \
    apt-utils \
    curl \
    wget \
    vim \
    git \
    # ncdu:這是一個磁碟使用分析工具。
    # ncdu \
    # procps:包含 ps, top 等進程管理工具。
    procps \
    unzip \
    ca-certificates \
    supervisor \
    libsodium-dev \
    libbrotli-dev \
    # 以下為使用 Install PHP extensions 所安裝的擴充套件
    && install-php-extensions \
    bz2 \
    pcntl \
    mbstring \
    bcmath \
    sockets \
    # pgsql:使用Postgres才打開
    # pgsql \
    # pdo_pgsql:使用Postgres才打開
    # pdo_pgsql \
    opcache \
    exif \
    pdo_mysql \
    zip \
    uv \
    vips \
    intl \
    gd \
    redis \
    memcached \
    igbinary \
    # ldap \
    && apt-get -y autoremove \
    && apt-get clean \
    && docker-php-source delete \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && rm /var/log/lastlog /var/log/faillog

# 根據容器架構（armhf, aarch64, x86_64, x86）選擇對應的 supercronic 可執行檔名稱
# 如果架構不被支援則停止建置並輸出錯誤
# 然後從 GitHub 下載對應版本的 supercronic，放到 /usr/bin 並給予執行權限
# 接著建立 /etc/supercronic 資料夾，並新增一個排程檔 laravel
# 內容是每分鐘執行一次 Laravel 的排程任務 (php artisan schedule:run --no-interaction)
# supercronic 是輕量級的 cron 替代品，適合在容器中使用，因為它能處理 log 並維持前景執行（避免容器退出）
RUN arch="$(uname -m)" \
    && case "$arch" in \
    armhf) _cronic_fname='supercronic-linux-arm' ;; \
    aarch64) _cronic_fname='supercronic-linux-arm64' ;; \
    x86_64) _cronic_fname='supercronic-linux-amd64' ;; \
    x86) _cronic_fname='supercronic-linux-386' ;; \
    *) echo >&2 "error: unsupported architecture: $arch"; exit 1 ;; \
    esac \
    && wget -q "https://github.com/aptible/supercronic/releases/download/v0.2.34/${_cronic_fname}" \
    -O /usr/bin/supercronic \
    && chmod +x /usr/bin/supercronic \
    && mkdir -p /etc/supercronic \
    && echo "*/1 * * * * php ${ROOT}/artisan schedule:run --no-interaction" > /etc/supercronic/laravel

# 刪除預設的 www-data 使用者和群組，並創建新的使用者和群組
RUN userdel --remove --force www-data \
    && groupadd --force -g ${WWWGROUP} ${USER} \
    && useradd -ms /bin/bash --no-log-init --no-user-group -g ${WWWGROUP} -u ${WWWUSER} ${USER}

# 設定工作目錄權限
RUN chown -R ${USER}:${USER} ${ROOT} /var/{log,run} \
    && chmod -R a+rw ${ROOT} /var/{log,run}

# 複製 php.ini
RUN cp ${PHP_INI_DIR}/php.ini-production ${PHP_INI_DIR}/php.ini

# 切換到指定使用者
USER ${USER}

# 複製 composer
COPY --link --chown=${WWWUSER}:${WWWUSER} --from=vendor /usr/bin/composer /usr/bin/composer

# 複製 supervisord 配置檔案
COPY --link --chown=${WWWUSER}:${WWWUSER} docker/php-cli/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 客制化 php.ini 配置
COPY --link --chown=${WWWUSER}:${WWWUSER} docker/php-cli/php.ini ${PHP_INI_DIR}/conf.d/app.ini

# 複製 啟動容器時執行的命令
COPY --link --chown=${WWWUSER}:${WWWUSER} docker/php-cli/start-container /usr/local/bin/start-container

# 啟動容器時執行的命令 權限設定
RUN chmod +x /usr/local/bin/start-container

###########################################
FROM base AS common

USER ${USER}

# 複製 Laravel 檔案
COPY --link --chown=${WWWUSER}:${WWWUSER} . .

# 安裝套件
RUN composer install \
    --no-dev \
    --no-interaction \
    --no-autoloader \
    --no-ansi \
    --no-scripts \
    --audit
###########################################
FROM common AS runner

ARG ENV_FILE

USER ${USER}

# 複製 Laravel 檔案
COPY --link --chown=${WWWUSER}:${WWWUSER} . .

# 複製環境變數檔案
COPY --link --chown=${WWWUSER}:${WWWUSER} ./envs/${ENV_FILE} .env

# 授予 artisan 執行權限
RUN chmod +x ${ROOT}/artisan

# 設定 Laravel 資料夾的權限
RUN mkdir -p \
    storage/framework/{sessions,views,cache,testing} \
    storage/logs \
    bootstrap/cache && chmod -R a+rw storage

# 安裝套件
RUN composer install \
    --classmap-authoritative \
    --no-interaction \
    --no-ansi \
    --no-dev \
    && composer clear-cache
###########################################

# 設定 port
EXPOSE 8000

# 啟動容器時執行的命令
ENTRYPOINT ["start-container"]

# 健康檢查
# 這裡的 healthcheck 指令會在容器啟動後每 10 分鐘執行一次，並在 5 秒內超時。如果連續失敗 3 次，則認為容器不健康。
HEALTHCHECK --start-period=10s --interval=10m --timeout=5s --retries=3 CMD curl -f http://localhost:8000/up || exit 1
