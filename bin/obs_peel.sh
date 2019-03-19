#! /bin/bash
usage()
{
echo "obs_infield_cal.sh [-d dep] [-q queue] [-M cluster] [-p model] [-n minuvm] [-x maxuvm] [-s steps] [-a] [-t] obsnum
  -d dep     : job number for dependency (afterok)
  -q queue   : job queue, default=workq
  -M cluster : cluster, default=zeus
  -p model   : model to peel, 'AO' format
  -n minuvm  : minuv distance in m
  -x maxuvm  : maxuv distance in m
  -s steps   : number of timesteps to average over, default = all
  -a         : turn ON applybeam, default=assume model has beem applied
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process" 1>&2;
exit 1;
}

#initialize as empty
dep=
queue='-p gpuq'
cluster='-M zeus'
model=
minuvm=
maxuvm=
ntsteps=
caldatacolumn='-datacolumn DATA'
dobeam=
tst=

base='/astro/mwasci/phancock/D0009/'
extras=

# parse args and set options
while getopts 'd:q:M:p:n:x:s:at' OPTION
do
    case "$OPTION" in
	d)
	    dep=${OPTARG}
	    ;;
	q)
	    queue="-p ${OPTARG}"
	    ;;
	M)
	    cluster="-M ${OPTARG}"
	    ;;
	p)
	    model=${OPTARG}
	    ;;
	n)
	    minuvm=${OPTARG}
	    ;;
	x)
	    maxuvm=${OPTARG}
	    ;;
	s)
	    ntsteps=${OPTARG}
	    ;;
	a)
	    dobeam=1
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

set -u

# if obsid is empty then just pring help
if [[ -z ${obsnum} ]]
then
    usage
fi

# set dependency
if [[ ! -z ${dep} ]]
then
    dep="--dependency=afterok:${dep}"
fi

# set up extra flags that may be needed
if [[ ${cluster} == *"zeus"* ]]; then
    extras="--ntasks=28"
fi

# start the real program
script="${base}queue/peel_${obsnum}.sh"
cat ${base}/bin/peel.tmpl | sed -e "s:OBSNUM:${obsnum}:g" \
                                -e "s:BASEDIR:${base}:g" \
                                -e "s:MODEL:${model}:g" \
                                -e "s:CALDATACOLUMN:${caldatacolumn}:g" \
                                -e "s:MINUVM:${minuvm}:g" \
                                -e "s:MAXUVM:${maxuvm}:g" \
                                -e "s:NTSTEPS:${ntsteps}:g" \
                                -e "s:DOBEAM:${dobeam}:g" > ${script}

output="${base}queue/logs/peel_${obsnum}.o%A"
error="${base}queue/logs/peel_${obsnum}.e%A"

sub="sbatch --begin=now+15 --output=${output} --error=${error} ${dep} ${cluster} ${extras} ${queue} ${script}"

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
python ${base}/bin/track_task.py queue --jobid=${jobid} --task='peel' \
                  --submission_time=`date +%s` --batch_file=${script} \
                  --obs_id=${obsnum} --stderr=${error} --stdout=${output}

echo "Submitted ${script} as ${jobid}"
