#! /bin/bash

echo "Building graphhopper-service-importer:graphhopper-service-importer"
BUILDKIT_PROGRESS=plain DOCKER_BUILDKIT=1 docker buildx build \
  -t "graphhopper-service-importer:graphhopper-service-importer" \
  --platform linux/amd64 --file alltrails/import.Dockerfile .

echo "Tagging graphhopper-service-importer:graphhopper-service-importer"
docker tag graphhopper-service-importer:graphhopper-service-importer 873326996015.dkr.ecr.us-west-2.amazonaws.com/graphhopper-service-importer:graphhopper-service-importer

echo "Pushing graphhopper-service-importer:graphhopper-service-importer"
docker push 873326996015.dkr.ecr.us-west-2.amazonaws.com/graphhopper-service-importer:graphhopper-service-importer

# Check the exit code of the previous command
if [ $? -ne 0 ]; then
  echo "Docker push failed..."
  exit 1
fi

echo "✅ Image pushed - graphhopper-service-importer:graphhopper-service-importer"