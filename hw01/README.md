```
bash setup_host.sh --user-host "admin@namenode_public_ip" --password "HadoopUserPassword"
bash setup_host.sh --user-host "admin@datanode_public_ip1" --password "HadoopUserPassword"
bash setup_host.sh --user-host "admin@datanode_public_ip2" --password "HadoopUserPassword"

bash distribute_namenode_key.sh \
    --namenode-host "namenode_public_ip" \
    "datanode_public_ip1" \
    "datanode_public_ip2"
```