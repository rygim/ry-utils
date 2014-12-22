set -e
set -x

TOP_DIR=$(cd $(dirname "$0") && pwd)

function turn_on_and_start {
    chkconfig $1 on
    service $1 start
}

function turn_off_and_stop {
    chkconfig $1 off
    service $1 stop
}

function download_install_rpm(){
  LINK=$1
  FILE=`echo $LINK | /bin/sed 's/.*\///'`
  cd /tmp
  set +e
  wget -nc $1 -O $FILE 
  rpm -ivH $FILE
  set -e
}

function install_tarball () {
  LINK=$1
  LINK_PATH=$2
  
  if [ ! -L $LINK_PATH ]
  then
    cd /tmp
    FILE=`echo $LINK | /bin/sed 's/.*\///'`
    wget -nc $LINK -O $FILE
    cd /opt
    DL_FILE=/tmp/$FILE
    TAR_ROOT_DIR=/opt/`tar -tf $DL_FILE | head -n 1 | /bin/sed 's/\/.*//'`
    cd /opt
    tar -xf $DL_FILE
    ln -s $TAR_ROOT_DIR $LINK_PATH
  fi
}

function compile_and_install {
  cd $1
  ./configure
  make 
  make install
}

function compile_and_install_autogen {
  cd $1
  FILE=`echo $LINK | /bin/sed 's/.*\///'`
  ./autogen.sh
  compile_and_install $1
}

function clone_repository {
   cd /opt
   REPO_DIR=`echo $1 | sed -e 's/.*\///' -e 's/\.git$//'`
   [ ! -d $REPO_DIR ] && git clone $1 $REPO_DIR
   cd $REPO_DIR 
   git pull 
}

 turn off swappiness
echo 'vm.swappiness = 0' >> /etc/sysctl.conf
sysctl vm.swappiness=0


cat  >> /etc/security/limits.conf << EOF
user hard nofile 65546
user soft nofile 65536
EOF

yum update -y

download_install_rpm 'http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm'
download_install_rpm 'http://archive.cloudera.com/cdh5/one-click-install/redhat/6/x86_64/cloudera-cdh-5-0.x86_64.rpm'

yum install -y git tmux ppp pptp vpnc openvpn NetworkManager-pptp* NetworkManager-vpnc* NetworkManager-openvpn* NetworkManager* putty dkms kernel-devel httpd git nodejs npm libuuid-devel libtool zip unzip ntp ntpdate ntp-doc erlang hadoop-yarn zookeeper-server anglia ganglia-devel ganglia-gmetad ganglia-gmond ganglia-web telnet
npm install -g inherits bower grunt grunt-cli
yum groupinstall "Development Tools" -y

cat > /etc/profile.d/java.sh << EOF
export JAVA_HOME=/usr/lib/jvm/java
export PATH=\$JAVA_HOME/bin:\$PATH
EOF
turn_off_and_stop iptables
turn_on_and_start ntpd

download_install_rpm 'http://www.rabbitmq.com/releases/rabbitmq-server/v3.2.3/rabbitmq-server-3.2.3-1.noarch.rpm'

install_tarball 'http://download-cf.jetbrains.com/idea/ideaIU-14.0.2.tar.gz' /opt/idea
install_tarball 'http://mirror.reverse.net/pub/apache/maven/maven-3/3.2.3/binaries/apache-maven-3.2.3-bin.tar.gz' /opt/maven
install_tarball 'http://apache.cs.utah.edu/storm/apache-storm-0.9.3/apache-storm-0.9.3.tar.gz' /opt/storm
install_tarball 'http://eclipse.org/downloads/download.php?file=/jetty/8.1.15.v20140411/dist/jetty-distribution-8.1.15.v20140411.tar.gz' /opt/jetty
install_tarball 'http://apache.mesi.com.ar/accumulo/1.5.2/accumulo-1.5.2-bin.tar.gz' /opt/accumulo
install_tarball 'https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.1.2.tar.gz' /opt/elasticsearch
install_tarball 'http://download.zeromq.org/zeromq-2.1.7.tar.gz' /opt/zeromq
clone_repository 'https://github.com/nathanmarz/jzmq.git'

chown root:root -R /opt
chmod g+w -R /opt 

#setup + initialize everything
IP_ADDR=`hostname -I | sed 's/ .*//'`

#hadoop
mkdir -p /var/lib/hadoop-hdfs/cache/hdfs/dfs/{name,namesecondary,data} /var/local/hadoop
chown hdfs:hdfs /var/lib/hadoop-hdfs/cache/hdfs/dfs/{name,namesecondary,data} /var/local/hadoop

sudo -u zookeeper mkdir -p /var/lib/zookeeper

#storm
compile_and_install /opt/zeromq
compile_and_install_autogen /opt/jzmq

turn_on_and_start hadoop-hdfs-namenode &
turn_on_and_start hadoop-hdfs-secondarynamenode &
turn_on_and_start hadoop-hdfs-datanode &
turn_on_and_start rabbitmq-server &
turn_on_and_start zookeeper-server &

$TOP_DIR/symlink-setup.sh


wait;
