#! /bin/bash

if [[ $1 ]]
then
  obsnum=$1
  dep=$2
else
  echo "obs_flag_tiles.sh obsnum [dep]"
  exit 1
fi

depend=""
if [[ ! -z ${dep} ]]
then
depend="--dependency=afterok:${dep}"
fi

base='/astro/mwasci/phancock/D0009/'

flagfile="${base}/processing/${obsnum}_tiles_to_flag.txt"
if [[ ! -e ${flagfile} ]]
then
    echo "flagging file doesn't exist: ${flagfile}"
    echo "not submitting job"
    exit 1
fi

script="${base}queue/flag_tiles_${obsnum}.sh"
cat ${base}/bin/flag_tiles.tmpl | sed "s:OBSNUM:${obsnum}:g" | sed "s:BASEDIR:${base}:g" | sed "s:FLAGFILE:${flagfile}:g" > ${script}

output="${base}queue/logs/flag_${obsnum}.o%A"
error="${base}queue/logs/flag_${obsnum}.e%A"


# submit job
jobid=(`sbatch --begin=now+15 --output=${output} --error=${error} ${depend} ${queue} ${script}`)
jobid=${jobid[3]}

# rename the err/output files as we now know the jobid
error=`echo ${error} | sed "s/%A/${jobid}/"`
output=`echo ${output} | sed "s/%A/${jobid}/"`

# record submission
python ${base}/bin/track_task.py queue --jobid=${jobid} --task='flag_tiles' --submission_time=`date +%s` --batch_file=${script} \
                     --obs_id=${obsnum} --stderr=${error} --stdout=${output}

echo "Submitted ${script} as ${jobid}"
