#!/usr/bin/env bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

set -e 

echo changing the sudoers file to allow tty-less sudoing to other users
sed '/.*Defaults.*requiretty.*/d' < /etc/sudoers > /etc/sudoers.new
mv /etc/sudoers /etc/sudoers.old
mv /etc/sudoers.new /etc/sudoers

echo bootstrapping and starting single-node spark cluster...
WORKING_DIR=$(mktemp -d)
echo working directory is $WORKING_DIR

echo finding local ip
#LOCAL_IP=`curl http://169.254.169.254/latest/meta-data/local-ipv4` #for aws 
LOCAL_IP=`hostname -I | tr -d ' '`
echo local IP is $LOCAL_IP, going to bind everything to that ip 
cd $WORKING_DIR

yum repolist | grep cloudera-cdh5 || {
    echo installing cdh5 rpm \(adds the repo we need to pull from\)
    wget http://archive.cloudera.com/cdh5/one-click-install/redhat/6/x86_64/cloudera-cdh-5-0.x86_64.rpm
    yum install $WORKING_DIR/cloudera-cdh-5-0.x86_64.rpm -y
    echo done installing cdh5 rpm
} 
echo doing yum update from all repositories
yum update -y

echo installing all of the packages
yum install hadoop-hdfs-namenode hadoop-hdfs-datanode hadoop-client spark-core spark-master spark-worker -y

HDFS=/var/run/hadoop-hdfs
echo created hdfs data directories..
mkdir -p $HDFS/{name,data}
chown hdfs:hdfs -R $HDFS
echo hdfs files will be in $HDFS

echo changing /etc/hadoop/conf/core-site.xml
echo "<configuration><property><name>fs.defaultFS</name><value>hdfs://$LOCAL_IP/</value></property></configuration>" > /etc/hadoop/conf/core-site.xml

echo changing /etc/hadoop/conf/hdfs-site.xml
echo "<configuration><property><name>dfs.name.dir</name><value>$HDFS/name</value></property><property><name>dfs.datanode.data.dir</name><value>$HDFS/data</value></property></configuration>" > /etc/hadoop/conf/hdfs-site.xml

echo formatting the namenode
sudo -u hdfs hadoop namenode -format
echo starting the namenode service
service hadoop-hdfs-namenode start
echo starting the datanode service
service hadoop-hdfs-datanode start

SPARK_CONF=/etc/spark/conf
echo adding this node to the slaves file
echo $LOCAL_IP > $SPARK_CONF/slaves

cat $SPARK_CONF/spark-env.sh | sed -e '/^#.*/d' -e '/^$/d' -e '/^.*STANDALONE_SPARK_MASTER_HOST.*$/d' > $SPARK_CONF/spark-env.new

echo export STANDALONE_SPARK_MASTER_HOST=`hostname -A` >> $SPARK_CONF/spark-env.new
echo export SPARK_MASTER_IP=\$STANDALONE_SPARK_MASTER_HOST >> $SPARK_CONF/spark-env.new

cp $SPARK_CONF/spark-env.new $SPARK_CONF/spark-env.sh

echo starting spark-master
service spark-master start
echo starting spark-worker
service spark-worker start


