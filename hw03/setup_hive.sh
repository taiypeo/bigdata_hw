#!/bin/bash

usage () {
    echo "Usage:"
    echo "./setup_hive.sh \\"
    echo "  --namenode <namenode_ip>"
    echo "  --hadoop-password <hadoop_user_password>"
    echo "  --hive-password <hive_postgres_password>"
}

VALID_ARGS=$(getopt -o '' --long help,namenode:,hadoop-password:,hive-password: -- "$@")
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
    --hadoop-password)
        HADOOP_PASSWORD="$2"
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
if [[ -z $HADOOP_PASSWORD ]]; then
    echo "No hadoop user password provided!"
    usage
    exit 1
fi
if [[ -z $HIVE_POSTGRES_PASSWORD ]]; then
    echo "No hive postgres password provided!"
    usage
    exit 1
fi

echo "Updating the system and installing Java 11"
yes | sudo apt-get update
yes | sudo apt-get upgrade
yes | sudo apt-get install openjdk-11-jre
yes | sudo apt-get install openjdk-11-jdk-headless

echo "Creating the hadoop user"
(
    sudo useradd -m hadoop -p "$(echo ${HADOOP_PASSWORD} | openssl passwd -1 -stdin)" && \
    sudo chsh -s /bin/bash hadoop
) || echo "User already exists! Skipping"
(
    sudo mkdir -p "/home/hadoop/.ssh" && \
    sudo chown hadoop:hadoop "/home/hadoop/.ssh" && \
    sudo cp "$HOME/.ssh/authorized_keys" "/home/hadoop/.ssh/authorized_keys" && \
    sudo chown hadoop:hadoop "/home/hadoop/.ssh/authorized_keys"
) || echo "File does not exist! Skipping"

sudo -i -u hadoop bash << OUTEREOF
cd
echo "Generating the hadoop user ssh keys"
yes | ssh-keygen -q -t ed25519 -f "\$HOME/.ssh/host_key" -N ""
chmod 600 "\$HOME/.ssh/host_key"
chmod 600 "\$HOME/.ssh/host_key.pub"

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
OUTEREOF

echo "Done!"
