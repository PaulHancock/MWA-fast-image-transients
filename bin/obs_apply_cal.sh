#! /bin/bash

if [[ $1 ]] && [[ $2 ]]
then
  obsnum=@1
  cal=@2
  dep=@3
else
  echo "obs_apply_cal.sh obsnum cal [dep]"
  exit 1
fi

depend=""
if [[ ! -z ${dep} ]]
then
depend="--dependency=afterok:${dep}"
fi

base='/scratch2/mwasci/phancock/D0009/'

script="${base}queue/apply_cal_${obsnum}.sh"
cat apply_cal.tmpl | sed "s/OBSNUM/${obsnum}/g" | sed "s/BASEDIR/${base}/g" | sed "s/CALOBSID/${cal}/g"  > ${script}

output="${base}queue/logs/apply_cal_${obsnum}.o%A"
error="${base}queue/logs/apply_cal_${obsnum}.e%A"


# submit job
jobid=`sbatch ${script} --begin=now+15 --output=${output} --error=${error} ${depend}`

jobid=${jobid##* }

# record submission
python track_task.py queue --jobid=${jobid} --task='apply_cal' --submission_time=`date +%s` --batch_file=${script} \
                     --obs_id=${obsnum} --stderr=${error} --stdout=${output}
