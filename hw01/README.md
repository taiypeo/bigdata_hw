# Развертывание минимального кластера Hadoop

Пусть у нас есть 3 ноды, одна из которых будет NameNode, а остальные -- DataNode.
Пусть у них у всех есть sudo пользователь admin.
Также работаем в предположении, что для каждого хоста есть как публичный IP адрес, чтобы получить доступ с нашей машины,
а также приватный, чтобы ноды могли в облаке между собой общаться в своей сети (так, например, в Яндекс Облаке, но
если разделения нет, то соответствующие public и private IP будут одинаковыми).

Тогда, можно развернуть кластер таким набором команд:
```bash
# Сетапим ноду -- устанавливаем Java и Hadoop, конфигурируем последний
# Так как в конце есть positional arguments, эта нода будет считаться NameNode
# Важно не забыть поставить "localhost" в конце! Иначе у нас на этой ноде не будет запущен
# daemon DataNode
bash setup_host.sh \
    --user admin \
    --host namenode_public_ip \
    --password "HadoopUserPassword" \
    --namenode namenode_private_ip \
    "localhost" datanode_private_ip1 datanode_private_ip2

# Аналогично, сетап нод, но уже DataNodes
bash setup_host.sh \
    --user admin \
    --host datanode_public_ip1 \
    --password "HadoopUserPassword" \
    --namenode namenode_private_ip
bash setup_host.sh \
    --user admin \
    --host datanode_public_ip2 \
    --password "HadoopUserPassword" \
    --namenode namenode_private_ip

# Перекидываем публичный ssh ключ NameNode на DataNodes,
# чтобы с NameNode можно было достучаться до DataNodes
bash distribute_namenode_key.sh \
    --namenode-host "namenode_public_ip" \
    "datanode_public_ip1" \
    "datanode_public_ip2"

# Форматируем HDFS и стартуем кластер
bash format_and_start_hdfs.sh --namenode-host "namenode_public_ip"
```