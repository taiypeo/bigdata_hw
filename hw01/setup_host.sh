#!/bin/bash

usage () {
    echo "Usage:"
    echo "./setup_host.sh \\"
    echo "  --user <admin_username> \\"
    echo "  --host <host_address> \\"
    echo "  --password <hadoop_user_password> \\"
    echo "   [--namenode <namenode_address> [<datanode_host_address>...]]"
}

VALID_ARGS=$(getopt -o '' --long help,user:,host:,password:,namenode: -- "$@")
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
    --user)
        REMOTE_USER="$2"
        shift 2
        ;;
    --host)
        HOST="$2"
        shift 2
        ;;
    --password)
        HADOOP_PASSWORD="$2"
        shift 2
        ;;
    --namenode)
        NAMENODE_HOST="$2"
        shift 2
        ;;
    --) shift;
        break
        ;;
  esac
done

if [[ -z $REMOTE_USER ]]; then
    echo "No user provided!"
    usage
    exit 1
fi
if [[ -z $HOST ]]; then
    echo "No host provided!"
    usage
    exit 1
fi
if [[ -z $HADOOP_PASSWORD ]]; then
    echo "No hadoop user password provided!"
    usage
    exit 1
fi
if [[ -z $NAMENODE_HOST ]]; then
    echo "No namenode host provided!"
    usage
    exit 1
fi

DATANODE_HOSTS="$@"

ssh -x -a "$REMOTE_USER@$HOST" /bin/bash << OUTEREOF
    echo "Updating the system and installing Java 11"
    yes | sudo apt-get update
    yes | sudo apt-get upgrade
    yes | sudo apt-get install openjdk-11-jre
    yes | sudo apt-get install openjdk-11-jdk-headless

    echo "Creating the hadoop user"
    (
        sudo useradd -m hadoop -p "\$(echo ${HADOOP_PASSWORD} | openssl passwd -1 -stdin)" && \
        sudo chsh -s /bin/bash hadoop
    ) || echo "User already exists! Skipping"
    (
        sudo mkdir -p "/home/hadoop/.ssh" && \
        sudo chown hadoop:hadoop "/home/hadoop/.ssh" && \
        sudo cp "\$HOME/.ssh/authorized_keys" "/home/hadoop/.ssh/authorized_keys" && \
        sudo chown hadoop:hadoop "/home/hadoop/.ssh/authorized_keys"
    ) || echo "File does not exist! Skipping"

    sudo su hadoop
    cd

    echo "Generating the hadoop user ssh keys"
    yes | ssh-keygen -q -t ed25519 -f "\$HOME/.ssh/host_key" -N ""
    chmod 600 "\$HOME/.ssh/host_key"
    chmod 600 "\$HOME/.ssh/host_key.pub"

    if [[ ! -f "hadoop-3.4.0.tar.gz" ]]; then
        echo "Downloading Hadoop"
        wget -q "https://dlcdn.apache.org/hadoop/common/hadoop-3.4.0/hadoop-3.4.0.tar.gz"
        tar -xzf "hadoop-3.4.0.tar.gz"
    fi

    echo "Configuring Hadoop"
    echo 'export HADOOP_HOME=/home/hadoop/hadoop-3.4.0' >> .profile
    echo 'export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))' >> .profile
    echo 'export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin' >> .profile
    echo 'export HADOOP_SSH_OPTS="-i ~/.ssh/host_key"' >> .profile

    echo 'export HADOOP_HOME=/home/hadoop/hadoop-3.4.0' >> .bashrc
    echo 'export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))' >> .bashrc
    echo 'export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin' >> .bashrc
    echo 'export HADOOP_SSH_OPTS="-i ~/.ssh/host_key"' >> .bashrc

    export HADOOP_HOME=/home/hadoop/hadoop-3.4.0
    export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
    export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin

    echo "JAVA_HOME=\$JAVA_HOME" >> \$HADOOP_HOME/etc/hadoop/hadoop-env.sh
    echo 'HADOOP_SSH_OPTS="-i ~/.ssh/host_key"' >> \$HADOOP_HOME/etc/hadoop/hadoop-env.sh

    cat > \$HADOOP_HOME/etc/hadoop/core-site.xml<< EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://${NAMENODE_HOST}:9000</value>
    </property>
</configuration>
EOF

    cat > \$HADOOP_HOME/etc/hadoop/hdfs-site.xml<< EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>
    <property>
        <name>dfs.namenode.datanode.registration.ip-hostname-check</name>
        <value>false</value>
    </property>
</configuration>
EOF

    if [[ -n "${DATANODE_HOSTS}" ]]; then
        echo "\$datanode_host" > \$HADOOP_HOME/etc/hadoop/workers
        tr ' ' '\n' < <(echo ${DATANODE_HOSTS}) >> \$HADOOP_HOME/etc/hadoop/workers
    fi
OUTEREOF

echo "Done!"
