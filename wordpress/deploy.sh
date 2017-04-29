#!/bin/bash
#
# This script will deploy the wordpress manifest on a specified
# cluster and namespace
#
# The script assumes that your cluster has an NFS provider and MySQL provider
# already configured on your cluster.
#


print_usage()
{
    USAGE="deploy.sh <clustername> <namespace> <nfs-provider> <mysql-provider>"
    echo $USAGE
    echo "Where:"
    echo " clustername is the domain name of your cluster"
    echo " namespace is where the services and jobs will be created"
    echo " nfs-provider is the name of the nfs provider that will hold the Wordpress data"
    echo " mysql-provider is the name of the mysql provider that will hold the Wordpress config"
    exit 1
}

if [ "$1" -eq "-h" ]; then
    print_usage
    exit 1
fi

if [ -z "$1" ]; then
  export CLUSTERNAME=`apc target | sed -e 's/\[/\]/' | awk -F\] '/Targeted/{ print $2}'`
else
  export CLUSTERNAME=$1
fi

if [ -z "$2" ]; then
   export NAMESPACE=`apc namespace | awk -F\' '{ print $2 }'`
else
   export NAMESPACE=$2
fi

if [ -z "$3" ]; then
    export NFS_PROVIDER=`apc provider list -ns /apcera/providers -l | grep apcfs | head -1 | awk '{ print $2 }'`
else
    export NFS_PROVIDER=$3
fi

if [ -z "$4" ]; then
    export MYSQL_PROVIDER=`apc provider list -l | grep mysql | head -1 | awk '{ print $2 }'`
else
    export MYSQL_PROVIDER=$4
fi

echo "Creating Wordpress with:"
echo " CLUSTERNAME=${CLUSTERNAME}"
echo " NAMESPACE=${NAMESPACE}"
echo " NFS_PROVIDER=${NFS_PROVIDER}"
echo " MYSQL_PROVIDER=${MYSQL_PROVIDER}"

apc target $CLUSTERNAME
RET=$?
if [ ${RET} -ne 0 ]; then
    echo "ERROR: failed to target ${CLUSTERNAME}"
    print_usage
    exit 1
fi

apc namespace $NAMESPACE
RET=$?
if [ ${RET} -ne 0 ]; then
    echo "ERROR: failed to set ${NAMESPACE}"
    print_usage
    exit 1
fi

# cleanup parameters to avoid superflous prefix
export CLUSTERNAME=`echo $CLUSTERNAME | sed -e's/https:\/\///'`
export CLUSTERNAME=`echo $CLUSTERNAME | sed -e's/http:\/\///'`
export NFS_PROVIDER=`echo $NFS_PROVIDER | sed -e 's/^provider:://'`
export MYSQL_PROVIDER=`echo $MYSQL_PROVIDER | sed -e 's/^provider:://'`

apc manifest deploy wordpress-manifest.json -- \
  --CLUSTERNAME $CLUSTERNAME --NAMESPACE $NAMESPACE --NFS_PROVIDER $NFS_PROVIDER  --MYSQL_PROVIDER $MYSQL_PROVIDER
