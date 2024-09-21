#!/bin/bash

usage () {
    echo "Usage:"
    echo "./distribute_namenode_key.sh \\"
    echo "  --namenode-host <namenode_host_address> \\"
    echo "  <datanode_host_address>..."
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
        NAMENODE_HOST="$2"
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

scp "hadoop@$NAMENODE_HOST:/home/hadoop/.ssh/host_key.pub" host_key.pub
PUBLIC_KEY=$(cat host_key.pub)
rm host_key.pub

for host in "$@"; do
    ssh -x -a "hadoop@$host" /bin/bash << EOF
        echo "${PUBLIC_KEY}" >> ~/.ssh/authorized_keys
EOF
done

echo "Done!"