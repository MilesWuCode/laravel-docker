#!/usr/bin/env sh

docker rm -f app-fpm-local

docker rmi app-fpm-local

docker build \
--build-arg ENV_FILE=local.env \
-f ./docker/php-fpm/Dockerfile \
-t app-fpm-local:latest .

# amd64
# --platform linux/amd64 \

docker run --name app-fpm-local \
-p 3000:8000 \
-e APP_ENV=production \
--restart unless-stopped \
--network public-network \
-d app-fpm-local:latest

# check crontab
# docker exec -it container crontab -l
