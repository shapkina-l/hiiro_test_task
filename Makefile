IMAGE_NAME   := devops-task
TAG          := local
FULL_IMAGE   := $(IMAGE_NAME):$(TAG)
NAMESPACE    := devops-task
CLUSTER_NAME := devops-task

.PHONY: all build scan load deploy setup teardown port-forward

all: build scan load deploy

setup:
	@echo ">>> Creating kind cluster..."
	kind create cluster --name $(CLUSTER_NAME) || true
	kubectl create namespace $(NAMESPACE) || true

build:
	@echo ">>> Building image..."
	docker build -t $(FULL_IMAGE) .

scan:
	@echo ">>> Scanning for vulnerabilities..."
	trivy image --exit-code 0 --severity HIGH,CRITICAL $(FULL_IMAGE)

load:
	@echo ">>> Loading image into kind..."
	kind load docker-image $(FULL_IMAGE) --name $(CLUSTER_NAME)

deploy:
	@echo ">>> Deploying to Kubernetes..."
	kubectl apply -f k8s/namespace.yaml
	kubectl apply -f k8s/
	kubectl rollout status deployment/$(IMAGE_NAME) -n $(NAMESPACE)

port-forward:
	kubectl port-forward svc/$(IMAGE_NAME) 8080:80 -n $(NAMESPACE)

teardown:
	kind delete cluster --name $(CLUSTER_NAME)