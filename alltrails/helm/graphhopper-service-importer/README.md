# graphhopper-service-importer

graphhopper-service-importer is the job that imports osm data to be used by the graphhopper service. This is a one-off task the runs to completion and then stops. This is an unscheduled manual process that happens when we need to update the underlying data used by graphhopper to calculate routes.

# Table of Contents
1. [Running the Job](#running-the-job)
2. [Monitoring](#monitoring)
3. [Implementation Notes](#implementation-notes)

# Running the Job

## Toolchain

In order to run this job, you will need to be familiar with our [SRE toolchain](https://alltrails.atlassian.net/wiki/spaces/AE/pages/1647312980/Recommended+SRE+Toolchain). Specifically, we will use the AWS CLI, Kubectl and Helm.

## Process Overview

This is a long-running job that can take more than 30 hours to complete. It uses OSM data that is publicly available from AWS combined with AllTrails custom routing weights to generate the files graphhopper needs to calculate routes.

This job only needs to run in alpha. The output data is the same in all environments, so it can simply be copied to prod and other regions.

## Step by Step

There are several steps needed to complete an import:
1. [Copy the planet-latest.osm.pbf file from aws to ensure we are using the latest version](#copy-the-planet-latestosmpbf-file-from-aws)
2. [Copy the planet-latest.osm.pbf.csv file from DSAE](#ensure-we-have-the-latest-byot_custom_routing_weightscsv)
3. [Build and push the importer image](#build-and-push-the-importer-image)
4. [Start the job in k8s](#start-the-job-in-k8s)
5. [When the job is complete delete it from k8s](#delete-the-completed-job-in-k8s)
6. [Ensure the imported files look correct](#ensure-imported-files-look-correct)
7. [Rename the folders in s3](#rename-the-s3-folders)
8. [Update the data version](#update-data-version)
9. [Update the alpha deployment](#update-alpha-deployment)
10. [Spot check alpha to ensure the routing requests work as expected](#verify-alpha-deployment)
11. [Copy the imported data to prod and repeat steps 5-7](#update-prod-data)

## Copy the planet-latest.osm.pbf file from aws

Log in to aws and use the mostpaths profile:
```bash
aws sso login
export AWS_PROFILE=mostpaths
```

Switch your kube context to `eks-alpha` and your namespace to `alpha`:
```bash
kubectl config use-context arn:aws:eks:us-west-2:873326996015:cluster/eks-alpha
kubectl config set-context --current --namespace=alpha
```

Copy the file from aws to our own s3 bucket. This is a large file and it can take some time.
```bash
aws s3 cp s3://osm-pds/planet-latest.osm.pbf s3://alltrails-alpha-us-west-2-graphhopper-service
```

## Ensure we have the latest byot_custom_routing_weights.csv

The `byot_custom_routing_weights.csv` is put together by DSAE and contains the AllTrails custom routing weights.
It needs to be in the same directory as `planet-latest.osm.pbf`.
Ensure this file exists and that it is the latest version from DSAE. Their pipeline automatically updates this file and overwrites the old one.

Rename this file to `planet-latest.osm.pbf.csv`:
```bash
aws s3 mv s3://alltrails-production-us-west-2-graphhopper-service/byot_custom_routing_weights.csv s3://alltrails-production-us-west-2-graphhopper-service/planet-latest.osm.pbf.csv
```

## Build and Push the Importer Image

Login to docker:
```bash
docker login -u AWS -p $(aws ecr get-login-password --region us-west-2) 873326996015.dkr.ecr.us-west-2.amazonaws.com
```

Run the build script:
```bash
make import-build ENV=alpha
```

## Start the Job in K8s

```bash
make import-start ENV=alpha
```

You can inspect the job with:
```bash
kubectl get job graphhopper-service-importer
```

## Delete the completed job in k8s
When the status of the job reaches `Completed`, it is safe to delete from k8s. It needs to be deleted to start a new job, so it's good to do this as a cleanup step.
```bash
kubectl delete job graphhopper-service-importer
```

## Ensure Imported Files Look Correct

Inspect the current default files:
```bash
latest_data_version=$(head -n 1 ./dataversion)
aws s3 ls s3://alltrails-alpha-us-west-2-graphhopper-service/$latest_data_version --recursive
```

And compare these to the new files:
```bash
aws s3 ls s3://alltrails-alpha-us-west-2-graphhopper-service/import-data --recursive
```

Ask:
* Are all the expected files present? 
* Do the file sizes make sense for the given change set?

## Rename the s3 Folders

Rename the import-data. We mark it with a timestamp to keep older versions around until we are sure they are safe to delete.
```bash
timestamp=$(date +%s)
aws s3 --recursive mv s3://alltrails-alpha-us-west-2-graphhopper-service/import-data s3://alltrails-alpha-us-west-2-graphhopper-service/default-gh-$timestamp
```

## Update Data Version

Update the dataversion file with the new directory
```bash
echo "default-gh-$timestamp" > ./dataversion
```

Create a pull request for this change and merge to master.
This is necessary because the new image will be tagged with the git hash.

On the updated master branch, build and push a new image to read from the new directory
```bash
make docker-build ENV=alpha
make docker-push ENV=alpha
```

## Update Alpha Deployment

Restart the alpha deployment. The new pods will use the new data in the `default-gh-$timestamp` directory.
```bash
make deploy ENV=alpha
```

## Verify Alpha Deployment

The easiest way to spot check the deployment is by making some requests in the [web-app](https://alpha.mostpaths.com/api/alltrails/graphhopper-service/maps/?profile=hike&layer=OpenStreetMap). Try a few requests for each profile.

## Update Prod Data

Update aws-cli and kube to use the production account:
```bash
export AWS_PROFILE=root
kubectl config use-context arn:aws:eks:us-west-2:434355312983:cluster/alltrails-production
kubectl config set-context --current --namespace=production
```

Docker Login:
```bash
docker login -u AWS -p $(aws ecr get-login-password --region us-west-2) 434355312983.dkr.ecr.us-west-2.amazonaws.com
```

Copy the imported data into production directory:
```bash
aws s3 --recursive cp s3://alltrails-alpha-us-west-2-graphhopper-service/default-gh-$timestamp s3://alltrails-production-us-west-2-graphhopper-service/default-gh-$timestamp
```

Build, push and deploy new image to production:
```bash
make docker-build ENV=prod
make docker-push ENV=prod
make deploy ENV=prod
```

Repeat these steps for all regions:
```bash
make docker-push ENV=prod_ap
make deploy ENV=prod_ap

make docker-push ENV=prod_eu
make deploy ENV=prod_eu
```

Spot check the deployment in the [production web-app](https://www.alltrails.com/api/alltrails/graphhopper-service/maps/?profile=hike&layer=OpenStreetMap).
# Monitoring

If the import fails it will notify in the #alerts-graphhopper slack channel.

## Links
* [Pods Overview Dashboard](https://app.datadoghq.com/dash/integration/Kubernetes%20-%20Pods?fromUser=false&refresh_mode=sliding&tpl_var_cluster%5B0%5D=eks-alpha&tpl_var_job%5B0%5D=graphhopper-service-importer&live=true)
* [Importer Pod Logs](https://app.datadoghq.com/logs?query=service%3Agraphhopper-service-importer&agg_m=count&agg_m_source=base&agg_t=count&cols=host%2Cservice&fromUser=true&messageDisplay=inline&refresh_mode=sliding&storage=hot&stream_sort=desc&viz=stream&live=true)

## Things to Watch For

`java.net.SocketTimeoutException: Connect timed out` When attempting to download the elevation data from cgiar.

Sometimes CGAIR takes a long time to respond with elevation data.
We have set the timeout very high and added retries, but it's still possible to timeout here if CGAIR is struggling.
Unfortunately, this error will require the job to be restarted.

___

`Failed to schedule pod, incompatible with nodepool "default"`

You might see this error when running `kubectl describe pod <POD_NAME>`. This job is asking for a ton of memory. The nodepool needs to be configured to allow large instances.

# Implementation Notes

## s3 Data storage

This job (and the graphhopper-service) use a [k8s persistent volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) with the [s3 csi driver](https://github.com/awslabs/mountpoint-s3-csi-driver) to mount the s3 bucket as file system. 
This allows us to share the data between pods. It also allows us to interact with s3 via file operations instead of an s3 specific library. 
However, there are some downsides here. Since s3 is an object store rather than a true file system, some of the standard file operations used by the java libraries do not work.
So, instead of writing the output files directly to s3, we are writing to local storage and then copying the files to s3 when the import is complete.
