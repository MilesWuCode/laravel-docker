FROM composer:2.9 AS vendor

FROM php:8.5-cli-trixie AS base

ARG APP_ENV
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG TZ=Asia/Taipei
ARG ENV_FILE

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-color \
    TZ=${TZ} \
    LANG=C.UTF-8 \
    USER=laravel \
    ROOT=/var/www/html \
    APP_ENV=${APP_ENV} \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_FUND=0 \
    COMPOSER_MAX_PARALLEL_HTTP=24

# XDG 基礎目錄設定
# - XDG_CONFIG_HOME: 設定檔位置（Composer、npm 等會用到）
# - XDG_DATA_HOME: 應用程式資料位置
ENV XDG_CONFIG_HOME=${ROOT}/.config XDG_DATA_HOME=${ROOT}/.data

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
    unzip \
    # ncdu:這是一個磁碟使用分析工具。
    # ncdu \
    # procps:包含 ps, top 等進程管理工具。
    procps \
    ca-certificates \
    supervisor \
    libsodium-dev \
    # 以下為使用 Install PHP extensions 所安裝的擴充套件
    && install-php-extensions \
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
    && apt-get -y autoremove \
    && apt-get clean \
    && docker-php-source delete \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/log/lastlog /var/log/faillog

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
    && wget -q "https://github.com/aptible/supercronic/releases/download/v0.2.45/${_cronic_fname}" \
    -O /usr/bin/supercronic \
    && chmod +x /usr/bin/supercronic \
    && mkdir -p /etc/supercronic \
    && echo "*/1 * * * * php ${ROOT}/artisan schedule:run --no-interaction" > /etc/supercronic/laravel

# 刪除預設的 www-data 使用者和群組，並創建新的使用者和群組
RUN userdel --remove --force www-data \
    && groupadd --force -g ${GROUP_ID} ${USER} \
    && useradd -ms /bin/bash --no-log-init --no-user-group -g ${GROUP_ID} -u ${USER_ID} ${USER}

# 複製 php.ini
RUN cp ${PHP_INI_DIR}/php.ini-production ${PHP_INI_DIR}/php.ini

# 複製 composer
COPY --link --from=vendor /usr/bin/composer /usr/bin/composer

# 複製 supervisord 配置檔案
COPY --link docker/php-cli/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 客制化 php.ini 配置
COPY --link docker/php-cli/php.ini ${PHP_INI_DIR}/conf.d/99-php.ini

# 複製 啟動容器時執行的命令
COPY --link docker/php-cli/start-container /usr/local/bin/start-container

# 複製 composer.json, composer.lock
COPY --link composer.* ./

# opcache.enable_cli=1 使得 PHP CLI（composer）在 build 時就初始化 opcache，
# 而 apk 安裝步驟已 rm -rf /tmp/*，因此需在 composer install 前重建目錄
RUN mkdir -p -m 700 /tmp/opcache-file-cache \
    && chown ${USER_ID}:${GROUP_ID} /tmp/opcache-file-cache

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
    storage/framework/{sessions,views,cache,testing} \
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
