#! /bin/bash

obsnum=$1
dep=$2

if [[ -z ${obsnum} ]]
then
    echo "usage: obs_image.sh obs_id [dependency]"
    exit 1
fi

depend=""
if [[ ! -z ${dep} ]] 
then
depend="--dependency=afterok:${dep}"
fi

base='/scratch2/mwasci/phancock/D0009/'

script="${base}queue/image_${obsnum}.sh"
cat ${base}/bin/image.tmpl | sed "s:OBSNUM:${obsnum}:g" | sed "s:BASEDIR:${base}:g"  > ${script}

output="${base}queue/logs/image_${obsnum}.o%A"
error="${base}queue/logs/image_${obsnum}.e%A"

# submit job
jobid=(`sbatch --begin=now+15 --output=${output} --error=${error} ${depend} ${script}`)
jobid=${jobid[3]}

# rename the err/output files as we now know the jobid
error=`echo ${error} | sed "s/%A/${jobid}/"`
output=`echo ${output} | sed "s/%A/${jobid}/"`

# record submission
python ${base}/bin/track_task.py queue --jobid=${jobid} --task='image' --submission_time=`date +%s` --batch_file=${script} \
                     --obs_id=${obsnum} --stderr=${error} --stdout=${output}

echo "Submitted ${script} as ${jobid}"
