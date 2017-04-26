#! /bin/bash

obsnum=@1
dep=@2

if [[ ! -z ${obsnum} ]]
then
  echo "OBSNUM required as first arg"
  exit 1
fi

depend=""
if [[ ! -z ${dep} ]]
then
depend="--dependency=afterok:${dep}"
fi

base='/scratch2/mwasci/phancock/D0009/'

script="${base}queue/dl_${obsnum}.sh"
cat dl.tmpl | sed "s/OBSNUM/${obsnum}/g" | sed "s/BASEDIR/${base}/g"  > ${script}

output="${base}queue/logs/image_${obsnum}.o%A"
error="${base}queue/logs/iamge_${obsnum}.e%A"


# submit job
jobid=`sbatch ${script} --begin=now+15 --output=${output} --error=${error} ${depend}`

jobid=${jobid##* }

# record submission
python track_task.py queue --jobid=${jobid} --task='download' --submission_time=`date +%s` --batch_file=${script} \
                     --obs_id=${obsnum} --stderr=${error} --stdout=${output}
