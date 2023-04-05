#!/usr/bin/env bash

echo "Copying all config files to $HOME"

# Copy shell-specific config files
if [[ $SHELL == *bash* ]]; then
    cp .bashrc .bash_aliases .bash_profile $HOME
else
    cp .zshrc .zsh_aliases .zsh_profile $HOME
fi

cp .tmux.conf .tmux.conf.local .vimrc $HOME
cp -r .vim $HOME


cd $HOME

# install vim plugins
vim +PluginInstall +qall
