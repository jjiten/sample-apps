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

MYSQL_VERSION=5.6.36

print_usage()
{
    USAGE="deploy.sh -c <clustername> -s <namespace> -n <nfs-provider> -m <mysql-provider>"
    echo $USAGE
    echo "Where:"
    echo " -c clustername is the domain name of your cluster."
    echo " -s namespace where the MySQL job will be run and the provider will be created."
    echo " -n nfs-provider is the FQN of the nfs provider."
    echo " -m mysql-provider is the FQN of the mysql provider."
    echo " -h will print this help message."
    echo ""

    exit 1
}

while getopts "h:c:s:n:m" opt; do
  case $opt in
      h)
          print_usage >&2
          ;;
      c)
          CLUSTERNAME=$OPTARG
          ;;
      s)
          NAMESPACE=$OPTARG
          ;;
      n)
          NFS_PROVIDER=$OPTARG
          ;;
      m)
          MYSQL_PROVIDER=$OPTARG
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
    export MYSQL_PROVIDER=${NAMESPACE}::mysql
else
    export MYSQL_PROVIDER=$4
fi

# Prompt for the MySQL password
read -s -p "Enter the MySQL ROOT password: " PASSWORD

# Create MySQL job with NFS persistent storage
apc docker run --image mysql --tag ${MYSQL_VERSION} --port 3306 --memory 640MB --restart always --volume /var/data/mysql --provider 'provider::/apcera/providers::apcfs-ha-aws' -e MYSQL_ROOT_PASSWORD=${PASSWORD}  mysql-server

RET=$?
if [ "$RET" ]; then
    echo "ERROR: Creating the provider job"
    exit 1
fi

# Register the provider
apc provider register ${NAMESPACE}::mysql  --type mysql --job ${NAMESPACE}::mysql-server --port 3306 -u mysql://root:mysqlpw@mysql-provider
RET=$?
if [ "$RET" ]; then
    echo "ERROR: Registering the provider job"
    exit 1
fi
