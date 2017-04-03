# About

Contains the scripts and multi-resource manifest to deploy netperf & netserver in an Apcera cluster.


# Using Multi-Resource Manifest
With the multi-resource manifest you can establish a declarative file that can deploy the netserver and its netperf client (end to end and including the network) in a single command. Please see the file deploy.sh for details, also look at the cleanup.sh script that cleans up the work that the deploy script did.

To use the manifest and the helper script end to end you will need to issue first edit and import the policy then deploy the manifest, here is an example:

```
deploy.sh  demo.mycluster.mydomain.im /sandbox/joe
```
