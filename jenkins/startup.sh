#!/bin/bash
#
# This script is used to start jenkins inside an Apcera Cluster
#
PLUGIN_LIST="swarm github workflow-aggregator workflow-job workflow-basic-steps"
JENKINS_HOST=http://127.0.0.1:8080
JENKINS_HOME=/var/jenkins_home
cd $JENKINS_HOME

# TARGET must be set when deployed to an Apcera cluster.
if [ -z "$TARGET" ]; then
    echo "$0:Please set the TARGET environment variable"
    exit 1
else
    echo "$0: TARGET CLUSTER is ${TARGET}";echo
fi

#Start Jenkins
echo "$0: Jenkins starting .. ";echo
java $JAVA_OPTS -jar /usr/share/jenkins/jenkins.war&

# Give the jenkins some time to start up
sleep 15

echo "$0: Jenkins check on installed plugins .. ";echo
COUNT=40
until java -jar ${JENKINS_HOME}/war/WEB-INF/jenkins-cli.jar -s ${JENKINS_HOST} list-plugins > INSTALLED_PLUGINS 2>/dev/null
do
    echo "$0: Jenkins is not ready .. ";echo
    sleep 3
    COUNT=$((COUNT-1))
    if [ ${COUNT} -eq "0" ]; then
        echo "$0: Exiting, will retry ... ";echo
        exit 1
    fi
done

RESTART=''
for p in $PLUGIN_LIST
do
    if grep $p INSTALLED_PLUGINS ; then
        echo "$0: Found plugin $p installed .. "; echo
    else
        echo "$0: Installing plugin $p"; echo
        java -jar ${JENKINS_HOME}/war/WEB-INF/jenkins-cli.jar -s ${JENKINS_HOST} install-plugin ${p}
        RESTART=true
    fi
done

if [ "${RESTART}" == "true" ]; then
    echo "$0: Restarting Jenkins to activate plugins ...";echo
    java -jar ${JENKINS_HOME}/war/WEB-INF/jenkins-cli.jar -s ${JENKINS_HOST} restart
    echo "$0: Jenkins re-starting .. ";echo
    COUNT=30
    until kill -0 `pidof java` 2> /dev/null ; do
        echo "$0: Jenkins is not up yet .. ";echo
        sleep 3
        COUNT=$((COUNT-1))
        if [ ${COUNT} -eq "0" ]; then
            echo "$0: Exiting, will retry ... ";echo
            exit 1
        fi
    done
fi

echo "$0: Sleeping forever ...";echo
while kill -0 `pidof java` 2> /dev/null ; do
  sleep 1
done
echo "$0: Exiting ...";echo
exit 1
