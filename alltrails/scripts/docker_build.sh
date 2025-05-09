#!/bin/bash

REPO_NAME="graphhopper-service"
GIT_HASH=$(git rev-parse --short HEAD)
IMAGE_TAG="${IMAGE_TAG:-$GIT_HASH}"
LATEST_DATA_VERSION=$(head -n 1 ./dataversion)
DATA_VERSION="${DATA_VERSION:-$LATEST_DATA_VERSION}"
JAVA_OPTS="${JAVA_OPTS:-"-Xmx9g -Xms9g -javaagent:/usr/lib/dd-java-agent.jar"}"

echo "Building Docker image - ${REPO_NAME}:${IMAGE_TAG}"
BUILDKIT_PROGRESS=plain DOCKER_BUILDKIT=1 docker buildx build \
  -t "${REPO_NAME}:${IMAGE_TAG}" \
  --platform linux/amd64 --file alltrails/Dockerfile . \
  --build-arg DATA_VERSION="${DATA_VERSION}" \
  --build-arg JAVA_OPTS="${JAVA_OPTS}" \

echo "✅ Image built - ${REPO_NAME}:${IMAGE_TAG}"
