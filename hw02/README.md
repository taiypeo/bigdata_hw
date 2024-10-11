# Развертывание YARN и HistoryServer

## Настройка YARN
Работаем в предположении, что кластер Hadoop уже подготовлен и запущен (`start-dfs.sh`) кодом из
`../hw01`.

Для запуска, выполним на jump node следующие команды:
```bash
# !!! Не забываем здесь и ниже заменять .*_ip на настоящие IP адреса !!!
./setup_host --host namenode_public_ip
./setup_host --host datanode_public_ip1
./setup_host --host datanode_public_ip2

ssh hadoop@namenode_public_ip
# ==== Команды ниже уже вводятся не на JumpNode, а на NameNode!!!! ====
start-yarn.sh
mapred --deamon start historyserver
```

## Настройка jump node
Добавим в nginx reverse proxy информацию про YARN и
MapReduce аналогично прошлой домашней работе.

Все действия выполняются на jump node
(`ssh team@jump-node-ip`).

### YARN
```bash
sudo cp /etc/nginx/sites-available/nn /etc/nginx/sites-available/ya
sudo vim /etc/nginx/sites-available/ya
```

И заменяем следующие строки:
- `listen 9870 default_server;` -> `listen 8088 default_server;`
- Внутри `location / { ... }`:
    - `proxy_pass http://namenode-ip:9870;` -> `proxy_pass http://namenode-ip:8088;`
    (не забывая заменить namenode-ip на настоящий IP-адрес)

### HistoryServer
```bash
sudo cp /etc/nginx/sites-available/nn /etc/nginx/sites-available/dh
sudo vim /etc/nginx/sites-available/dh
```

И заменяем следующие строки:
- `listen 9870 default_server;` -> `listen 19888 default_server;`
- Внутри `location / { ... }`:
    - `proxy_pass http://namenode-ip:9870;` -> `proxy_pass http://namenode-ip:19888;`
    (не забывая заменить namenode-ip на настоящий IP-адрес)

Далее сохраняем файлы и делаем:
```bash
sudo ln -s /etc/nginx/sites-available/ya /etc/nginx/sites-enabled/ya
sudo ln -s /etc/nginx/sites-available/dh /etc/nginx/sites-enabled/dh
sudo systemctl reload nginx
```

И по `http://jumpnode_public_ip:8088` в браузере будет доступен веб-интерфейс YARN,
а по `http://jumpnode_public_ip:19888` -- веб-интерфейс HistoryServer.
