PROJECT_NAME=ip-spectre
TF_DIR=terraform
DOCKER_IMAGE=ip-spectre-app

init:
	cd $(TF_DIR) && terraform init

validate:
	cd $(TF_DIR) && terraform validate

plan:
	cd $(TF_DIR) && terraform plan

apply:
	cd $(TF_DIR) && terraform apply

destroy:
	cd $(TF_DIR) && terraform destroy

docker-build:
	docker build -t $(DOCKER_IMAGE) -f docker/Dockerfile .

docker-run:
	docker run -it $(DOCKER_IMAGE)

lambda-zip:
	powershell -Command "Compress-Archive -Path .\\lambda\\lambda_function.py -DestinationPath .\\lambda\\lambda_function.zip -Force"

run-cli:
	python cli/main.py