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

# turn off swappiness
echo 'vm.swappiness = 0' >> /etc/sysctl.conf
sysctl vm.swappiness=0


cat  >> /etc/security/limits.conf << EOF
user hard nofile 65546
user soft nofile 65536
EOF

yum update -y

download_install_rpm 'http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm'

yum install -y git tmux ppp pptp vpnc openvpn NetworkManager-pptp* NetworkManager-vpnc* NetworkManager-openvpn* NetworkManager* putty dkms kernel-devel httpd git libuuid-devel libtool zip unzip ntp ntpdate ntp-doc erlang telent gcc node npm vim
npm install -g inherits bower grunt grunt-cli nodemon watchify
yum groupinstall "Development Tools" -y

cat > /etc/profile.d/java.sh << EOF
export JAVA_HOME=/usr/lib/jvm/java
export PATH=\$JAVA_HOME/bin:\$PATH
EOF
turn_off_and_stop iptables
turn_on_and_start ntpd

$TOP_DIR/symlink-setup.sh


wait;
