# About

This repository contains the Dockerfile and startup scripts to run a Jenkins cluster on Apcera. You can build the image from the Dockerfile or use the pre-built image on Docker Hub (<https://hub.docker.com/r/apcerademos/jenkins/>). The Docker image also contains the APC command-line utility so you can easily run commands against your Apcera cluster from within Jenkins.

Feel free to test this out on the Apcera Platform Community or Enterprise Edition (<https://www.apcera.com/community-edition>).

# Build the Docker image

Use the following commands to build the Jenkins image from the provided Dockerfile and push the image to your own repository. Be sure to replace `my-repo` with your Docker Hub username.

```
cd jenkins
docker build -t my-repo/jenkins .
docker push my-repo/jenkins
```

Alternatively, you can use the pre-built Jenkins Docker image available on Docker Hub (`apcerademos/jenkins`) to complete the installation.

# Setup policy for the application token

[Application tokens](https://docs.apcera.com/jobs/app-token/) allow the APC client installed in the Jenkins jobs to authenticate securely with the Apcera platform. You need to modify `jenkins.pol` to reflect the correct namespace where the Jenkins jobs will run. Specifically, you must change each occurrence of `/sandbox/demo` to the namespace where the Jenkins jobs will run (`/sandbox/your-name`, for example).

The policy file in this Git repository allows the Jenkins jobs to get assigned an App Token, and provides them with permissions to create jobs, service, networks, and so forth.

```
apc policy import jenkins.pol
```

For more information on policy, please visit <http://docs.apcera.com/jobs/app-token>.

Now that necessary policy is in place you can deploy using multi-resource manifests or by making individual APC calls.

# Deploy using a Multi-Resource Manifest

The easiest way to deploy Jenkins from the Docker image is with the provided [multi-resource manifest](http://docs.apcera.com/jobs/multi-resource-manifests) file (`jenkins-manifest.json`). The multi-resource manifest declaratively defines both Jenkins jobs (master and slave), creates the required services, networking, and application routes. You can then deploy, configure, and start the Jenkins instance in a single command.

The manifest file, `jenkins-manifest.json`, uses [substitution variables](https://docs.apcera.com/jobs/multi-resource-manifests/#using-substitution-variables) so it can be easily ported to different environments. Please see `deploy.sh` for details, which executes the following command at the end to deploy the manifest:

```
apc manifest deploy jenkins-manifest.json -- \
	--CLUSTERNAME $CLUSTERNAME --NAMESPACE $NAMESPACE --NFS_PROVIDER $NFS_PROVIDER
```

* `CLUSTERNAME` -- Base name of your cluster ("my-cluster.example.com", for example).
* `NAMESPACE` -- The namespace to deploy the job. This namespace must match the one specified in the policy document that you imported (see previous section).
* `NFS_PROVIDER` -- The name of the NFS provider used to create the persistence layer. This is either `apcfs` (for Community Edition installations) or `apcfs-ha` (for Enterprise Edition installations).

For example, the following uses the helper script to deploy the manifest to the `/sandbox/yourname` namespace on the specified cluster:

```
deploy.sh your-cluster.example.com /sandbox/yourname apcfs-ha
```

For more information on multi-resource manifests see: <http://docs.apcera.com/jobs/multi-resource-manifests/>

# Running the Docker image using the APC CLI

Instead of using a multi-resource manifest to deploy Jenkins and create the necessary networks and service bindings, you can use APC to perform these steps manually. You can use APC to create a Jenkins master job from your Docker registry (or the public image). The `-r` flag assigns a public route for you to access Jenkins. The environment variable "TARGET" should reflect the address of the Apcera cluster. The provider flag sets up persistent storage for the Jenkins directory: /root/.jenkins.

```
apc docker run jenkins-master -i apcerademos/jenkins \
-m 2G -d 5G --port 8080 -ae -r http://jenkins.my-cluster.example.com \
-e TARGET="http://my-cluster.example.com" --provider /apcera/providers::apcfs \
--batch --no-start
```

Use APC to create the Jenkins slave job from the Docker image. Here we need to change the startup command with the `-s` flag because the slave nodes require a different application to connect to the Jenkins master.

```
apc docker run jenkins-slave -i apcerademos/jenkins \
-m 2G -d 5G --port 8080 -ae -s "bash /slave.sh" \
-e TARGET="my-cluster.example.com" \
--provider /apcera/providers::apcfs --batch --no-start
```

## Configure the networking

Create a virtual network for Jenkins and assign the Jenkins jobs to it. The -da argument assigns a static discovery address set to master. Please do not change this.
```
apc network create jenkins --batch
apc network join jenkins -j jenkins-master -da master --batch
apc network join jenkins -j jenkins-slave  --batch
```

## Bind the HTTP service gateway to both jobs

For App Tokens to work you must bind each app to the `/apcera::http` service:

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

# Jenkins CLI

To use the Jenkins CLI with the Apcera platform, the easiest mechanism is to connect to the container running jenkins then execute it inside the container. For example, to list the plugins installed in Jenkins, do the following:

```
apc job connect jenkins-master
root@ip-169-254-0-1:/root# java -jar /root/.jenkins/war/WEB-INF/jenkins-cli.jar -s http://127.0.0.1:8080/ list-plugins
... etc ...
```
