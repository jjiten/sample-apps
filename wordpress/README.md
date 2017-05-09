# About

Contains the multi-resource-manifest to create a Wordpress blog server that uses an NFS provider for file durability and a MySQL provider for configuration.

# Deploying

To deploy the easy way, just run the deploy script:

```
./deploy.sh
```

Or pass four parameters like this:

```
./deploy.sh biscotti.buffalo.im /sandbox/juan /apcera/providers::apcfs-ha-aws /sandbox/juan::mysql
```

Where the first parameter (biscotti.buffalo.im) is the name of the Apcera cluster, the second one (/sandbox/juan) is the namespace,
the third (/apcera/providers::apcfs-ha-aws) is the NFS provider, and (/sandbox/juan::mysql) is the MySQL provider.

Either way the Apcera platform will process the manifest to tie everything up, creating services and binding to them, setting up the right environment
variables, retrieve the Docker image from the Dockerhub, create a route for it, that will be served by the platform and then deploy the image safely.
