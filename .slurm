# - vim: ft=sh
#
#
conda activate /scratch/users/akashc/miniconda3/envs/test_env
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

export INTERACTIVE_GNODE_PARTITION="willhies"  #,owners"
export DEFAULT_CNODE_PARTITION="willhies"
default_gpu_interactive_mem="64g"

export PYTHONDONTWRITEBYTECODE=1


# Since numpy==1.16.5, they enabled some hugepage support for allocating memory
# by default.  This caused some instability especially when frequently copying
# images (as we are currently doing in util/augmentation.py), and this problem
# might occur randomly (possibly due to fragmentations in memory). The symptoms
# of this are elevated latencies when calling img.copy(), but the problem
# happens intermittently, making it extremely hard to debug. To return to
# previous behavior, we can use the following environment variable.
# See also:
#   * https://github.com/numpy/numpy/issues/15545
#   * https://github.com/numpy/numpy/pull/14322
#   * https://github.com/numpy/numpy/pull/15769
export NUMPY_MADVISE_HUGEPAGE=0

export MPLBACKEND="Agg"  # Matplotlib backend

# HDF5 wants to lock all files, even when opened read-only. This can result in errno 11, resource
# unavailable, when calling fcntl to lock files. Instead, don't bother locking. The risk is that
# we will attempt to read an HDF5 file while it is being written. This risk is, very, very low.
export HDF5_USE_FILE_LOCKING="FALSE"


# Set the pythonpath so we can call `python scripts/..` with the cwd as its python root path.
export PYTHONPATH=":"


# Handy slurm shortcuts
function allmyjobs () {
    local from=${1:-"1 month ago"}
    sacct -T -S $(date -d "$from" "+%Y-%m-%d") --format=JobID,state,time,start,elapsed,partition,nodelist%15,Jobname%-70 | sed -e '1,2{H;d}; ${p;x;s/^\n//}' | less +G
}

function jobstatus() {
    # The sed and less from above not needed because this usually produces a short list (unless
    # you go crazy on your comma-separated list of job IDs, which you should not)
    sacct -j "$1" --format=JobID,state,time,start,elapsed,partition,nodelist%15,Jobname%-70
}

alias q='squeue -o "%.18i %.20P %.8u %.2t %.10M %.6D %.6r %20N %j" | grep -v Depend'
alias allq='squeue -o "%.18i %.20P %.8u %.2t %.10M %.6D %.6r %20N %j"'
alias myq='squeue -o "%.24i %.20P %.8u %.2t %.10M %.6D %.6r %20N %b %j" -u `whoami` | grep -v Depend'
alias allmyq='squeue -o "%.24i %.20P %.8u %.2t %.10M %.6D %.32r %32E %20N %j" -u `whoami`'
alias pq='squeue -o "%.10i %.20P %.8u %.2t %.10M %.6D %.6r %20N %13b %j" -p willhies | grep -v Depend'
alias scancelall='squeue -u $(whoami) -o "%i"  --noheader| xargs -I{} scancel {}'
alias scancelnodeps='scancel --signal=USR1' # kill <job_id> but keep dependent jobs alive
alias sinf='sinfo -s -o "%20P %gpu.5a %.15G %.10l %.6D %.6t %N"'
alias sidle='sinfo -s -o "%20P %.5a %.15G %.10l %.6D %.6t %N" -t IDLE'
alias sdead='sinf | grep -Pv "idle|alloc|mix"'
alias sterminate='scancel -s 14' # Kill the job immediately without the graceful wait

function nodehog() {
    if [[ -z $1 ]]; then
        partition=${INTERACTIVE_GNODE_PARTITION}
    else
        partition=$1
    fi

    worst=$(q | grep $partition | sed 's/  */:/g' | cut -d: -f4 | sort -n | uniq -c | sort -nr | head -n 1 | sed 's/  */:/g')
    worstcount=$(echo $worst | cut -d: -f2)
    worstname=$(echo $worst | cut -d: -f3)

    >&2 echo "--- '$partition' node usage ---"
    >&2 echo "'$worstname' has the most jobs! (count:$worstcount)"
    >&2 echo
    printf "$(q | grep $partition | sed 's/  */:/g' | cut -d: -f4 | sort -n | uniq -c | sed 's/  */:/g' | cut -d: -f3,2)"
    echo
}

