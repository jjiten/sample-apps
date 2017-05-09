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
    USAGE="deploy.sh [options]"
    echo $USAGE
    echo "Where:"
    echo " -c <clustername>    is the domain name of your cluster"
    echo " -n <namespace>      is where the services and jobs will be created"
    echo " -v <nfs-provider>   is the name of the nfs provider (/apcera/providers) to create the volume"
    echo " -p <mysql-provider> is the FQN of the mysql provider that will hold the Wordpress config"
    echo " -t <wp-version-tag> is the version tag of the wordpress Docker image"

    exit 1
}

while getopts "hc:n:v:p:t:" opt; do
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
          WORDPRESS_VERSION=$OPTARG
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

# If not passed in, used the first MySQL provider we can find
if [ -z "${MYSQL_PROVIDER}" ]; then
    MYSQL_PROVIDER=`apc provider list -l | grep mysql | head -1 | awk '{ print $2 }'`
fi

if [ -z "${WP_VERSION}" ]; then
    WP_VERSION=latest
fi

# cleanup parameters to avoid superflous prefix
CLUSTERNAME=`echo $CLUSTERNAME | sed -e's/https:\/\///'`
CLUSTERNAME=`echo $CLUSTERNAME | sed -e's/http:\/\///'`
NFS_PROVIDER=`echo $NFS_PROVIDER | sed -e 's/^provider:://'`
MYSQL_PROVIDER=`echo $MYSQL_PROVIDER | sed -e 's/^provider:://'`

echo "Creating Wordpress with:"
echo " CLUSTERNAME    ${CLUSTERNAME}"
echo " NAMESPACE      ${NAMESPACE}"
echo " NFS_PROVIDER   ${NFS_PROVIDER}"
echo " MYSQL_PROVIDER ${MYSQL_PROVIDER}"
echo " WP_VERSION     ${WP_VERSION}"

read -p "Press RETURN to Continue" YES

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

apc manifest deploy wordpress-manifest.json -- \
    --CLUSTERNAME $CLUSTERNAME --NAMESPACE $NAMESPACE  \
    --NFS_PROVIDER $NFS_PROVIDER  --MYSQL_PROVIDER $MYSQL_PROVIDER \
    --TAG $WP_VERSION
