#! /bin/bash

obsnum=$1
dep=$2

if [[ -z ${obsnum} ]]
then
    echo "usage: obs_im28s.sh obs_id [dependency]"
    exit 1
fi

depend=""
if [[ ! -z ${dep} ]] 
then
depend="--dependency=afterok:${dep}"
fi

base='/astro/mwasci/phancock/D0009/'

script="${base}queue/im28s_${obsnum}.sh"
cat ${base}/bin/im28s.tmpl | sed "s:OBSNUM:${obsnum}:g" | sed "s:BASEDIR:${base}:g"  > ${script}

output="${base}queue/logs/im28s_${obsnum}.o%A"
error="${base}queue/logs/im28s_${obsnum}.e%A"

# submit job
jobid=(`sbatch --begin=now+15 --output=${output} --error=${error} ${depend} ${queue} ${script}`)
jobid=${jobid[3]}

# rename the err/output files as we now know the jobid
error=`echo ${error} | sed "s/%A/${jobid}/"`
output=`echo ${output} | sed "s/%A/${jobid}/"`

# record submission
python ${base}/bin/track_task.py queue --jobid=${jobid} --task='im28s' --submission_time=`date +%s` --batch_file=${script} \
                     --obs_id=${obsnum} --stderr=${error} --stdout=${output}

echo "Submitted ${script} as ${jobid}"
