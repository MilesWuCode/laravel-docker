# Laravel Docker

## 安裝

-   Laravel Horizon
-   Redis

## 設定

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

docker rm -f app-local

docker rmi app-local

docker build \
--build-arg ENV_FILE=local.env \
-f ./docker/Dockerfile \
-t app-local:latest .

# amd64
# --platform linux/amd64 \

docker run --name app-local \
-p 8000:8000 \
-e APP_ENV=production \
--restart unless-stopped \
--network public-network \
-d app-local:latest

# check crontab
# docker exec -it container crontab -l
```
