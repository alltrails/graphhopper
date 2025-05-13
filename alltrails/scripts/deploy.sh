#!/bin/bash

REGION="${REGION:-us-west-2}"
NAMESPACE="${NAMESPACE:-alpha}"
KUBE_CONTEXT="${KUBE_CONTEXT:-arn:aws:eks:us-west-2:873326996015:cluster/eks-alpha}"
VALUES="${VALUES:-alltrails/helm/graphhopper-service/alpha-values.yaml}"
GIT_HASH=$(git rev-parse --short HEAD)
IMAGE_TAG="${IMAGE_TAG:-$GIT_HASH}"
DEPLOYMENT_NAME="${DEPLOYMENT_NAME:-graphhopper-service}"

helm upgrade --install "${DEPLOYMENT_NAME}" \
alltrails/helm/graphhopper-service \
    --kube-context "${KUBE_CONTEXT}" \
    --namespace "${NAMESPACE}" \
    --wait --timeout 16m --atomic --debug \
    --values "${VALUES}" \
    --set image.tag="${IMAGE_TAG}" \
    --set region="${REGION}"
