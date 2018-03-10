#! /bin/bash

usage()
{
echo "obs_cotter.sh [-d dep] [-q queue] [-t] obsnum
  -d dep      : job number for dependency (afterok)
  -q queue    : job queue, default=gpuq
  -t          : test. Don't submit job, just make the batch file
                and then return the submission command
  obsnum      : the obsid to process" 1>&2;
exit 1;
}

#initialize as empty
dep=
tst=
queue='-p gpuq'

# parse args and set options
while getopts ':td:' OPTION
do
    case "$OPTION" in
        d)
            dep=${OPTARG}
            ;;
	q)
	    queue="-p ${OPTARG}"
	    ;;
        t)
            tst=1
            ;;
        ? | : | h)
            usage
            ;;
  esac
done

# set the obsid to be the first non option
shift  "$(($OPTIND -1))"
obsnum=$1

# if obsid is empty then just print help

if [[ -z ${obsnum} ]]
then
    usage
fi

fres=40
tres=0.5

if [[ ! -z ${dep} ]]
then
depend="--dependency=afterok:${dep}"
fi

base='/astro/mwasci/phancock/D0009/'

script="${base}queue/cotter_${obsnum}.sh"
cat ${base}/bin/cotter.tmpl | sed "s:OBSNUM:${obsnum}:g" | sed "s:TRES:${tres}:g" | sed "s:FRES:${fres}:g" | sed "s:BASEDIR:${base}:g"  > ${script}

output="${base}queue/logs/cotter_${obsnum}.o%A"
error="${base}queue/logs/cotter_${obsnum}.e%A"


sub="sbatch --begin=now+15 --output=${output} --error=${error} ${depend} ${queue} ${script}"
if [[ ! -z ${tst} ]]
then
    echo "script is ${script}"
    echo "submit via:"
    echo "${sub}"
    exit 0
fi



# submit job
jobid=($(S{sub}))
jobid=${jobid[3]}

# rename the err/output files as we now know the jobid
error=`echo ${error} | sed "s/%A/${jobid}/"`
output=`echo ${output} | sed "s/%A/${jobid}/"`

# record submission
python ${base}/bin/track_task.py queue --jobid=${jobid} --task='cotter' --submission_time=`date +%s` --batch_file=${script} \
                     --obs_id=${obsnum} --stderr=${error} --stdout=${output}

echo "Submitted ${script} as ${jobid}"
