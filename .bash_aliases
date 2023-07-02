
attachtmux() {
    tmux new -s $1
    tmux a -t $1
}

list_directories() {
    if [[ $# == 1 ]]; then
        ls -d "$1"/*
    else
        ls -d ./*
    fi
}

model_diff() {
    if [[ $# != 2 ]]; then
        echo "Usage: model_diff BRANCH1 BRANCH2"
        exit
    fi
    git diff $1 $2 -- . | grep diff | grep config.yaml | cut -d / -f 6 | uniq

}

unique_jobs() {
    if [[ $# < 1 ]]; then
        echo "Usage: unique_jobs PIPELINE_ID"
        kill -INT $$
    fi
    squeue -o "%.24i %.20P %.8u %.2t %.10M %.6D %.6r %20N %j" -u `whoami` \
        | grep -v Depend | grep -v CG | grep $1 \
        | awk '{print $1}' | cut -d _ -f 1 | uniq
}

jobdirs() {
    if [[ $# < 1 ]]; then
        echo "Usage: jobdirs KEYWORD"
        kill -INT $$
    fi
    for j in `unique_jobs $1`; do
        getdir $j
    done
}

get_branch() {
    if [[ $# < 1 ]]; then
        echo "Usage: get_branch BRANCH"
        kill -INT $$
    fi
    branch=`git rev-parse --abbrev-ref HEAD`
    git fetch origin $1 && git checkout $1 && git checkout $branch
}


changed_files() {
    if [[ $# < 1 ]]; then
        branch='master'
    else
        branch=$1
    fi
    git diff $branch --name-only | cat
}


alias lsd="list_directories"
alias ll="ls -lhF --group-directories-first --color=auto"
alias ks="tmux kill-session -t"
alias tmuxc="attachtmux"
alias tmuxa="tmux a -t"

# always use --noaffinity for ag
alias ag="ag --noaffinity"

# easily make dated dir in `.`
alias td="date +'%Y_%m%d'"
alias ts="date +'%Y_%m%d_%H%M%S'"
alias mkdirdt="mkdir `date +'%Y_%m%d'`"

# Slurm helpers
alias idle="sidle | grep idle"
alias trainq="myq | grep gnode | grep -v eval | grep -v interactive"

# git shortcuts
alias gits="git status"
alias gita="git add ."
alias gitc="git commit -am"
alias gitb="git rev-parse --abbrev-ref HEAD"  # prints only current branch
alias ggrep="git grep"
alias gmc="ag \"<<< HEAD\""   # find any merge conflicts
alias grc="git add . && git rebase --continue"
alias grs="git rebase --skip"
alias gamend="git commit --amend"
alias gaa="gita . && gamend"
alias gtop="git log HEAD~1..HEAD | cat"

# git branching utils
alias mb='git branch -a | grep ${USER}'
alias mlb='git branch -a | grep ${USER} | grep -v remotes'
alias setb='export branch=`gitb`'
alias update_master='update_branch master'
alias push_new='git push -u origin HEAD'

alias sortdiff='isort $(git diff --name-only)'

# refresh files -- on some clusters this is needed to sync the filesystem :(
alias rf='find . > /dev/null'

update_branch() {
    if [[ $# < 1 ]]; then
        echo "Usage: update_branch <BRANCH>"
        kill -INT $$
    fi

    branch=`gitb`
    git checkout $1 && git pull
    git checkout $branch
}

rebase_on() {
    branch=`gitb`

    if [[ $# == 0 ]]; then
        base=master
    else
        base=$1
    fi

    git rebase $base
}



alias build_ap='tools/autopilot --podman build m3_3 -x86 -j 40 //common/tasks/vision'
alias clean_build='rm -rf bazel-bin bazel-firmware bazel-out bazel-testlogs envs logs'

alias ncpus="python -c 'from infra.constants import N_CPUS_ALLOCATED; print(N_CPUS_ALLOCATED)'"
alias ngpus="nvidia-smi > /dev/null && nvidia-smi -L | wc -l"
alias whole_gnode="srun --propagate=NONE --cpus-per-task 252 --ntasks 1 --gres=gpu:1 -p gnode-hi-pri --pty bash"
alias big_cnode="srun --propagate=NONE --cpus-per-task 252 --ntasks 1 -p cnode --pty bash"

alias debugpy="python -m debugpy --listen 0.0.0.0:`shuf -i9001-9999 -n1`"
