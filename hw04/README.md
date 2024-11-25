# Работа со Spark
На jump node запустим
```bash
bash setup_spark.sh --namenode-host namenode-ip
```

В отдельном терминале на jump node под юзером hadoop запустим:
```bash
hive
    --hiveconf hive.server2.enable.doAs=false
    --hiveconf hive.security.authorization.enabled=false
    --service metastore
    1>> /tmp/metastore.log
    2>> /tmp/metastore.log
```

На jump node выполним:
```bash
ssh team@namenode-ip
# ===== Ниже уже на NameNode! =====
sudo apt install python3.12-venv
su hadoop
cd ~
source ~/.profile
python3 -m venv .venv
source .venv/bin/activate
pip install pyspark
python
```

В интерпретаторе Python запустим сессию Spark, не забывая заменить jumpnode-ip
на нужный IP-адрес
(в предположении, что HDFS, YARN и Hive уже запущены по инструкциям из предыдущих
домашних заданий):
```python
from pyspark.sql import SparkSession
session = SparkSession.builder \
    .master("yarn") \
    .appName("spark-with-yarn") \
    .config("spark.sql.warehouse.dir", "/user/hive/warehouse") \
    .config("spark.hadoop.hive.metastore.uris", "thrift://jumpnode-ip:9083") \
    .enableHiveSupport() \
    .getOrCreate()

df = session.read.csv("/input/dataset.csv")
df.write.saveAsTable("testTable")
```