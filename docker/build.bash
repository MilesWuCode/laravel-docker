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
