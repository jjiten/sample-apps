#!/bin/bash
#
# This script will deploy the netperf manifest on the
# cluster and namespace for the specified time
#


print_usage()
{
    USAGE="deploy.sh <clustername> <namespace> <test-len-secs>"
    echo $USAGE
    exit 1
}

if [ -z "$1" ]; then
   echo "Please specify the cluster name."
   print_usage
else
   export CLUSTERNAME=$1
fi

if [ -z "$2" ]; then
   echo "Please specify the namespace."
   print_usage
else
   export NAMESPACE=$2
fi

if [ -z "$3" ]; then
    export TEST_LEN=10
else
    export TEST_LEN=$3
fi


apc target $CLUSTERNAME
RET=$?
if [ ${RET} -ne 0 ]; then
    print_usage
    exit 1
fi

apc namespace $NAMESPACE
RET=$?
if [ ${RET} -ne 0 ]; then
    print_usage
    exit 1
fi

apc manifest deploy netperf.json -- \
  --CLUSTERNAME $CLUSTERNAME --NAMESPACE $NAMESPACE --TEST_LEN ${TEST_LEN}
