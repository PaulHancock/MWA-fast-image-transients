function tag {
    $@ \
        2> >(awk '{print strftime("%F %T")";",$0; fflush()}') \
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
