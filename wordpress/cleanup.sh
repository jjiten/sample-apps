#!/bin/bash
#
# This script cleans up the objects created by the deploy of wordpress-manifest.json
#

echo "Deleting jobs ..."
apc job delete --batch wordpress

echo "Deleting services ..."
apc service delete --batch wordpress-www-html
apc service delete --batch wordpress-mysql

echo "Done"
