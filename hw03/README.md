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
