#!/usr/bin/env bash
echo bootstrapping and starting single-node spark cluster...
WORKING_DIR=$(mktemp -d)
echo working directory is $WORKING_DIR

echo FINDING LOCAL IP
#LOCAL_IP=`curl http://169.254.169.254/latest/meta-data/local-ipv4` #for aws 
LOCAL_IP=`hostname -I`
echo local IP is $LOCAL_IP, going to bind everything to that ip 

cd $WORKING_DIR

echo installing cdh5 rpm (adds the repo we need to pull from)
wget http://archive.cloudera.com/cdh5/one-click-install/redhat/6/x86_64/cloudera-cdh-5-0.x86_64.rpm
yum install $WORKING_DIR/cloudera-cdh-5-0.x86_64.rpm -y
echo done, doing yum update from all repositories
yum update -y

echo installing all of the packages
yum install hadoop-hdfs-namenode hadoop-hdfs-datanode hadoop-client spark-core spark-master spark-worker

HDFS=/var/run/hadoop-hdfs
echo created hdfs data directories..
mkdir -p $HDFS/{name,data}
chown hdfs:hdfs -R $HDFS
echo hdfs files will be in $HDFS

echo changing /etc/hadoop/conf/core-site.xml
echo "<configuration><property><name>fs.defaultFS</name><value>$LOCAL_IP</value></property></configuration>" > /etc/hadoop/conf/core-site.xml

echo changing /etc/hadoop/conf/hdfs-site.xml
echo "<configuration><property><name>dfs.name.dir</name><value>$HDFS/name</value></property><property><name>dfs.datanode.data.dir</name><value>$HDFS/data</value><</property></configuration>" > /etc/hadoop/conf/hdfs-site.xml

echo formatting the namenode
sudo -u hdfs hadoop namenode -format
echo starting the namenode service
service hadoop-hdfs-namenode start
echo starting the datanode service
service hadoop-hdfs-datanode start


echo adding this node to the slaves file
echo $LOCAL_IP > /etc/spark/conf/slaves

service spark-master start
service spark-worker start

