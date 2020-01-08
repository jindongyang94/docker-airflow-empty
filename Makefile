.PHONY: compose build kill webserver scheduler worker pushcurrent pushnext

# Build Docker Image Locally
build:
	docker build --rm -t hubble/docker-airflow:latest .

# Set up Local Docker Containers
compose:
	docker-compose -f docker-compose-CeleryExecutor.yml up -d
	@echo airflow running on http://localhost:8080

# Kill Local Docker Containers
kill:
	@echo "Killing all docker-airflow containers"
	docker-compose -f docker-compose-CeleryExecutor.yml down

# Enter Webserver Docker Container as Bash
webserver:
	@echo "Entering webserver in bash mode"
	docker exec -it $(shell docker ps -q --filter label=name=webserver) /entrypoint.sh bash

# Enter Scheduler Docker Container as Bash
scheduler:
	@echo "Entering scheduler in bash mode"
	docker exec -it $(shell docker ps -q --filter label=name=scheduler) /entrypoint.sh bash

# Enter Worker Docker Container as Bash
worker:
	@echo "Entering worker in bash mode"
	docker exec -it $(shell docker ps -q --filter label=name=worker) /entrypoint.sh bash

# Check what Docker Tag No. it is currently in AWS ECR Docker Repository
tag:
	@echo "Checking current tag number for hubble/airflow-docker"
	sh script/push_docker.sh

# Push Current Local Docker Image to SAME Tag to AWS ECR Docker Repository
# DO NOT USE THIS as deleting current tag is not a permission given unless you are admin.
pushcurrent: build
	@echo "Pushing current image to same current tag in Docker Repository"
	@echo "Do not use this unless you got administrative rights to delete tags!"
	sh script/push_docker.sh current

# Push Current Local Docker Image to NEXT Tag to AWS ECR Docker Repository 
pushnext: build
	@echo "Pushing current image to next tag in Docker Repository"
	sh script/push_docker.sh next

# Clean local builds and images to restart building from scratch and save space
clean:
	@echo "Deleting cache in local memory."
	docker system prune -a --volumes
	docker image prune -a