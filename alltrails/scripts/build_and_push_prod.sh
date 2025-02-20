#! /bin/bash

echo "Building graphhopper-service:graphhopper-service"
BUILDKIT_PROGRESS=plain DOCKER_BUILDKIT=1 docker buildx build \
  -t "graphhopper-service:graphhopper-service" \
  --platform linux/amd64 --file alltrails/Dockerfile . 

echo "Tagging graphhopper-service:graphhopper-service"
docker tag graphhopper-service:graphhopper-service 434355312983.dkr.ecr.us-west-2.amazonaws.com/graphhopper-service:graphhopper-service

echo "Pushing graphhopper-service:graphhopper-service"
docker push 434355312983.dkr.ecr.us-west-2.amazonaws.com/graphhopper-service:graphhopper-service
