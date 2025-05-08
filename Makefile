ENV ?= dev

# Tag images with the git hash unless specified
GIT_HASH = $(shell git rev-parse --short HEAD)
IMAGE_TAG ?= $(GIT_HASH)

# Use the data from ./dataversion unless specified
LATEST_DATA_VERSION = $(shell head -n 1 ./dataversion)
DATA_VERSION ?= $(LATEST_DATA_VERSION)

JAVA_OPTS = -Xmx156g -Xms156g -javaagent:/usr/lib/dd-java-agent.jar
DEPLOYMENT_NAME = graphhopper-service

ifeq ($(ENV),dev)
IMPORT_FILE = /graphhopper/data/berlin-latest.osm.pbf
JAVA_OPTS = -Xmx9g -Xms9g -javaagent:/usr/lib/dd-java-agent.jar
endif

ifeq ($(ENV),alpha)
ACCOUNT_ID = 873326996015
AWS_PROFILE = mostpaths
KUBE_CONTEXT = arn:aws:eks:us-west-2:873326996015:cluster/eks-alpha
NAMESPACE = alpha
REGION = us-west-2
VALUES = alltrails/helm/graphhopper-service/values-alpha.yaml
IMPORT_VALUES = alltrails/helm/graphhopper-service-importer/values-alpha.yaml
IMPORT_JOB_NAME = graphhopper-service-importer
IMPORT_JAVA_OPTS = -Xmx416g -Xms416g
IMPORT_S3_DIR = /graphhopper/data/import-data/
IMPORT_FILE = /graphhopper/data/planet-latest.osm.pbf
endif

ifeq ($(ENV),alpha_ap)
ACCOUNT_ID = 873326996015
AWS_PROFILE = mostpaths
KUBE_CONTEXT = arn:aws:eks:ap-southeast-2:873326996015:cluster/eks-alpha-sydney
NAMESPACE = alpha
REGION = ap-southeast-2
VALUES = alltrails/helm/graphhopper-service/values-alpha.yaml
endif

ifeq ($(ENV),alpha_eu)
ACCOUNT_ID = 873326996015
AWS_PROFILE = mostpaths
KUBE_CONTEXT = arn:aws:eks:eu-west-1:873326996015:cluster/eks-alpha-eu
NAMESPACE = alpha
REGION = eu-west-1
VALUES = alltrails/helm/graphhopper-service/values-alpha.yaml
endif

ifeq ($(ENV),test)
ACCOUNT_ID = 873326996015
AWS_PROFILE = mostpaths
KUBE_CONTEXT = arn:aws:eks:us-west-2:873326996015:cluster/eks-alpha
NAMESPACE = alpha
REGION = us-west-2
VALUES = alltrails/helm/graphhopper-service/values-test.yaml
IMPORT_VALUES = alltrails/helm/graphhopper-service-importer/values-test.yaml
DATA_VERSION = import-data-test
IMAGE_TAG = test
JAVA_OPTS = -Xmx12g -Xms12g -javaagent:/usr/lib/dd-java-agent.jar
DEPLOYMENT_NAME = graphhopper-service-test
IMPORT_JOB_NAME = graphhopper-service-importer-test
IMPORT_JAVA_OPTS = -Xmx12g -Xms12g
IMPORT_S3_DIR = /graphhopper/data/import-data-test/
IMPORT_FILE = /graphhopper/data/berlin-latest.osm.pbf
endif

ifeq ($(ENV),prod)
ACCOUNT_ID = 434355312983
AWS_PROFILE = root
KUBE_CONTEXT = arn:aws:eks:us-west-2:434355312983:cluster/alltrails-production
NAMESPACE = production
REGION = us-west-2
VALUES = alltrails/helm/graphhopper-service/values-production.yaml
endif

ifeq ($(ENV),prod_ap)
ACCOUNT_ID = 434355312983
AWS_PROFILE = root
KUBE_CONTEXT = arn:aws:eks:ap-southeast-2:434355312983:cluster/eks-prod-sydney
NAMESPACE = production
REGION = ap-southeast-2
VALUES = alltrails/helm/graphhopper-service/values-production.yaml
endif

