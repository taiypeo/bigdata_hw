#!/bin/bash

usage () {
    echo "Usage:"
    echo "./setup_basic.sh --host <host_address> --user <remote_user> --password <hadoop_user_password>"
}

VALID_ARGS=$(getopt -o '' --long help,user:,host:,password: -- "$@")
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
    --host)
        HOST="$2"
        shift 2
        ;;
    --user)
        REMOTE_USER="$2"
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

if [[ -z $HOST ]]; then
    echo "No host provided!"
    usage
    exit 1
fi
if [[ -z $REMOTE_USER ]]; then
    echo "No remote user provided!"
    usage
    exit 1
fi
if [[ -z $HADOOP_PASSWORD ]]; then
    echo "No hadoop user password provided!"
    usage
    exit 1
fi

ssh -x -a "$REMOTE_USER@$HOST" /bin/bash << EOF
    yes | sudo apt-get update
    yes | sudo apt-get upgrade
    yes | sudo apt-get install openjdk-11-jre
    sudo useradd hadoop
    sudo usermod -p "${HADOOP_PASSWORD}" hadoop
EOF

echo "Done!"
