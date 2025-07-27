#!/usr/bin/env sh

docker rm -f app-cli-local

docker rmi app-cli-local

docker build \
--build-arg ENV_FILE=local.env \
-f ./docker/php-cli/Dockerfile \
-t app-cli-local:latest .

# amd64
# --platform linux/amd64 \

docker run --name app-cli-local \
-p 8000:8000 \
-e APP_ENV=production \
--restart unless-stopped \
--network public-network \
-d app-cli-local:latest

# check crontab
# docker exec -it container crontab -l
