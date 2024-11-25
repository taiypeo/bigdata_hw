#!/bin/bash

#!/bin/bash

usage () {
    echo "Usage:"
    echo "./setup_spark.sh \\"
    echo "  --namenode-host <host_address>"
}

VALID_ARGS=$(getopt -o '' --long help,namenode-host: -- "$@")
if [[ $? -ne 0 ]] && usage; then
    exit 1
fi

eval set -- "$VALID_ARGS"
while true; do
  case "$1" in
    --help)
        usage
        exit 0
        ;;
    --namenode-host)
        HOST_ADDRESS="$2"
        shift 2
        ;;
    --) shift;
        break
        ;;
  esac
done

if [[ -z $HOST_ADDRESS ]]; then
    echo "No namenode host provided!"
    usage
    exit 1
fi

ssh -x -a "hadoop@$HOST_ADDRESS" /bin/bash << OUTEREOF
if [[ ! -f "spark-3.5.3-bin-hadoop3.tgz" ]]; then
    echo "Downloading Spark"
    wget -q "https://dlcdn.apache.org/spark/spark-3.5.3/spark-3.5.3-bin-hadoop3.tgz"
    tar -xzf "spark-3.5.3-bin-hadoop3.tgz"
fi

echo 'export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop' >> ~/.profile
echo 'export SPARK_HOME=/home/hadoop/spark-3.5.3-bin-hadoop3' >> .profile
echo 'export PATH=\$PATH:\$SPARK_HOME/bin' >> .profile
echo 'export SPARK_DIST_CLASSPATH=\$SPARK_HOME/jars/*:\$(hadoop classpath)' >> .profile
OUTEREOF
