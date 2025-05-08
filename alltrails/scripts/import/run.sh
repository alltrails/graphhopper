#!/bin/bash

JOB_NAME="${JOB_NAME:-graphhopper-service-importer}"
REGION="${REGION:-us-west-2}"
NAMESPACE="${NAMESPACE:-alpha}"
KUBE_CONTEXT="${KUBE_CONTEXT:-arn:aws:eks:us-west-2:873326996015:cluster/eks-alpha}"
VALUES="${VALUES:-alltrails/helm/graphhopper-service-importer/alpha-values.yaml}"
GIT_HASH=$(git rev-parse --short HEAD)
IMAGE_TAG="${IMAGE_TAG:-$GIT_HASH}"

helm upgrade --install "${JOB_NAME}" alltrails/helm/graphhopper-service-importer \
    --kube-context "${KUBE_CONTEXT}" \
    --namespace "${NAMESPACE}" \
    --wait \
    --timeout 10m \
    --atomic \
    --debug \
    --values "${VALUES}" \
    --set image.tag="${IMAGE_TAG}" \
    --set region="${REGION}"