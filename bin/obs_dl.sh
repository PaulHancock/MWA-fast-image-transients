#! /bin/bash

obsnum=$1
dep=$2
calid=$3
calname=$4

if [[ -z ${obsnum} ]]
then
  echo "OBSNUM required as first arg"
  exit 1
fi

depend=""
if [[ ${#dep} -gt 4 ]]
then
depend="--dependency=afterok:${dep}"
fi

base='/scratch2/mwasci/phancock/D0009/'

script="${base}queue/dl_${obsnum}.sh"
cat ${base}/bin/dl.tmpl | sed "s:OBSNUM:${obsnum}:" | sed "s:BASEDIR:${base}:"  > ${script}
# submit extra jobs when the d/l completes
cat ${base}/bin/chain.tmpl | sed "s:CALNAME:${calname}:" | sed "s:CALID:${calid}:" >> ${script}


output="${base}queue/logs/dl_${obsnum}.o%A"
error="${base}queue/logs/dl_${obsnum}.e%A"


# submit job
jobid=(`sbatch --begin=now+15 --output=${output} --error=${error} ${depend} ${queue} ${script}`)
jobid=${jobid[3]}

# rename the err/output files as we now know the jobid
error=`echo ${error} | sed "s/%A/${jobid}/"`
output=`echo ${output} | sed "s/%A/${jobid}/"`
# record submission
python ${base}/bin/track_task.py queue --jobid=${jobid} --task='download' --submission_time=`date +%s` --batch_file=${script} \
                     --obs_id=${obsnum} --stderr=${error} --stdout=${output}

echo "Submitted ${script} as ${jobid}"
