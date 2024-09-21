#!/bin/bash

usage () {
    echo "Usage:"
    echo "./setup_host_basic.sh --user-host <username>@<host_address> --password <hadoop_user_password>"
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
    sudo useradd hadoop
    sudo usermod -p "${HADOOP_PASSWORD}" hadoop
    ssh-keygen -q -t ed25519 -f "\$HOME/.ssh/host_key" -N ""
    chmod 600 "\$HOME/.ssh/host_key"
EOF

echo "Done!"
