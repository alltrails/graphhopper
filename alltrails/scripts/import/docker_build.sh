#! /bin/bash
REPO_NAME="graphhopper-service-importer"
GIT_HASH=$(git rev-parse --short HEAD)
IMAGE_TAG="${IMAGE_TAG:-$GIT_HASH}"
IMPORT_FILE="${IMPORT_FILE:-/graphhopper/data/planet-latest.osm.pbf}"
JAVA_OPTS="${JAVA_OPTS:-"-Xmx9g -Xms9g"}"
S3_DIR="${S3_DIR:-/graphhopper/data/import-data/}"

echo "Building Docker image - ${REPO_NAME}:${IMAGE_TAG}"
BUILDKIT_PROGRESS=plain DOCKER_BUILDKIT=1 docker buildx build \
  -t "${REPO_NAME}:${IMAGE_TAG}" \
  --platform linux/amd64 --file alltrails/import.Dockerfile . \
  --build-arg JAVA_OPTS="${JAVA_OPTS}" \
  --build-arg IMPORT_FILE="${IMPORT_FILE}" \
  --build-arg S3_DIR="${S3_DIR}"