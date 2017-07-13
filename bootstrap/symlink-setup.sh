#!/usr/bin/env bash

TOP_DIR=$(cd $(dirname "$0") && pwd)
REPO_TOP_DIR=$TOP_DIR/..

for file in  ~/.bashrc ~/.tmux.conf ~/.vimrc ~/.gitconfig
do
  [ -f $file ] && rm $file
  [ -L $file ] && unlink $file
done

ln -s $REPO_TOP_DIR/dotfiles/bashrc ~/.bashrc
ln -s $REPO_TOP_DIR/dotfiles/tmux.conf ~/.tmux.conf
ln -s $REPO_TOP_DIR/dotfiles/vimrc ~/.vimrc
ln -s $REPO_TOP_DIR/dotfiles/gitconfig ~/.gitconfig
ln -s $REPO_TOP_DIR/dotfiles/lynx.cfg ~/.lynx.cfg
