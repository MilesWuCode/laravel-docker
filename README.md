# Laravel Docker - PHP-CLI / PHP-FPM

This project's is heavily inspired by smortexa's work and laravel-octane-dockerfile contributors

Reference: [laravel-octane-dockerfile](https://github.com/exaco/laravel-octane-dockerfile)

## Feature

-   PHP-CLI / PHP-FPM
-   Scheduler
-   Queue

## Install

-   Laravel Horizon
-   Redis

## Config

envs/local.env

```ini
QUEUE_CONNECTION=redis
REDIS_HOST=redis
```

## Redis

```bash
docker run --name redis \
-p 6379:6379 \
--restart unless-stopped \
--network public-network \
-d redis:alpine
```

## Run

```bash
docker network create public-network

# php-cli
sh docker/php-cli/build.sh

# php-fpm
sh docker/php-fpm/build.sh
```

## Test

Queue : app/Jobs/TestQueueJob.php

Scheduler : routes/web.php
