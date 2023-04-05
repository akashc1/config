source ~/.bash_aliases

if [[ $- == *i* ]]
then
    source ~/.bash_profile
    eval `ssh-agent -s`
    ssh-add ~/.ssh/rsa_id
    if [[ -d ./.git ]]
    then
        setb
    fi
fi

source ~/.machine_specific
export GIT_EDITOR='vim'
export EDITOR='vim'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
ctags=/opt/homebrew/bin/ctags
