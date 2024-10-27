#!/bin/bash

usage () {
    echo "Usage:"
    echo "./setup_hive.sh \\"
    echo "  --namenode <namenode_ip>"
    echo "  --hive-password <hive_postgres_password>"
}

VALID_ARGS=$(getopt -o '' --long help,namenode:,hive-password: -- "$@")
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
    --namenode)
        NAMENODE_HOST="$2"
        shift 2
        ;;
    --hive-password)
        HIVE_POSTGRES_PASSWORD="$2"
        shift 2
        ;;
    --) shift;
        break
        ;;
  esac
done

if [[ -z $NAMENODE_HOST ]]; then
    echo "No namenode host provided!"
    usage
    exit 1
fi
if [[ -z $HIVE_POSTGRES_PASSWORD ]]; then
    echo "No hive postgres password provided!"
    usage
    exit 1
fi

sudo -i -u hadoop bash << OUTEREOF
cd
if [[ ! -f "apache-hive-4.0.1-bin.tar.gz" ]]; then
    echo "Downloading Apache Hive"
    wget -q "https://dlcdn.apache.org/hive/hive-4.0.1/apache-hive-4.0.1-bin.tar.gz"
    tar -xzf "apache-hive-4.0.1-bin.tar.gz"
    cd apache-hive-4.0.1-bin/lib
    echo "Downloading postgres JDBC driver"
    wget -q https://jdbc.postgresql.org/download/postgresql-42.7.4.jar
    cd
fi

cd
echo "Configuring Apache Hive"
cat > apache-hive-4.0.1-bin/conf/hive-site.xml<< EOF
<configuration>
    <property>
        <name>hive.server2.authentication</name>
        <value>NONE</value>
    </property>
    <property>
        <name>hive.metastore.warehouse.dir</name>
        <value>/user/hive/warehouse</value>
    </property>
    <property>
        <name>hive.server2.thrift.port</name>
        <value>5433</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:postgresql://${NAMENODE_HOST}:5432/metastore</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>org.postgresql.Driver</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>hive</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>${HIVE_POSTGRES_PASSWORD}</value>
    </property>
</configuration>
EOF

echo 'export HIVE_HOME=/home/hadoop/apache-hive-4.0.1-bin' >> ~/.profile
echo 'export HIVE_CONF_DIR=/home/hadoop/apache-hive-4.0.1-bin/conf' >> ~/.profile
echo 'export HIVE_AUX_JARS_PATH=/home/hadoop/apache-hive-4.0.1-bin/lib/*' >> ~/.profile
echo 'export PATH=\$PATH:\$HIVE_HOME/bin' >> ~/.profile
source ~/.profile

hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -chmod g+w /tmp
hdfs dfs -chmod g+w /user/hive/warehouse

cd apache-hive-4.0.1-bin
bin/schematool -dbType postgres -initSchema
OUTEREOF

echo "Done!"
