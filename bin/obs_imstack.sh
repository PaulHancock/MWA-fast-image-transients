#! /bin/bash

obsnum=@1
dep=@2

sed 's/OBSNUM/${obsnum}/g' image.tmpl > ../queue/image_${obsnum}.sh

depend=""
if [[ ! -z ${dep} ]] 
then
depend="--dependancy=afterok:${dep}"
fi

base='/scratch2/mwasci/phancock/D0009/'

script="${base}queue/stack_${obsnum}.sh"
cat image.tmpl | sed 's/OBSNUM/${obsnum}/g' | sed "s/BASEDIR/${base}/g"  > ${script}

output="${base}queue/logs/stack_${obsnum}.o%A"
error="${base}queue/logs/stack_${obsnum}.e%A"

# submit job
jobid=`sbatch ${script} --begin=now+15 --output=${output} --error=${error} ${depend}`

jobid=${jobid##* }

# record submission
python track_task.py queue --jobid=${jobid} --task='stack' --submission_time=`date +%s` --batch_file=${script} \
                     --obs_id=${obsnum} --stderr=${error} --stdout=${output}
