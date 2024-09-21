```
bash setup_host_basic.sh --user-host "admin@namenode_public_ip" --password "HadoopUserPassword"
bash setup_host_basic.sh --user-host "admin@datanode_public_ip1" --password "HadoopUserPassword"
bash setup_host_basic.sh --user-host "admin@datanode_public_ip2" --password "HadoopUserPassword"

bash distribute_namenode_key.sh \
    --namenode-user-host "hadoop-admin@namenode_public_ip" \
    "admin@datanode_public_ip1" \
    "admin@datanode_public_ip2"
```