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

## Redis & Mailpit

```bash
docker run --name redis \
-p 6379:6379 \
--restart unless-stopped \
--network public-network \
-d redis:alpine

docker run --name mailpit \
-p 1025:1025 \
-p 8025:8025 \
--restart unless-stopped \
-d axllent/mailpit:latest
```

## Run

```bash
docker network create public-network

sh docker/php-cli/build.sh
sh docker/php-cli-alpine/build.sh
sh docker/php-fpm/build.sh
sh docker/php-fpm-alpine/build.sh
```

## Test

Queue : app/Jobs/TestQueueJob.php

Scheduler : routes/web.php
