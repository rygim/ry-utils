TOP_DIR=$(cd $(dirname "$0") && pwd)

for file in  ~/.bashrc ~/.tmux.conf ~/.vimrc ~/.gitconfig
do
  [ -f $file ] && rm $file
  [ -L $file ] && unlink $file
done

ln -s $TOP_DIR/bash/bashrc ~/.bashrc
ln -s $TOP_DIR/tmux/tmux.conf ~/.tmux.conf
ln -s $TOP_DIR/vim/vimrc ~/.vimrc
ln -s $TOP_DIR/git/gitconfig ~/.gitconfig
