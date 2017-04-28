#! /bin/bash

if [[ $1 ]] && [[ $2 ]]
then
  obsnum=$1
  cal=$2
  dep=$3
else
  echo "obs_calibrate.sh obsnum cal [dep]"
  exit 1
fi

depend=""
if [[ -z ${dep} ]]
then
depend="--dependency=afterok:${dep}"
fi

base='/scratch2/mwasci/phancock/D0009/'

script="${base}queue/calibrate_${obsnum}.sh"
cat ${base}/bin/calibrate.tmpl | sed "s:OBSNUM:${obsnum}:g" | sed "s:BASEDIR:${base}:g" | sed "s:CALBIRATOR:${cal}:g"  > ${script}

output="${base}queue/logs/calibrate_${obsnum}.o%A"
error="${base}queue/logs/calibrate_${obsnum}.e%A"


# submit job
jobid=(`sbatch --begin=now+15 --output=${output} --error=${error} ${depend} ${script}`)
jobid=${jobid[3]}

# rename the err/output files as we now know the jobid
error=`echo ${error} | sed "s/%A/${jobid}/"`
output=`echo ${output} | sed "s/%A/${jobid}/"`

# record submission
python ${base}/bin/track_task.py queue --jobid=${jobid} --task='calibrate' --submission_time=`date +%s` --batch_file=${script} \
                     --obs_id=${obsnum} --stderr=${error} --stdout=${output}
