#!/bin/bash
#
# This script will create a MySQL provider using a docker image and a
# APCFS (NFS) provider.
#
# The script assumes that your cluster has an APCFS provider
# already configured on your cluster.
#
# If you do not pass any parameters the script makes a best effort at guessing the
# right values. It will use the first apcfs provider it finds, and will use the current
# namespace and cluster as defaults.
#

print_usage()
{
    USAGE="deploy.sh [options]"
    echo $USAGE
    echo "Where:"
    echo " -c <clustername>    is the domain name of your cluster"
    echo " -n <namespace>      is where the MySQL job and provider will be created"
    echo " -v <nfs-provider>   is the FQN of the nfs provider used for the volume"
    echo " -p <mysql-provider> is the FQN of the mysql provider"
    echo " -t <mysql-version>  for version tag options please see: https://hub.docker.com/_/mysql"
    echo " -j <job-name>       is the name of the job to create for the provider mysql server"
    echo " -h                  will print this help message"
    echo ""

    exit 1
}

while getopts "hc:n:v:p:j:t:" opt; do
  case $opt in
      h)
          print_usage >&2
          ;;
      c)
          CLUSTERNAME=$OPTARG
          ;;
      n)
          NAMESPACE=$OPTARG
          ;;
      v)
          NFS_PROVIDER=$OPTARG
          ;;
      p)
          MYSQL_PROVIDER=$OPTARG
          ;;
      t)
          MYSQL_VERSION=$OPTARG
          ;;
      j)
          MYSQL_JOB_NAME=$OPTARG
          ;;
      \?)
          echo "Invalid option: -$OPTARG" >&2
          print_usage >&2
          exit 1
          ;;
      :)
          echo "Option -$OPTARG requires an argument." >&2
          print_usage >&2
          exit 1
          ;;
  esac
done


if [ -z "${CLUSTERNAME}" ]; then
  CLUSTERNAME=`apc target | sed -e 's/\[/\]/' | awk -F\] '/Targeted/{ print $2}'`
fi

if [ -z "${NAMESPACE}" ]; then
   NAMESPACE=`apc namespace | awk -F\' '{ print $2 }'`
fi

if [ -z "${NFS_PROVIDER}" ]; then
    NFS_PROVIDER=`apc provider list -ns /apcera/providers -l | grep apcfs | head -1 | awk '{ print $2 }'`
else
    NFS_PROVIDER="/apcera/providers::${NFS_PROVIDER}"
fi

if [ -z "${MYSQL_PROVIDER}" ]; then
    MYSQL_PROVIDER=${NAMESPACE}::mysql
fi

if [ -z "${MYSQL_VERSION}" ]; then
    MYSQL_VERSION=5.6.36
fi

if [ -z "${MYSQL_JOB_NAME}" ]; then
    MYSQL_JOB_NAME=mysql-server
fi

# cleanup parameters to avoid superflous prefixes
export CLUSTERNAME=`echo $CLUSTERNAME | sed -e's/https:\/\///'`
export CLUSTERNAME=`echo $CLUSTERNAME | sed -e's/http:\/\///'`
export NFS_PROVIDER=`echo $NFS_PROVIDER | sed -e 's/^provider:://'`

echo -e "Creating MySQL Provider '${MYSQL_PROVIDER}'\n" \
    " Cluster      : ${CLUSTERNAME}\n" \
    " Namespace    : ${NAMESPACE}\n" \
    " NFS Provider : ${NFS_PROVIDER}\n" \
    " Job Name     : ${MYSQL_JOB_NAME}\n" \
    " MySQL Version: ${MYSQL_VERSION}"

# Prompt for the MySQL password
read -s -p "Enter the MySQL ROOT password: " PASSWORD

# Create MySQL job with NFS persistent storage
apc docker run --image mysql --tag ${MYSQL_VERSION} --port 3306 --memory 640MB \
    --restart always --volume /var/data/mysql --provider ${NFS_PROVIDER} \
    -e MYSQL_ROOT_PASSWORD=${PASSWORD}  "${NAMESPACE}::${MYSQL_JOB_NAME}"
RET=$?
if [ ${RET} -ne 0 ] ;then
    echo "ERROR: Creating the provider job '${MYSQL_JOB_NAME}': $RET"
    exit 1
fi

# MySQL reports process running before it is ready to accept connections, so we add delay and retry
sleep 10

# Register the provider
COUNT=0
until [ ${COUNT} -eq 5 ] || apc provider register --batch "${MYSQL_PROVIDER}"  --type mysql --job "${NAMESPACE}::${MYSQL_JOB_NAME}" --port 3306 -u "mysql://root:${PASSWORD}@mysql-provider"
do
    COUNT=$(($COUNT+1))
    echo "MySQL is not ready, retrying ${COUNT} ... "
    sleep 10
done

if [ ${COUNT} -ge 5 ]; then
    echo "ERROR: Registering the provider '${MYSQL_PROVIDER}' " \
        "with job '${NAMESPACE}::${MYSQL_JOB_NAME}'"
    exit 1
fi
