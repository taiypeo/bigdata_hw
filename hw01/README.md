```
bash setup_host.sh \
    --user admin \
    --host namenode_public_ip \
    --password "HadoopUserPassword" \
    --namenode \
    datanode_private_ip1 datanode_private_ip2
bash setup_host.sh \
    --user admin \
    --host datanode_public_ip1 \
    --password "HadoopUserPassword"
bash setup_host.sh \
    --user admin \
    --host datanode_public_ip2
    --password "HadoopUserPassword"

bash distribute_namenode_key.sh \
    --namenode-host "namenode_public_ip" \
    "datanode_public_ip1" \
    "datanode_public_ip2"

bash format_and_start_hdfs.sh --namenode-host "namenode_public_ip"
```