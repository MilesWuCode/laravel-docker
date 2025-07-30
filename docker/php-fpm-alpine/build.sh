#!/usr/bin/env sh

docker rm -f app-fpm-alpine-local

docker rmi app-fpm-alpine-local

docker build \
--build-arg ENV_FILE=local.env \
-f ./docker/php-fpm-alpine/Dockerfile \
-t app-fpm-alpine-local:latest .

# amd64
# --platform linux/amd64 \

docker run --name app-fpm-alpine-local \
-p 3001:8000 \
-e APP_ENV=production \
--restart unless-stopped \
--network public-network \
-d app-fpm-alpine-local:latest

# check crontab
# docker exec -it container crontab -l
