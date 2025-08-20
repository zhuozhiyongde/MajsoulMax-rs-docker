docker build -t arthals/majsoul-max-rs:latest \
	--network host \
	--build-arg HTTP_PROXY=http://127.0.0.1:7890 \
	--build-arg HTTPS_PROXY=http://127.0.0.1:7890 \
    .
docker push arthals/majsoul-max-rs:latest