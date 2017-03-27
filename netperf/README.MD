# About

Contains the scripts and multi-resource manifest to deploy netperf & netserver in an Apcera cluster.


# Using Multi-Resource Manifest
With the multi-resource manifest you can establish a single descriptive declarative file that can deploy the Jenkins and its Jenkins-slave, including apcera services, the network, routes, and in a single command deploys the application end-to-end. The file, jenkins-manifest.json includes variables so it is portable. Please see the file deploy.sh for details, also look at the cleanup.sh script that cleans up the work that the deploy script did.

To use the manifest and the helper script end to end you will need to issue first edit and import the policy then deploy the manifest, here is an example:

```
deploy.sh  demo.mycluster.mydomain.im /sandbox/joe
```
