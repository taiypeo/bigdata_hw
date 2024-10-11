# Развертывание минимального кластера Hadoop

*Данная последовательность действий проверялась на работоспособность на Яндекс Облаке*
*и выданных ресурсах в рамках курса.*

Пусть у нас есть 4 ноды, одна из которых будет JumpNode, другая -- NameNode, а остальные -- DataNode.
Пусть у них у всех есть sudo пользователь team.
**Если мы работаем на выданных машинах, то ниже все соответствующие public и private IP будут совпадать.**
Если же мы работаем с Яндекс Облаком, то для каждого хоста есть как публичный IP адрес, чтобы получить доступ с нашей машины,
а также приватный, чтобы ноды могли в облаке между собой общаться в своей сети.

## Настройка NameNode и DataNode
Прежде чем разворачивать кластер, настроим NOPASSWD доступ к sudo **на каждом хосте** (namenode и все datanode):
1) `ssh team@public_ip`
2) На хосте запускаем `sudo visudo`
3) Добавляем перед (строкой выше) `@includedir /etc/sudoers.d` вот это: `team ALL=(ALL) NOPASSWD:ALL`

Теперь можно развернуть кластер таким набором команд:
```bash
# Сетапим ноду -- устанавливаем Java и Hadoop, конфигурируем последний
# Так как в конце есть positional arguments, эта нода будет считаться NameNode
# Важно не забыть поставить "localhost" в конце! Иначе у нас на этой ноде не будет запущен
# daemon DataNode

# !!! Не забываем здесь и ниже заменять .*_ip на настоящие IP адреса !!!
bash setup_host.sh \
    --user team \
    --host namenode_public_ip \
    --password "HadoopUserPassword" \
    --namenode namenode_private_ip \
    "localhost" datanode_private_ip1 datanode_private_ip2

# Аналогично, сетап нод, но уже DataNodes
bash setup_host.sh \
    --user team \
    --host datanode_public_ip1 \
    --password "HadoopUserPassword" \
    --namenode namenode_private_ip
bash setup_host.sh \
    --user team \
    --host datanode_public_ip2 \
    --password "HadoopUserPassword" \
    --namenode namenode_private_ip

# Перекидываем публичный ssh ключ NameNode на DataNodes,
# чтобы с NameNode можно было достучаться до DataNodes
bash distribute_namenode_key.sh \
    --namenode-host "namenode_public_ip" \
    "datanode_public_ip1" \
    "datanode_public_ip2"

# Заходим на NameNode, форматируем HDFS и стартуем кластер
ssh hadoop@namenode_public_ip
# ==== Команды ниже уже вводятся не локально, а на NameNode!!!! ====
hdfs namenode -format
start-dfs.sh
```

В последовательности команд есть несколько интерактивных моментов:
- Нужно добавить NOPASSWD для sudo на каждый хост
- При попытке подключиться на новый хост через ssh нужно вручную написать "yes"
(возможно придется просто несколько раз это сделать без промпта, если выглядит, как будто зависло
-- это просто ожидается ввод) и ввести пароль
- Форматирование и start-dfs.sh (последние 2 команды выше) запускаются вручную на хосте NameNode


Работоспособность можно проверить `jps` и `hdfs dfsadmin -report` (на нодах **под юзером hadoop**).

## Настройка jump node
Для того, чтобы открыть веб-интерфейс Hadoop, нам нужно на нашей jump node настроить reverse proxy
с помощью nginx. Для этого на локальной машине зайдем по ssh на jump node (`ssh team@jump-node-ip`)
и выполним **на jump node** следующие команды:
```bash
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/nn
sudo vim /etc/nginx/sites-available/nn
```

И заменяем следующие строки:
- `listen 80 default_server;` -> `listen 9870 default_server;`
- `listen [::]:80 default_server;` -> `# listen [::]:80 default_server;`
- Внутри `location / { ... }`:
    - `try_files $uri $uri/ =404;` -> `proxy_pass http://namenode-ip:9870;`
    (не забывая заменить namenode-ip на настоящий IP-адрес)

Далее сохраняем файл и делаем:
```bash
sudo ln -s /etc/nginx/sites-available/nn /etc/nginx/sites-enabled/nn
sudo systemctl reload nginx
```

И по `http://jumpnode_public_ip:9870` в браузере будет доступен веб-интерфейс.
