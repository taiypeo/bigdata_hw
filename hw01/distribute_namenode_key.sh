#!/bin/bash

usage () {
    echo "Usage:"
    echo "./distribute_namenode_key.sh \\"
    echo "  --namenode-user-host <username>@<namenode_host_address> \\"
    echo "  <username>@<datanode_host_address>..."
}

VALID_ARGS=$(getopt -o '' --long help,namenode-user-host: -- "$@")
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
    --namenode-user-host)
        NAMENODE_USER_HOST="$2"
        shift 2
        ;;
    --) shift;
        break
        ;;
  esac
done

if [[ -z $NAMENODE_USER_HOST ]]; then
    echo "No namenode user-host pair provided!"
    usage
    exit 1
fi

scp "$NAMENODE_USER_HOST:~/.ssh/host_key.pub" host_key.pub
PUBLIC_KEY=$(cat host_key.pub)
rm host_key.pub

for user_host in "$@"; do
    ssh -x -a "$user_host" /bin/bash << EOF
        echo "${PUBLIC_KEY}" >> ~/.ssh/authorized_keys
EOF
done

echo "Done!"