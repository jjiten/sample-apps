# About

Contains the Dockerfile and startup scripts to run a Jenkins cluster on Apcera. This project contains instructions about how to use the docker image in the apcerademos
repository for the docker hub.  It describes how to deploy the image and set it up in your environment using two different methods.  It also describes how to create
your own dockerfile that will work on the apcera platform.

Feel free to test this out on the Apcera Platform Community or Enterprise Edition https://www.apcera.com/community-edition

# Using Multi-Resource Manifest
With the multi-resource manifest you can establish a single descriptive declarative file that can deploy the Jenkins and its Jenkins-slave, including apcera services, the network, routes, and in a single command deploys the application end-to-end. The file, jenkins-manifest.json includes variables so it is portable. Please see the file deploy.sh for details, also look at the cleanup.sh script that cleans up the work that the deploy script did.

To use the manifest and the helper script end to end you will need to issue first edit and import the policy then deploy the manifest, here is an example:

```
apc policy import jenkins.pol
deploy.sh bagel.buffalo.im /sandbox/juan apcfs-ha
```
For more information on multi-resource manifests see: http://docs.apcera.com/jobs/multi-resource-manifests/


# Running the Docker image using the APC CLI
## Run the Docker image on Apcera
Use APC to create a Jenkins master job from your Docker registry. The -r flag assigns a public route for you to access Jenkins. The envrionment variable "target" should reflect the address of the Apcera cluster. The provider flag sets up persistent storage for the Jenkins directory: /root/.jenkins.
```
apc docker run jenkins-master -i my-repo/jenkins -m 2G -d 5G --port 8080 -ae -r http://master-jenkins.demo.apcera.net -e target="http://demo.apcera.net" --provider  /apcera/providers::apcfs --batch --no-start
```

Use APC to create the Jenkins slave job from your Docker registry. Here we need to change the startup command with the -s flag because the slave nodes require a different application to connect to the Jenkins master.
```
apc docker run jenkins-slave -i my-repo/jenkins -m 2G -d 5G --port 8080 -ae -s "bash /slave.sh" -e target="http://demo.apcera.net" --provider /apcera/providers::apcfs --batch --no-start
```

## Configure the networking
Create a virtual network for Jenkins and assign the Jenkins jobs to it. The -da argument assigns a static discovery address set to master. Please do not change this.
```
apc network create jenkins --batch
apc network join jenkins -j jenkins-master -da master --batch
apc network join jenkins -j jenkins-slave  --batch
```

## Setup policy for the application token
Application tokens allow the APC client installed in the Jenkins jobs to authenticate securely with the Apcera platform. Modify jenkins.pol to reflect the correct namespace where the Jenkins jobs run. This policy file in this Git repository allows the Jenkins jobs to get assigned an App Token and policy. For more information on policy, please visit http://docs.apcera.com/jobs/app-token
```
apc policy import jenkins.pol
```

Bind the HTTP service gateway for App Tokens to work
```
apc service bind /apcera::http --job jenkins-master --batch
apc service bind /apcera::http --job jenkins-slave --batch
```

## Start all of the Jenkins jobs
```
apc app start jenkins-master
apc app start jenkins-slave
```

## If desired, you can easily scale up the Jenkins slaves
```
apc app update jenkins-slave -i 3 --batch
```

# Building the Docker image

If you do not want to use Apcera's Jenkins docker image, you can build your own and adjust the manifest to reflect this.  Please follow the steps below to create a new jenkins docker image.

Adjust line 4 of the Dockerfile to point to your own Apcera Cluster so the appropriate APC version will be installed. When done, you can build the Docker image and push it to a public registry.  Then execute the following commands:
```
cd jenkins
docker build -t my-repo/jenkins .
docker push my-repo/jenkins
```
You can then modify the _image_ portion of the resource manifest, or change the _-i_ argument to the docker run command.

# Jenkins CLI

To use the Jenkins CLI with the Apcera platform, the easiest mechanism is to connect to the container running jenkins then execute it inside the container.
So, for example to list the plugins installed in the jenkins plugin, do the following:

```
apc job connect jenkins-master
root@ip-169-254-0-1:/root# java -jar /root/.jenkins/war/WEB-INF/jenkins-cli.jar -s http://127.0.0.1:8080/ list-plugins
... etc ...
```
