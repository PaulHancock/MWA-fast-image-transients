function tag {
    $@ \
        2> >(awk '{print strftime("%F %T")";",$0; fflush()}' >&2) \
         > >(awk '{print strftime("%F %T")";",$0; fflush()}')
}

function test_fail {
if [[ $1 != 0 ]]
then
    cd ${base}
    python bin/track_task.py fail --jobid=${SLURM_JOBID} --finish_time=`date +%s`
    exit $1
fi
}


function get_mem {
    if [[ ${SLURM_CLUSTER_NAME} == 'zeus' ]] ; then
	# default
	mem=64
	if [[ ${SLURM_JOB_PARTITION} == 'workq' ]] ; then
	    mem=128
	fi
    elif [[ ${SLURM_CLUSTER_NAME} == 'galaxy' ]] ; then
	# gpuq
	mem=32
    elif [[ ${SLURM_CLUSTER_NAME} == 'magnus' ]] ; then
	# workq
	mem=64
    else
	echo "Unknown cluster, unable to determine memory assuming 32" >&2
	mem=32
    fi
    echo ${mem}
}

function get_cores {
    if [[ ${SLURM_CLUSTER_NAME} == 'zeus' ]] ; then
	# default
	cores=1
	if [[ ${SLURM_JOB_PARTITION} == 'workq' ]] ; then
	    cores=28
	fi
    elif [[ ${SLURM_CLUSTER_NAME} == 'galaxy' ]] ; then
	# gpuq
	cores=16
    elif [[ ${SLURM_CLUSTER_NAME} == 'magnus' ]] ; then
	# workq
	cores=48
    else
	echo "Unknown cluster, unable to determine cores assuming 16" >&2
	cores=16
    fi
    echo ${cores}
}
