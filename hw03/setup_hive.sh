#!/bin/bash

usage () {
    echo "Usage:"
    echo "./setup_hive.sh \\"
    echo "  --password <hadoop_user_password>"
}

VALID_ARGS=$(getopt -o '' --long help,password: -- "$@")
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
    --password)
        HADOOP_PASSWORD="$2"
        shift 2
        ;;
    --) shift;
        break
        ;;
  esac
done

if [[ -z $HADOOP_PASSWORD ]]; then
    echo "No hadoop user password provided!"
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

sudo -i -u hadoop bash << EOF
cd
echo "Generating the hadoop user ssh keys"
yes | ssh-keygen -q -t ed25519 -f "\$HOME/.ssh/host_key" -N ""
chmod 600 "\$HOME/.ssh/host_key"
chmod 600 "\$HOME/.ssh/host_key.pub"

if [[ ! -f "apache-hive-4.0.1-bin.tar.gz" ]]; then
    echo "Downloading Apache Hive"
    wget -q "https://dlcdn.apache.org/hive/hive-4.0.1/apache-hive-4.0.1-bin.tar.gz"
    tar -xzf "apache-hive-4.0.1-bin.tar.gz"
fi
EOF

echo "Done!"
