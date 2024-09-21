#!/bin/bash

usage () {
    echo "Usage:"
    echo "./setup_host.sh --user-host <username>@<host_address> --password <hadoop_user_password>"
}

VALID_ARGS=$(getopt -o '' --long help,user-host:,password: -- "$@")
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
    --user-host)
        USER_HOST="$2"
        shift 2
        ;;
    --password)
        HADOOP_PASSWORD="$2"
        shift 2
        ;;
    --) shift;
        break
        ;;
  esac
done

if [[ -z $USER_HOST ]]; then
    echo "No user-host pair provided!"
    usage
    exit 1
fi
if [[ -z $HADOOP_PASSWORD ]]; then
    echo "No hadoop user password provided!"
    usage
    exit 1
fi

ssh -x -a "$USER_HOST" /bin/bash << EOF
    yes | sudo apt-get update
    yes | sudo apt-get upgrade
    yes | sudo apt-get install openjdk-11-jre

    sudo useradd -m hadoop -p "${HADOOP_PASSWORD} -s /bin/bash" || echo "User already exists!"
    (
        sudo cp "\$HOME/.ssh/authorized_keys" "/home/hadoop/.ssh/authorized_keys" && \
        sudo chown hadoop:hadoop "/home/hadoop/.ssh/authorized_keys"
    ) || echo "File does not exist! Skipping"
    sudo su hadoop

    ssh-keygen -q -t ed25519 -f "\$HOME/.ssh/host_key" -N ""
    chmod 600 "\$HOME/.ssh/host_key"
    chmod 600 "\$HOME/.ssh/host_key.pub"

    wget "https://dlcdn.apache.org/hadoop/common/hadoop-3.4.0/hadoop-3.4.0.tar.gz"
    tar -xzf "hadoop-3.4.0.tar.gz"
    export HADOOP_HOME=/home/hadoop/hadoop-3.4.0
    export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
    echo "JAVA_HOME=$JAVA_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
    export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
EOF

echo "Done!"
