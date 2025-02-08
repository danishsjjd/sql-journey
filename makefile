build-pg:
	docker build -t custom-postgres ./docker

start-pg:
	docker run --name postgres \
          -e POSTGRES_USER=user \
          -e POSTGRES_PASSWORD=password \
          -e POSTGRES_DB=mydb \
          -p 5432:5432 \
          -v "$${PWD}/docker/init-pg-cron.sh:/docker-entrypoint-initdb.d/init-pg-cron.sh" \
          -d custom-postgres

stop-pg:
	docker stop postgres
	docker rm postgres
