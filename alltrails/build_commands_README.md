# Build Commands

All of the graphhopper build and deploy processes are managed with our [make](https://www.gnu.org/software/make/) commands.

An `ENV` can be passed to each of these commands to setup the [default configurations](#default-values) for a given environment. If no `ENV` is passed it will default to `dev`.

## Commands
1. [docker-build](#docker-build)
2. [docker-push](#docker-push)
3. [deploy](#deploy)
4. [run](#run)
5. [import-docker-build](#import-docker-build)
6. [import-docker-push](#import-docker-push)
7. [import-run](#import-run)

### docker-build

Builds a `graphhopper-service` or a `graphhopper-service-test` docker image.

Usage:
```bash
make docker-build ENV=test
```

Variables:

| Variable       | Required | Description                                                                 | Example                              |
|----------------|----------|-----------------------------------------------------------------------------|--------------------------------------|
| **`ENV`**      | Yes      | Specifies the environment for the build. Supported values: `dev`, `alpha`, `test`, `prod`. | `ENV=alpha`                         |
| **`IMAGE_TAG`**| No       | Specifies the Docker image tag. Defaults to the current Git hash if not provided. | `IMAGE_TAG=example-tag`           |
| **`DATA_VERSION`** | No    | Specifies the version of the data to include in the build.                  | `DATA_VERSION=default-gh-1746469916`           |
| **`JAVA_OPTS`**| No       | Specifies Java options for the service.                                     | `JAVA_OPTS="-Xmx12g -Xms12g -javaagent:/usr/lib/dd-java-agent.jar"`         |

### docker-push

Pushes a graphhopper-service docker image to ECR.

Usage:
```bash
make docker-push ENV=test
```

Variables:

| Variable       | Required | Description                                                                 | Example                              |
|----------------|----------|-----------------------------------------------------------------------------|--------------------------------------|
| **`ENV`**      | Yes      | Specifies the environment for the push. Supported values: `alpha`, `alpha_ap`, `alpha_eu`, `test`, `prod`, `prod_ap`, `prod_eu`. | `ENV=alpha`                         |
| **`IMAGE_TAG`**| No      | Specifies the Docker image tag to push.                                     | `IMAGE_TAG=example-tag`           |
| **`REGION`**   | No      | Specifies the AWS region for the ECR repository.                           | `REGION=us-west-2`                  |
| **`ACCOUNT_ID`**| No     | Specifies the AWS account ID for the ECR repository.                       | `ACCOUNT_ID=873326996015`           |

### deploy

Creates a `graphhopper-service` or `graphhopper-service-test` deployment.

Usage:
```bash
make deploy ENV=test
```

Variables:

| Variable       | Required | Description                                                                 | Example                              |
|----------------|----------|-----------------------------------------------------------------------------|--------------------------------------|
| **`ENV`**      | Yes      | Specifies the environment for the deployment. Supported values: `alpha`, `alpha_ap`, `alpha_eu`, `test`, `prod`, `prod_ap`, `prod_eu`. | `ENV=alpha`                         |
| **`IMAGE_TAG`**| No      | Specifies the Docker image tag to deploy.                                   | `IMAGE_TAG=example-tag`           |
| **`REGION`**   | No      | Specifies the AWS region for the Kubernetes cluster.                        | `REGION=us-west-2`                  |
| **`KUBE_CONTEXT`** | No  | Specifies the Kubernetes context to use for the deployment.                 | `KUBE_CONTEXT=arn:aws:eks:us-west-2:873326996015:cluster/eks-alpha` |
| **`NAMESPACE`**| No      | Specifies the Kubernetes namespace for the deployment.                      | `NAMESPACE=alpha`                   |
| **`VALUES`**   | No      | Specifies the Helm values file to use for the deployment.                   | `VALUES=alltrails/helm/graphhopper-service/values-alpha.yaml` |
| **`DEPLOYMENT_NAME`** | No | Specifies the name of the Kubernetes deployment. This should either be graphhopper-service or graphhopper-service-test.                           | `DEPLOYMENT_NAME=graphhopper-service-test` |

### run

Runs the latest docker image locally. This command is only availabe in `ENV=dev`.

Usage:
```bash
make run
```

### import-docker-build

Builds a `graphhopper-service-importer` or a `graphhopper-service-importer-test` docker image.

Usage:
```bash
make import-docker-build ENV=test
```

Variables:

| Variable       | Required | Description                                                                 | Example                              |
|----------------|----------|-----------------------------------------------------------------------------|--------------------------------------|
| **`ENV`**      | Yes      | Specifies the environment for the build. Supported values: `dev`, `alpha`, `test`. | `ENV=alpha`                         |
| **`IMAGE_TAG`**| No       | Specifies the Docker image tag.                                             | `IMAGE_TAG=example-tag`           |
| **`IMPORT_FILE`** | No    | Specifies the OSM file to import. This should always start with `/graphhopper/data/` because that is the root of the s3 bucket.                                           | `IMPORT_FILE=/graphhopper/data/planet-latest.osm.pbf` |
| **`IMPORT_CSV`** | No    | Specifies the AllTrails custom attributes CSV to import. This should always start with `/graphhopper/data/` because that is the root of the s3 bucket.                                           | `IMPORT_CSV=/graphhopper/data/byot_custom_routing_weights.csv` |
| **`IMPORT_JAVA_OPTS`**| No       | Specifies Java options for the importer. Used to give the JVM more memory to import larger areas.                                    | `JAVA_OPTS="-Xmx9g -Xms9g"`         |
| **`IMPORT_S3_DIR`**   | No       | Specifies the directory for S3 uploads. This should always start with `/graphhopper/data/` because that is the root of the s3 bucket.                                    | `S3_DIR=/graphhopper/data/example-data`             |

### import-docker-push

Pushes a `graphhopper-service-importer` docker image to ECR.

Usage:
```bash
make import-docker-push ENV=test
```

Variables:

| Variable       | Required | Description                                                                 | Example                              |
|----------------|----------|-----------------------------------------------------------------------------|--------------------------------------|
| **`ENV`**      | Yes      | Specifies the environment for the push. Supported values: `alpha`, `test`.  | `ENV=alpha`                         |
| **`IMAGE_TAG`**| Yes      | Specifies the Docker image tag to push.                                     | `IMAGE_TAG=example-tag`           |
| **`REGION`**   | Yes      | Specifies the AWS region for the ECR repository.                           | `REGION=us-west-2`                  |
| **`ACCOUNT_ID`**| Yes     | Specifies the AWS account ID for the ECR repository.                       | `ACCOUNT_ID=873326996015`           |

### import-run

Starts a `graphhopper-service-importer` or a `graphhopper-service-importer-test` job in k8s. If run in `ENV=dev` this will run the importer locally.

Usage:
```bash
make import-run ENV=test
```

Variables:

| Variable           | Required | Description                                                                 | Example                              |
|--------------------|----------|-----------------------------------------------------------------------------|--------------------------------------|
| **`ENV`**          | Yes      | Specifies the environment for running the importer. Supported values: `dev`, `alpha`, `test`. | `ENV=alpha`                         |
| **`IMPORT_FILE`**  | Yes      | Specifies the OSM file to import.                                           | `IMPORT_FILE=/graphhopper/data/planet-latest.osm.pbf` |
| **`IMPORT_CSV`**   | Yes      | Specifies the AllTrails custom attributes CSV to import.                    | `IMPORT_CSV=/graphhopper/data/byot_custom_routing_weights.csv` |
| **`IMAGE_TAG`**    | Yes      | Specifies the Docker image tag to use for the importer.                     | `IMAGE_TAG=example-tag`           |
| **`REGION`**       | Yes      | Specifies the AWS region for the Kubernetes cluster.                        | `REGION=us-west-2`                  |
| **`KUBE_CONTEXT`** | Yes      | Specifies the Kubernetes context to use for the importer job.               | `KUBE_CONTEXT=arn:aws:eks:us-west-2:123456789012:cluster/eks-alpha` |
| **`NAMESPACE`**    | Yes      | Specifies the Kubernetes namespace for the importer job.                   | `NAMESPACE=alpha`                   |
| **`IMPORT_VALUES`**| Yes      | Specifies the Helm values file to use for the importer job.                 | `IMPORT_VALUES=alltrails/helm/graphhopper-service-importer/values-alpha.yaml` |
| **`IMPORT_JOB_NAME`** | Yes   | Specifies the name of the Kubernetes job for the importer. This should either be `graphhopper-service-importer` or `graphhopper-service-importer-test`.                  | `IMPORT_JOB_NAME=graphhopper-service-importer-alpha` |

## Default Values

| Variable            | alpha                                         | alpha_ap                                      | alpha_eu                                     | dev                                       | prod                                        | prod_ap                                     | prod_eu                                     | test                                                                 |
|---------------------|-----------------------------------------------|-----------------------------------------------|----------------------------------------------|--------------------------------------------|---------------------------------------------|---------------------------------------------|---------------------------------------------|----------------------------------------------------------------------|
| ACCOUNT_ID          | 873326996015                                  | 873326996015                                  | 873326996015                                 |                                              | 434355312983                                | 434355312983                                | 434355312983                                | 873326996015                                                       |
| AWS_PROFILE         | mostpaths                                     | mostpaths                                     | mostpaths                                    |                                              | root                                        | root                                        | root                                        | mostpaths                                                           |
| DATA_VERSION        | *(from `./dataversion`)*                      | *(from `./dataversion`)*                      | *(from `./dataversion`)*                     | *(from `./dataversion`)*                   | *(from `./dataversion`)*                    | *(from `./dataversion`)*                    | *(from `./dataversion`)*                    | import-data-test                                                   |
| DEPLOYMENT_NAME     | graphhopper-service                           | graphhopper-service                           | graphhopper-service                          | graphhopper-service                         | graphhopper-service                          | graphhopper-service                          | graphhopper-service                          | graphhopper-service-test                                           |
| GIT_HASH            | *(from `git rev-parse --short HEAD`)*         | *(from `git rev-parse --short HEAD`)*         | *(from `git rev-parse --short HEAD`)*        | *(from `git rev-parse --short HEAD`)*       | *(from `git rev-parse --short HEAD`)*       | *(from `git rev-parse --short HEAD`)*       | *(from `git rev-parse --short HEAD`)*       | *(from `git rev-parse --short HEAD`)*                             |
| IMAGE_TAG           | *(defaults to `GIT_HASH`)*                    | *(defaults to `GIT_HASH`)*                    | *(defaults to `GIT_HASH`)*                   | *(defaults to `GIT_HASH`)*                  | *(defaults to `GIT_HASH`)*                  | *(defaults to `GIT_HASH`)*                  | *(defaults to `GIT_HASH`)*                  | test                                                               |
| IMPORT_FILE         | /graphhopper/data/planet-latest.osm.pbf      |                                               |                                              | /graphhopper/data/berlin-latest.osm.pbf     |                                             |                                             |                                             | /graphhopper/data/berlin-latest.osm.pbf                           |
| IMPORT_CSV          | /graphhopper/data/byot_custom_routing_weights.csv |                                           |                                              |                                            |                                             |                                             |                                             |
| IMPORT_JAVA_OPTS    | -Xmx416g -Xms416g                             |                                               |                                              |                                              |                                             |                                             |                                             | -Xmx12g -Xms12g                                                    |
| IMPORT_JOB_NAME     | graphhopper-service-importer                  |                                               |                                              |                                              |                                             |                                             |                                             | graphhopper-service-importer-test                                 |
| IMPORT_S3_DIR       | /graphhopper/data/import-data/                |                                               |                                              |                                              |                                             |                                             |                                             | /graphhopper/data/import-data-test/                                |
| IMPORT_VALUES       | alltrails/helm/graphhopper-service-importer/values-alpha.yaml |                                               |                                              |                                              |                                             |                                             |                                             | alltrails/helm/graphhopper-service-importer/values-test.yaml       |
| JAVA_OPTS           | -Xmx156g -Xms156g -javaagent:/usr/lib/dd-java-agent.jar |                                               |                                              | -Xmx9g -Xms9g -javaagent:/usr/lib/dd-java-agent.jar |                                     |                                             |                                             | -Xmx12g -Xms12g -javaagent:/usr/lib/dd-java-agent.jar             |
| KUBE_CONTEXT        | arn:aws:eks:us-west-2:873326996015:cluster/eks-alpha | arn:aws:eks:ap-southeast-2:873326996015:cluster/eks-alpha-sydney | arn:aws:eks:eu-west-1:873326996015:cluster/eks-alpha-eu |                                              | arn:aws:eks:us-west-2:434355312983:cluster/alltrails-production | arn:aws:eks:ap-southeast-2:434355312983:cluster/eks-prod-sydney | arn:aws:eks:eu-west-1:434355312983:cluster/eks-production-eu | arn:aws:eks:us-west-2:873326996015:cluster/eks-alpha               |
| NAMESPACE           | alpha                                         | alpha                                         | alpha                                        |                                              | production                                  | production                                  | production                                  | alpha                                                             |
| REGION              | us-west-2                                     | ap-southeast-2                                | eu-west-1                                    |                                              | us-west-2                                   | ap-southeast-2                              | eu-west-1                                  | us-west-2                                                         |
| VALUES              | alltrails/helm/graphhopper-service/values-alpha.yaml | alltrails/helm/graphhopper-service/values-alpha.yaml | alltrails/helm/graphhopper-service/values-alpha.yaml |                                              | alltrails/helm/graphhopper-service/values-production.yaml | alltrails/helm/graphhopper-service/values-production.yaml | alltrails/helm/graphhopper-service/values-production.yaml | alltrails/helm/graphhopper-service/values-test.yaml               |