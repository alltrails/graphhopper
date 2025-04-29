#!/bin/bash

export AWS_PROFILE=${AWS_PROFILE}
docker login -u AWS -p "$(aws ecr get-login-password --region "${REGION}")" "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"