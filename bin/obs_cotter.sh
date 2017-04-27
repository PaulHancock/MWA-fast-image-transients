#! /bin/bash

obsnum=$1
tres=$2
fres=$3
dep=$4

if [[ -z ${obsnum} ]]
then
  echo "OBSNUM required as first arg"
  exit 0
fi

# set default values if not given
if [[ -z ${fres} ]]
then
	fres=40
fi
if [[ -z ${tres} ]]
then
	tres=0.5
fi

depend=""
if [[ -z ${dep} ]]
then
depend="--dependency=afterok:${dep}"
fi

base='/scratch2/mwasci/phancock/D0009/'

script="${base}queue/cotter_${obsnum}.sh"
cat ${base}/bin/cotter.tmpl | sed 's:OBSNUM:${obsnum}:g' | sed 's:TRES:${tres}:g' | sed 's:FRES:${fres}:g' | sed "s:BASEDIR:${base}:g"  > ${script}

output="${base}queue/logs/cotter_${obsnum}.o%A"
error="${base}queue/logs/cotter_${obsnum}.e%A"

# submit job
jobid=(`sbatch ${script} --begin=now+15 --output=${output} --error=${error} ${depend}`)
jobid=${jobid[3]}

# rename the err/output files as we now know the jobid
error=`echo ${error} | sed "s/%A/${jobid}/"`
output=`echo ${output} | sed "s/%A/${jobid}/"`

# record submission
python ${base}/bin/track_task.py queue --jobid=${jobid} --task='cotter' --submission_time=`date +%s` --batch_file=${script} \
                     --obs_id=${obsnum} --stderr=${error} --stdout=${output}
