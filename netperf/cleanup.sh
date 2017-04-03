#!/bin/bash
#
# This scripts cleans up the objects created by the deploy of jenkins-manifest.json
#

echo "Deleting jobs ..."
apc job delete --batch netserver
apc job delete --batch netperf

echo "Deleting network ..."
apc network delete netperf-network

echo "Done"
