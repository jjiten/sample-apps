#!/bin/bash

print_usage()
{
    USAGE="deploy.sh [options]"
    echo $USAGE
    echo "Where:"
    echo " -c <clustername>    is the domain name of your cluster"
    echo " -n <namespace>      is where the MySQL job and provider will be created"
    echo " -p <mysql-provider> is the FQN of the mysql provider"
    echo " -j <job-name>       is the name of the job to create for the provider mysql server"
    echo " -h                  will print this help message"
    echo ""

    exit 1
}

while getopts "hc:n:p:j:" opt; do
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
      p)
          MYSQL_PROVIDER=$OPTARG
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

if [ -z "${MYSQL_PROVIDER}" ]; then
    MYSQL_PROVIDER=${NAMESPACE}::mysql
fi

if [ -z "${MYSQL_JOB_NAME}" ]; then
    MYSQL_JOB_NAME=mysql-server
fi

# cleanup parameters to avoid superflous prefix
export CLUSTERNAME=`echo $CLUSTERNAME | sed -e's/https:\/\///'`
export CLUSTERNAME=`echo $CLUSTERNAME | sed -e's/http:\/\///'`
export NFS_PROVIDER=`echo $NFS_PROVIDER | sed -e 's/^provider:://'`

echo -e "Deleting MySQL Provider '${MYSQL_PROVIDER}'\n" \
    " Cluster      : ${CLUSTERNAME}\n" \
    " Namespace    : ${NAMESPACE}\n" \
    " Job Name     : ${MYSQL_JOB_NAME}"

# remove the provider
apc provider delete ${MYSQL_PROVIDER}
RET=$?
if [ ${RET} -ne 0 ]; then
    echo "ERROR: Deleting the provider job '${MYSQL_JOB_NAME}': $RET"
fi

# Get the list of services attached to the mysql-server job
SERVICES=""
for i in `apc job show mysql-server | grep 'service::' | sed -e 's/  / /g' | awk -F' ' '{ print $5 }'` ; do
    SERVICES="${SERVICES} $i"
done

# remove the server
apc job delete mysql-server
RET=$?
if [ ${RET} -ne 0 ]; then
    echo "ERROR: Deleting the provider job" \
        "'${NAMESPACE}::${MYSQL_JOB_NAME}': $RET"
    exit 1
fi

# Remove the services created by the docker run with the --volume option
for i in ${SERVICES} ; do
    apc service delete $i
done
