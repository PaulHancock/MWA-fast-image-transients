#! /bin/bash

usage()
{
echo "obs_apply_cal.sh [-d dep] [-q queue] [-M cluster] [-c calid] [-t] obsnum
  -d dep      : job number for dependency (afterok)
  -q queue    : job queue, default=workq
  -M cluster : cluster, default=zeus
  -c calid    : obsid for calibrator.
                processing/calid/calid_*_solutions.bin will be used
                to calibrate if it exists, otherwise job will fail.
  -t          : test. Don't submit job, just make the batch file
                and then return the submission command
  obsnum      : the obsid to process" 1>&2;
exit 1;
}

#initialize as empty
depend=
queue='-p workq'
cluster='-M zeus'
calid=
tst=
extras=

# parse args and set options
while getopts 'd:q:M:c:t' OPTION
do
    case "$OPTION" in
        d)
            depend=${OPTARG}
            ;;
	c)
	    calid=${OPTARG}
	    ;;
	q)
	    queue="-p ${OPTARG}"
	    ;;
	M)
	    cluster="-M ${OPTARG}"
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

set -uo pipefail
# if obsid is empty then just print help

if [[ -z ${obsnum} ]]
then
    usage
fi

# set dependency
if [[ ! -z ${depend} ]]
then
    depend="--dependency=afterok:${dep}"
fi

# set up extra flags that may be needed
if [[ ${cluster} == *"zeus"* ]]; then
    extras="--ntasks=28"
fi

base='/astro/mwasci/phancock/D0009/'

# look for the calibrator solutions file
calfile=($( ls -1 ${base}/processing/${calid}/${calid}*_solutions.bin))
if [[ ${#calfile[@]} -eq 0 ]]
then
    echo "Could not find calibrator file"
    echo "looked for: ${base}/${calid}/${calid}_*_solutions.bin"
    exit 1
else
    calfile=${calfile[0]}
fi


script="${base}queue/apply_cal_${obsnum}.sh"
cat ${base}/bin/apply_cal.tmpl | sed -e "s:OBSNUM:${obsnum}:g" \
                                     -e "s:BASEDIR:${base}:g" \
                                     -e "s:CALFILE:${calfile}:g"  > ${script}

output="${base}queue/logs/apply_cal_${obsnum}.o%A"
error="${base}queue/logs/apply_cal_${obsnum}.e%A"

sub="sbatch --begin=now+15 --output=${output} --error=${error} ${depend} ${cluster} ${extras} ${queue} ${script}"
if [[ ! -z ${tst} ]]
then
    echo "script is ${script}"
    echo "submit via:"
    echo "${sub}"
    exit 0
fi
    
# submit job
jobid=($(${sub}))
jobid=${jobid[3]}

# rename the err/output files as we now know the jobid
error=`echo ${error} | sed "s/%A/${jobid}/"`
output=`echo ${output} | sed "s/%A/${jobid}/"`

# record submission
python ${base}/bin/track_task.py queue --jobid=${jobid} --task='apply_cal' --submission_time=`date +%s` --batch_file=${script} \
                     --obs_id=${obsnum} --stderr=${error} --stdout=${output}

echo "Submitted ${script} as ${jobid}"
