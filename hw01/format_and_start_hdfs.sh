#!/bin/bash

usage () {
    echo "Usage:"
    echo "./format_and_start_hdfs.sh \\"
    echo "  --namenode-host <namenode_host_address>"
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

ssh -x -a "hadoop@$NAMENODE_HOST" /bin/bash << EOF
    source .profile
    yes | hdfs namenode -format
    start-dfs.sh
EOF

echo "Done!"