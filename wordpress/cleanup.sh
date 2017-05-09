#!/bin/bash
#
# This script cleans up the objects created by the deploy of wordpress-manifest.json
#

print_usage()
{
    USAGE="cleanup.sh [options]"
    echo $USAGE
    echo "Where:"
    echo " -c <clustername>    is the domain name of your cluster"
    echo " -n <namespace>      is where the services and jobs will be created"

    exit 1
}


while getopts "hc:n:" opt; do
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
fi

if [ -z "${NAMESPACE}" ]; then
   export NAMESPACE=`apc namespace | awk -F\' '{ print $2 }'`
fi

echo "Deleting jobs ..."
apc job delete --batch wordpress

echo "Deleting services ..."
apc service delete --batch wordpress-www-html
apc service delete --batch wordpress-mysql

echo "Done"
