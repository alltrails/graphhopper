# graphhopper-service-test

graphhopper-service-test is a deployment of graphhopper-serivce that can be used for testing. Because it does not need to import the entire planet.osm, it can be used for faster iteration.

# Table of Contents
1. [Toolchain](#toolchain)
2. [Deployment](#deployment)
3. [Troubleshooting](#troubleshooting)

# Toolchain

In order to deploy this server, you will need to be familiar with our [SRE toolchain](https://alltrails.atlassian.net/wiki/spaces/AE/pages/1647312980/Recommended+SRE+Toolchain). Specifically, we will use Docker, AWS CLI, Kubectl and Helm.

#### Setup Your Env

The test server lives in the alpha account. Login to AWS, setup your kube config and login to ecr.

```bash
aws sso login
export AWS_PROFILE=mostpaths

kubectl config use-context arn:aws:eks:us-west-2:873326996015:cluster/eks-alpha
kubectl config set-context --current --namespace=alpha

docker login -u AWS -p $(aws ecr get-login-password --region us-west-2) 873326996015.dkr.ecr.us-west-2.amazonaws.com
```

# Deployment

Deploying The test service is a two-step process. First we run the importer to build a graph of OSM segments. Once the graph is built, we deploy the service pointed at our graph.

All of the make commands used in this process are configurable and explained in detail in the [build_commands_README.md](build_commands_README.md).

#### Importing the Graph

There are two inputs required for building the graph:
1. An osm.pbf file
2. A csv of custom weights

The CSV file **must** share the same name as the OSM file with `.csv` on the end. For example, if we're using `berlin-latest.osm.pbf`, we would need a csv called `berlin-latest.osm.pbf.csv`. Both of these files need to be at the top level of the `alltrails-alpha-us-west-2-graphhopper-service` in the `mostpaths` account in `us-west-2`.

Build the importer image:
```bash
make import-docker-build ENV=test IMPORT_FILE=/graphhopper/data/berlin-latest.osm.pbf
```

Push the importer image to ECR:
```bash
make import-docker-push ENV=test
```

Run the import job in k8s:
```bash
make import-run ENV=test
```

Logs for the import job can be seen [here](https://app.datadoghq.com/logs?query=service%3Agraphhopper-service-importer%20image_tag%3Atest&agg_m=count&agg_m_source=base&agg_t=count&cols=host%2Cservice%2Cimage_tag&messageDisplay=inline&refresh_mode=sliding&storage=hot&stream_sort=time%2Cdesc&viz=stream&from_ts=1746644364946&to_ts=1746658764946&live=true).

When the job is finished, it will copy the files to the `import-data-test` directory. The `graphhopper-service-test` deployment in the next step is configured to read the graph from this directory.

The finished job needs to be deleted before a new one can be started:
```bash
kubectl delete job graphhopper-service-importer-test
```

#### Deploying the test server

Now that the graph is created in the `import-data-test` directory of our s3 bucket, we can deploy our instance of graphhopper. It is important the the service image is built with the same configuration as the importer image. The server must have the same configuration as the graph.

Build the docker image:
```bash
make docker-build ENV=test
```

Push the image to ECR:
```bash
make docker-push ENV=test
```

Create the `graphhopper-service-test` deployment:
```bash
make deploy ENV=test
```

It can take a minute for the deployment to finish while graphhopper loads the graph into memory.

When the deploy completes, the webapp can be accessed [here](https://alpha.mostpaths.com/api/alltrails/graphhopper-service-test/maps/?profile=hike&layer=OpenStreetMap)



# Troubleshooting

#### Monitoring

If something is going wrong with the test service, these are good places to start investigating:

* [service logs](https://app.datadoghq.com/logs?query=aws_account%3A873326996015%20service%3Agraphhopper%20image_tag%3Atest&agg_m=count&agg_m_source=base&agg_t=count&cols=host%2Cservice%2Cimage_tag&messageDisplay=inline&refresh_mode=sliding&storage=hot&stream_sort=time%2Cdesc&viz=stream&from_ts=1746671335742&to_ts=1746672235742&live=true)
* [service pods overview dashboard](https://app.datadoghq.com/dash/integration/Kubernetes%20-%20Pods?fromUser=true&refresh_mode=sliding&tpl_var_cluster%5B0%5D=eks-alpha&tpl_var_deployment%5B0%5D=graphhopper-service-test&from_ts=1746672780405&to_ts=1746673680405&live=true)
* [importer logs](https://app.datadoghq.com/logs?query=aws_account%3A873326996015%20service%3Agraphhopper-service-importer%20image_tag%3Atest&agg_m=count&agg_m_source=base&agg_t=count&cols=host%2Cservice%2Cimage_tag&messageDisplay=inline&refresh_mode=sliding&storage=hot&stream_sort=time%2Cdesc&viz=stream&from_ts=1746671335742&to_ts=1746672235742&live=true)
* [importer pods overview dashboard](https://app.datadoghq.com/dash/integration/Kubernetes%20-%20Pods?fromUser=true&refresh_mode=sliding&tpl_var_cluster%5B0%5D=eks-alpha&tpl_var_job%5B0%5D=graphhopper-service-importer-test&from_ts=1746587492655&to_ts=1746673892655&live=true)

#### Deployment Not Restarting

Even though we have set `imagePullPolicy` to always, k8s doesn’t re-pull if the image is already cached and the pod isn't recreated. If this happens, just delete the deployment and re-deploy.

```bash
kubectl delete deploy graphhopper-service-test
make deploy ENV=test
```

#### Out Of Memory Errors

These are likely to happen when changing the size of the test data. There are two types of OOM errors that can happen here with two different solutions.

If the containers are running out of memory that can be seen the pods overview dashboard. In this case we need to increase the resource limits in the appropriate values-test.yaml file.

If the JVM is running out of memory that can be seen in the logs. In this case we need to increase the amount of memory allocated to the JVM via the `JAVA_OPTS` or `IMPORT_JAVA_OPTS` build script variables.

#### java.net.SocketTimeoutException: Connect timed out

This happens when attempting to download the elevation data from cgiar. Sometimes CGAIR takes a long time to respond with elevation data.
We have set the timeout very high and added retries, but it's still possible to timeout here if CGAIR is struggling.
Unfortunately, this error will require the job to be restarted.