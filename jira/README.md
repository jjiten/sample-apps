# About

Contains the multi-resource-manifest to create a Jira server that uses a MySQL provider for configuration.

It uses the following image:

  https://hub.docker.com/r/cptactionhank/atlassian-jira/

See the Captain's repo here:

  https://github.com/cptactionhank/docker-atlassian-jira

The Apcera platform runs this unmodified Docker image with the help of the multi-resource manifest file jira-manifest.json and a helper bash script.
The manifest assembles the image with a route, environment variables, resources, an NFS partition for durability and a MySQL database for configuration
persistence.  The MySQL database can be setup with this example:

  https://github.com/apcera/sample-apps/tree/master/mysql-provider

# Deploying

To deploy the easy way, just run the deploy script:

```
./deploy.sh
```

Or get help from the command by passing the -h flag

```
./deploy.sh -h
```

# Cleaning Up

```
./cleanup.sh
```

That's it!  Easy as pie.
