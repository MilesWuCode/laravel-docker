#!/usr/bin/env sh

docker rm -f app-cli-alpine-local

docker rmi app-cli-alpine-local

docker build \
--build-arg ENV_FILE=local.env \
-f ./docker/php-cli-alpine/Dockerfile \
-t app-cli-alpine-local:latest .

# amd64
# --platform linux/amd64 \

docker run --name app-cli-alpine-local \
-p 8001:8000 \
-e APP_ENV=production \
--restart unless-stopped \
--network public-network \
-d app-cli-alpine-local:latest

# check crontab
# docker exec -it container crontab -l
