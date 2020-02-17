#! /bin/bash

obsnum=$1
dep=$2

depend=""
if [[ -z ${dep} ]]
then
    depend="#SBATCH --dependency=afterok:${dep}"
fi

base='/astro/mwasci/phancock/D0009/'

script="${base}queue/stack_${obsnum}.sh"
output="${base}queue/logs/stack_${obsnum}.o%A"
error="${base}queue/logs/stak_${obsnum}.e%A"

# build the sbatch header directives
sbatch="#SBATCH --output=${output}\n#SBATCH --error=${error}\n#SBATCH ${queue}\n#SBATCH ${cluster}\n#SBATCH ${account}\n${depend}\n${extras}"

# join directives and replace variables into the template
cat ${base}/bin/image.tmpl | sed -e "s:OBSNUM:${obsnum}:g" \
                                 -e "s:BASEDIR:${base}:g"  \
                                 -e "0,/#! .*/a ${sbatch}" > ${script}

# submit job
jobid=(`sbatch --begin=now+15 ${script}`)
jobid=${jobid[3]}

# rename the err/output files as we now know the jobid
error=`echo ${error} | sed "s/%A/${jobid}/"`
output=`echo ${output} | sed "s/%A/${jobid}/"`

# record submission
python ${base}/bin/track_task.py queue --jobid=${jobid} --task='stack' --submission_time=`date +%s` --batch_file=${script} \
                     --obs_id=${obsnum} --stderr=${error} --stdout=${output}

echo "Submitted ${script} as ${jobid}"
