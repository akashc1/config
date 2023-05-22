#!/usr/bin/env bash

echo "Copying all config files to $HOME"

# Copy shell-specific config files
if [[ $SHELL == *bash* ]]; then
    cp .bashrc .bash_aliases .bash_profile $HOME
elif [[ $SHELL == *zsh* ]]; then
    cp .zshrc .zsh_aliases .zsh_profile $HOME
else
    echo "Unable to identify shell! Exiting..."
    kill -INT $$
fi

# Vim/tmux config files
cp .tmux.conf .tmux.conf.local .vimrc $HOME
cp -r .vim $HOME

# install vim plugins
vim +PluginInstall +qall
