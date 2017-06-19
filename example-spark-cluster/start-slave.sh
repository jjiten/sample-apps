export SPARK_WORKER_DIR=/app/work
export SPARK_LOG_DIR=/app/logs
export VIRTUAL_NETWORK_IP=`ifconfig | grep "inet addr" | cut -d: -f2 | grep -v "169." | grep -v "127.0.0.1" | cut -d ' ' -f1`
$SPARK_HOME/sbin/start-slave.sh -h $VIRTUAL_NETWORK_IP $SPARK_MASTER
tail -f /app/logs/*