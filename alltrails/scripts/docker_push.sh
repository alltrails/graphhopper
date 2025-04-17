#!/bin/bash

REGION="${REGION:-us-west-2}"
REPO_NAME="graphhopper-service"
ACCOUNT_ID="${ACCOUNT_ID:-873326996015}"
GIT_HASH=$(git rev-parse --short HEAD)
IMAGE_TAG="${IMAGE_TAG:-$GIT_HASH}"
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}"

echo "Tagging image for ECR - ${REPO_NAME}:${IMAGE_TAG} ${ECR_URL}:${IMAGE_TAG}"
docker tag "${REPO_NAME}:${IMAGE_TAG}" "${ECR_URL}:${IMAGE_TAG}"

echo "Pushing image to ECR ${ECR_URL}:${IMAGE_TAG}"
docker push "${ECR_URL}:${IMAGE_TAG}"

echo "✅ Image pushed - ${ECR_URL}:${IMAGE_TAG}"
