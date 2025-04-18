ENV ?= dev

# Tag images with the git hash unless specified
GIT_HASH = $(shell git rev-parse --short HEAD)
IMAGE_TAG ?= $(GIT_HASH)

# Use the data from ./dataversion unless specified
LATEST_DATA_VERSION = $(shell head -n 1 ./dataversion)
DATA_VERSION ?= $(LATEST_DATA_VERSION)

ifeq ($(ENV),dev)
IMPORT_FILE = /graphhopper/data/berlin-latest.osm.pbf
endif

ifeq ($(ENV),alpha)
ACCOUNT_ID = 873326996015
KUBE_CONTEXT = arn:aws:eks:us-west-2:873326996015:cluster/eks-alpha
NAMESPACE = alpha
VALUES = alltrails/helm/graphhopper-service/values-alpha.yaml
endif

ifeq ($(ENV),prod)
ACCOUNT_ID = 434355312983
KUBE_CONTEXT = arn:aws:eks:us-west-2:434355312983:cluster/alltrails-production
NAMESPACE = production
VALUES = alltrails/helm/graphhopper-service/values-production.yaml
endif

docker-build:
ifeq ($(ENV),dev)
	@echo "Building $(ENV) image..."
	DATA_VERSION="${DATA_VERSION}" ./alltrails/scripts/local/build_graphhopper.sh
else
	@echo "Building $(ENV) image..."
	IMAGE_TAG="${IMAGE_TAG}" DATA_VERSION="${DATA_VERSION}" ./alltrails/scripts/docker_build.sh
endif

docker-push:
ifeq ($(ENV),dev)
	@echo "🚫 Can't push to dev."
else
	@echo "Pushing to $(ENV)..."
	IMAGE_TAG="${IMAGE_TAG}" ACCOUNT_ID="${ACCOUNT_ID}" ./alltrails/scripts/docker_push.sh
endif

deploy:
ifeq ($(ENV),dev)
	@echo "🚫 Can't deploy to dev."
else
	@echo "Deploying to $(ENV)..."
	IMAGE_TAG="${IMAGE_TAG}" KUBE_CONTEXT="${KUBE_CONTEXT}" NAMESPACE="${NAMESPACE}" VALUES="${VALUES}" ./alltrails/scripts/deploy.sh
endif

run:
ifeq ($(ENV),dev)
	docker run --rm -p 8989:8989 -v ./alltrails/data:/graphhopper/data graphhopper-service --host 0.0.0.0
else
	@echo "🚫 Can't run in $(ENV)."
endif

import-build:
ifeq ($(ENV),dev)
	./alltrails/scripts/local/build_graphhopper.sh
endif
ifeq ($(ENV),alpha)
	./alltrails/scripts/import/build_and_push_importer_alpha.sh
endif
ifeq ($(ENV),prod)
	@echo "🚫 Can't run the importer in prod."
endif

import-start:
ifeq ($(ENV),dev)
	docker run --rm -p 8989:8989 -v ./alltrails/data:/graphhopper/data graphhopper-service --import -i ${IMPORT_FILE}
endif
ifeq ($(ENV),alpha)
	helm upgrade --install "graphhopper-service-importer" alltrails/helm/graphhopper-service-importer --kube-context arn:aws:eks:us-west-2:873326996015:cluster/eks-alpha --namespace alpha --wait --timeout 10m --atomic --debug --values alltrails/helm/graphhopper-service-importer/values-alpha.yaml --set image.tag=graphhopper-service-importer --set region=us-west-2
endif
ifeq ($(ENV),prod)
	@echo "🚫 Can't run the importer in prod."
endif
