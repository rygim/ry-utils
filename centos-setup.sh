set -e
set -x

wget http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -ivh epel-release-6-8.noarch.rpm

yum install -y git tmux ppp pptp vpnc openvpn NetworkManager-pptp* NetworkManager-vpnc* NetworkManager-openvpn* NetworkManager*

cd ~
mkdir repos
cd repos
git clone https://github.com/rygim/ry-utils.git
ln -s ~/repos/ry-utils/bash/bashrc ~/.bashrc
ln -s ~/repos/ry-utils/tmux/tmux.conf ~/.tmux.conf
ln -s ~/repos/ry-utils/vim/vimrc ~/.vimrc