ifeq ($(ENV),prod_eu)
ACCOUNT_ID = 434355312983
AWS_PROFILE = root
KUBE_CONTEXT = arn:aws:eks:eu-west-1:434355312983:cluster/eks-production-eu
NAMESPACE = production
REGION = eu-west-1
VALUES = alltrails/helm/graphhopper-service/values-production.yaml
endif

docker-build:
ifeq ($(ENV),dev)
	@echo "Building $(ENV) image..."
	DATA_VERSION="${DATA_VERSION}" ./alltrails/scripts/local/build_graphhopper.sh
else
	@echo "Building $(ENV) image..."
	IMAGE_TAG="${IMAGE_TAG}" DATA_VERSION="${DATA_VERSION}" JAVA_OPTS="${JAVA_OPTS}" ./alltrails/scripts/docker_build.sh
endif

docker-login:
ifeq ($(ENV),dev)
	@echo "🚫 Can't login to dev."
else
	@echo "Logging in to $(ENV)..."
	AWS_PROFILE="${AWS_PROFILE}" REGION="${REGION}" ACCOUNT_ID="${ACCOUNT_ID}" ./alltrails/scripts/docker_login.sh
endif

docker-push:
ifeq ($(ENV),dev)
	@echo "🚫 Can't push to dev."
else
	@echo "Pushing to $(ENV)..."
	REGION="${REGION}" IMAGE_TAG="${IMAGE_TAG}" ACCOUNT_ID="${ACCOUNT_ID}" ./alltrails/scripts/docker_push.sh
endif

deploy:
ifeq ($(ENV),dev)
	@echo "🚫 Can't deploy to dev."
else
	@echo "Deploying to $(ENV)..."
	REGION="${REGION}" IMAGE_TAG="${IMAGE_TAG}" KUBE_CONTEXT="${KUBE_CONTEXT}" NAMESPACE="${NAMESPACE}" VALUES="${VALUES}" DEPLOYMENT_NAME="${DEPLOYMENT_NAME}" ./alltrails/scripts/deploy.sh
endif

run:
ifeq ($(ENV),dev)
	docker run --rm -p 8989:8989 -v ./alltrails/data:/graphhopper/data graphhopper-service --host 0.0.0.0
else
	@echo "🚫 Can't run in $(ENV)."
endif

import-docker-build:
ifeq ($(ENV),dev)
	@echo "Building $(ENV) image..."
	./alltrails/scripts/local/build_graphhopper.sh
else ifneq ($(filter $(ENV),alpha test),)
	echo "Building $(ENV) image..."
	IMAGE_TAG="${IMAGE_TAG}" IMPORT_FILE="${IMPORT_FILE}" JAVA_OPTS="${IMPORT_JAVA_OPTS}" S3_DIR="${IMPORT_S3_DIR}" ./alltrails/scripts/import/docker_build.sh
else
	@echo "🚫 Can't run the importer in $(ENV)."
endif

import-docker-push:
ifneq ($(filter $(ENV),alpha test),)
	@echo "Pushing to $(ENV)..."
	REGION="${REGION}" IMAGE_TAG="${IMAGE_TAG}" ACCOUNT_ID="${ACCOUNT_ID}" ./alltrails/scripts/import/docker_push.sh
else
	@echo "🚫 Can't push to $(ENV)."
endif

import-run:
ifeq ($(ENV),dev)
	docker run --rm -p 8989:8989 -v ./alltrails/data:/graphhopper/data graphhopper-service --import -i ${IMPORT_FILE}
else ifneq ($(filter $(ENV),alpha test),)
	@echo "Running $(ENV) image..."
	JOB_NAME="${IMPORT_JOB_NAME}" IMAGE_TAG="${IMAGE_TAG}" KUBE_CONTEXT="${KUBE_CONTEXT}" NAMESPACE="${NAMESPACE}" VALUES="${IMPORT_VALUES}" ./alltrails/scripts/import/run.sh
else
	@echo "🚫 Can't run the importer in $(ENV)."
endif