function login () {
    # Creates another interactive shell in the cpu/gpunode of the specified job id
    if [[ $# != 1 ]]; then
        echo >&2 "Exactly 1 argument (jobid) required, but $# provided"
        return 1
    fi

    local jobid=$1
    if [[ $(srun --version) =~ "slurm 2".* ]]; then
        srun --jobid $jobid --gres=gpu:0 --overlap --pty bash -i
    else
        srun --jobid $jobid --gres=gpu:0 --pty bash -i
    fi
}

function cpunode () {
    ptybash="--pty bash"
    cmd=${1:-${ptybash}}
    mem=${SLURM_MEM_PER_NODE:-"10g"}
    echo "Reserving ${mem} memory, if you need more, please set env SLURM_MEM_PER_NODE=XXg"
    srun --propagate=NONE --mem "${mem}" --cpus-per-task 8 --ntasks 1 --time 1-00:00:00 -p ${DEFAULT_CNODE_PARTITION} ${cmd}
}

function gpunode () {
    ptybash="--pty bash"
    partition=${1:-${INTERACTIVE_GNODE_PARTITION}}
    cmd=${2:-${ptybash}}
    mem=${SLURM_MEM_PER_NODE:-$default_gpu_interactive_mem}
    echo "Reserving ${mem} memory, if you need more, please set env SLURM_MEM_PER_NODE=XXg"
    srun --propagate=NONE --mem "${mem}" --cpus-per-task 8 --ntasks 1 --gres=gpu:1 --time 4-00:00:00 -p ${partition} ${cmd}
}

function lx () {
    default_slurm_log_file="/scratch/users/`whoami`/slurm_logs/job-${1}.out"
    slurm_log_dir=`env | grep MY_SLURM_LOG_DIR`
    slurm_log_file="${slurm_log_dir}/job-${1}.out"
    if [ -f $default_slurm_log_file ]; then
        less +F ${default_slurm_log_file}
    elif [ -f $slurm_log_file ]; then
        less +F ${slurm_log_file}
    else
        scontrol_log_file=`scontrol show job $1 | grep StdOut | cut -f2 -d=`
        if [ -f $scontrol_log_file ]; then
            less +F ${scontrol_log_file}
        fi
    fi
}

function lxe () {
    default_slurm_log_file="/scratch/users/`whoami`/slurm_logs/job-${1}.err"
    slurm_log_dir=`env | grep MY_SLURM_LOG_DIR`
    slurm_log_file="${slurm_log_dir}/job-${1}.err"
    if [ -f $default_slurm_log_file ]; then
        less +F ${default_slurm_log_file}
    elif [ -f $slurm_log_file ]; then
        less +F ${slurm_log_file}
    else
        scontrol_log_file=`scontrol show job $1 | grep StdErr | cut -f2 -d=`
        if [ -f $scontrol_log_file ]; then
            less +F ${scontrol_log_file}
        fi
    fi
}

function cancel_recursive () {
    # used only by scancel_chain
    cancel_job="$1"
    job_deps="$2"
    echo "  " scancel $cancel_job
    scancel $cancel_job

    # if `scancel` returned an error then stop recursing (0 means success)
    if [[ $? != 0 ]]; then
        return
    fi

    for job in "${!job_deps[@]}"
    do
        dep=${job_deps[$job]}
        if [[ $dep -eq $cancel_job ]]
        then
            cancel_recursive $job_deps $job
        fi
    done
}

function scancel_chain () {

  if [[ -z "$1" ]]; then
    echo 'usage: scancel_chain <jod_id> [job_id ...]'
    return
  fi

  # cancels all dependent jobs
  for job_id in $@; do
      echo "Killing '$job_id' and all its dependent jobs:"

      cancel_job=$job_id
      declare -A job_deps

      fname=`mktemp`
      squeue -o "%i %E" -u `whoami` >> $fname
      while read job dep
      do
          job=`echo $job | cut -f1 -d_`
          dep=`echo $dep | cut -f2 -d: | cut -f1 -d_ | cut -f1 -d\(`
          if [ ! -z "$dep" ]; then
              job_deps["$job"]=$dep
          fi
      done < $fname

      cancel_recursive $cancel_job $job_deps
      rm $fname
      echo # put a blank line between outputs
  done
}

function sx () {
    sattach ${1}.0
}

function sxf () {
    sattach ${1}.0 | grep 'loss: ' | sed -r -e 's/.*loss: ([^,]+),.*steps: ([0-9]+),.*/000000\2 \1/' -e "s/0*([0-9]{6}) (.*)/${1} \1 \2/"
}

function sqlite3() {
    # Be careful with sqlite3, and open files in readonly mode by default.
    # If you really need the original sqlite3 binary, you can find it using
    # which sqlite3, then use the absolute path
    SQLITE3_BIN_PATH=$(which sqlite3)
    if [ $# -eq 0 ]; then
        $SQLITE3_BIN_PATH
    else
        $SQLITE3_BIN_PATH "file:$1?immutable=1&mode=ro" "${@:2}"
    fi
}

# Handy aliases
alias topme='htop -u $USER -d 10'
alias wtf='python -m pdb -c continue'
alias gpus='watch -n 0.5 nvidia-smi'
alias cpus='watch -n 0.5 grep MHz /proc/cpuinfo'
alias memory='watch -n 0.5 "free -g ; echo ; echo ; df -h | grep shm"'
alias refcat='watch -n 1 cat '
alias reload='source ~/.bash_profile'

