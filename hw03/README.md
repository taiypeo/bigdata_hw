# Развертывание Apache Hive

## Установка и настройка postgres
Для начала, требуется на NameNode установить postgres и создать БД. С JumpNode выполняем:
```bash
# ====== Ниже на JumpNode! ======
ssh team@namenode-ip`
# ====== Ниже уже на NameNode! ======
sudo apt install postgresql
sudo -i -u postgres
psql
# ====== Ниже уже в psql (не забывая поставить хороший пароль ниже)! ======
CREATE DATABASE metastore;
CREATE USER hive with password 'HivePostgresPassword';
GRANT ALL PRIVILEGES ON DATABASE "metastore" TO hive;
ALTER DATABASE metastore OWNER TO hive;
\q
# ====== Ниже уже на NameNode! ======
exit  # выйти из пользователя postgres
sudo vim /etc/postgresql/16/main/postgresql.conf
```

В конфиге требуется в секции "CONNECTIONS AND AUTHENTICATION" в начале добавить
(не забывая заменить `<namenode-ip>` на IP адрес NameNode)
```
listen_addresses = '<namenode-ip>'
```

```bash
sudo vim /etc/postgresql/16/main/pg_hba.conf
```

В конфиге требуется в секции "IPv4 local connections" в начале добавить
(не забывая заменить `<jumpnode-ip>` на IP адрес JumpNode)
```
host    metastore       hive            <jumpnode-ip>/32         password
```

Также требуется в той же секции удалить строку
```
host    all             all             127.0.0.1/32            scram-sha-256
```

Далее,
```bash
sudo systemctl restart postgresql
```

И возвращаемся на jump node (`exit`).
```bash
# ====== Ниже уже на JumpNode! ======
sudo apt install postgresql-client-16
```

## Установка и настройка Apache Hive
На JumpNode под sudo пользователем (team) требуется запустить скрипт setup_host.sh из
первой домашней работы (`hw01/`, не забывая поставить NOPASSWD доступ к sudo для team, см. `hw01/README.md`):
```bash
bash setup_host.sh \
    --user team \
    --host jumpnode_ip \
    --password "HadoopUserPassword" \
    --namenode namenode_ip
```

Далее, на JumpNode под sudo пользователем (team) требуется запустить скрипт setup_hive.sh:
```bash
bash setup_hive.sh \
    --namenode namenode_ip \
    --hive-password HivePostgresPassword
```

Теперь, для запуска Apache Hive на Jump Node выполним следующие команды:
```bash
su hadoop
cd ~
source ~/.profile
hive \
    --hiveconf hive.server2.enable.doAs=false \
    --hiveconf hive.security.authorization.enabled=false \
    --service hiveserver2 \
    1>> /tmp/hs2.log 2>> /tmp/hs2.log
```

Проверить работу можно так в другом терминале:
```bash
su hadoop
cd ~
source ~/.profile
beeline -u jdbc:hive2://jumpnode-ip:5433
# ====== Ниже в beeline! ======
SHOW DATABASES;
CREATE DATABASE test;
SHOW DATABASES;
DESCRIBE DATABASE test;
```

Результат установки и настройки:
![image](https://github.com/user-attachments/assets/52280501-133b-47b2-b89a-63403c2d96a7)
![image](https://github.com/user-attachments/assets/5ca4f517-8bd8-4702-9fa9-bb71dc15e0c2)

## Загрузка данных в Apache Hive
Пусть у нас есть некоторый большой датасет `dataset.csv`
(например, я работал с https://github.com/PacktWorkshops/The-Data-Science-Workshop/raw/refs/heads/master/Chapter09/Dataset/KDDCup99.csv).
Его можно загрузить на JumpNode: `scp dataset.csv jumpnode-ip:/home/hadoop/dataset.csv`.

На JumpNode под пользователем hadoop выполним:
```bash
cd ~
source ~/.profile
hdfs dfs -mkdir /input
hdfs dfs -chmod g+w /input
hdfs dfs -put dataset.csv /input
hdfs fsck /input/dataset.csv  # проверка, что все хорошо с файлом на HDFS
beeline -u jdbc:hive2://jumpnode-ip:5433
# ====== Ниже в beeline! ======
use test;
CREATE TABLE IF NOT EXISTS test.dataset (
    `duration` string,
    `protocol_type` string,
    `service` string,
    `flag` string,
    `src_bytes` string,
    `dst_bytes` string,
    `land` string,
    `wrong_fragment` string,
    `urgent` string,
    `hot` string,
    `num_failed_logins` string,
    `logged_in` string,
    `lnum_compromised` string,
    `lroot_shell` string,
    `lsu_attempted` string,
    `lnum_root` string,
    `lnum_file_creations` string,
    `lnum_shells` string,
    `lnum_access_files` string,
    `lnum_outbound_cmds` string,
    `is_host_login` string,
    `is_guest_login` string,
    `count` string,
    `srv_count` string,
    `serror_rate` string,
    `srv_serror_rate` string,
    `rerror_rate` string,
    `srv_rerror_rate` string,
    `same_srv_rate` string,
    `diff_srv_rate` string,
    `srv_diff_host_rate` string,
    `dst_host_count` string,
    `dst_host_srv_count` string,
    `dst_host_same_srv_rate` string,
    `dst_host_diff_srv_rate` string,
    `dst_host_same_src_port_rate` string,
    `dst_host_srv_diff_host_rate` string,
    `dst_host_serror_rate` string,
    `dst_host_srv_serror_rate` string,
    `dst_host_rerror_rate` string,
    `dst_host_srv_rerror_rate` string,
    `label` string)
    ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';
LOAD DATA INPATH '/input/dataset.csv' INTO TABLE test.dataset;
```

Выполним простую MapReduce таску -- посчитаем, сколько всего строк в датасете:
```
SELECT COUNT(*) FROM dataset;
```

Результат:
Теперь у нас есть Apache Hive таблица с таким числом строк.
```
+---------+
|   _c0   |
+---------+
| 494021  |
+---------+
```

![image](https://github.com/user-attachments/assets/fbe3f9da-3eba-4249-a0a4-7583408aedc6)
![image](https://github.com/user-attachments/assets/2ea18ef3-ffc9-46cc-a788-febebd2e8475)
