#! /bin/bash

usage()
{
echo "obs_apply_cal.sh [-g group] [-d dep] [-q queue] [-M cluster] [-c calid] [-t] obsnum
  -g group   : pawsey group (account) to run as, default=mwasci
  -d dep      : job number for dependency (afterok)
  -q queue    : job queue, default=workq
  -M cluster : cluster, default=garrawarla
  -c calid    : obsid for calibrator.
                processing/calid/calid_*_solutions.bin will be used
                to calibrate if it exists, otherwise job will fail.
  -t          : test. Don't submit job, just make the batch file
                and then return the submission command
  obsnum      : the obsid to process" 1>&2;
exit 1;
}

#initialize as empty
account="#SBATCH --account mwasci"
dep=
queue='#SBATCH -p workq'
cluster='#SBATCH -M garrawarla'
calid=
tst=
extras=''

# parse args and set options
while getopts 'g:d:q:M:c:t' OPTION
do
    case "$OPTION" in
	g)
	    account="#SBATCH --account ${OPTARG}"
	    ;;
        d)
            dep=${OPTARG}
            ;;
	c)
	    calid=${OPTARG}
	    ;;
	q)
	    queue="#SBATCH -p ${OPTARG}"
	    ;;
	M)
	    cluster="#SBATCH -M ${OPTARG}"
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
if [[ ! -z ${dep} ]]
then
    depend="#SBATCH --dependency=afterok:${dep}"
else
    depend=''
fi


# set up extra flags that may be needed
if [[ ${cluster} == *"zeus"* ]]
then
    extras="#SBATCH --ntasks=28"
else
    extras=''
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
output="${base}queue/logs/apply_cal_${obsnum}.o%A"
error="${base}queue/logs/apply_cal_${obsnum}.e%A"

# build the sbatch header directives
sbatch="#SBATCH --output=${output}\n#SBATCH --error=${error}\n${queue}\n${cluster}\n${account}\n${depend}\n${extras}"

# join directives and replace variables into the template
cat ${base}/bin/apply_cal.tmpl | sed -e "s:OBSNUM:${obsnum}:g" \
                                     -e "s:BASEDIR:${base}:g" \
                                     -e "s:CALFILE:${calfile}:g" \
                                     -e "0,/#! .*/a ${sbatch}" > ${script}

sub="sbatch --begin=now+15 ${script}"
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
