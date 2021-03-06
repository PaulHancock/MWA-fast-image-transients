#! /bin/bash

usage()
{
echo "obs_flag_tiles.sh [-g group] [-d dep] [-q queue] [-M cluster] [-f flagfile] [-t] obsnum
  -g group   : pawsey group (account) to run as, default=pawsey0345
  -d dep      : job number for dependency (afterok)
  -q queue    : job queue, default=workq
  -M cluster : cluster, default=magnus
  -f flagfile : file to use for flagging
                default is processing/<obsnum>_tiles_to_flag.txt
  -t          : test. Don't submit job, just make the batch file
                and then return the submission command
  obsnum      : the obsid to process" 1>&2;
exit 1;
}

#initialize as empty
account="#SBATCH --account pawsey0345"
dep=
queue='#SBATCH -p workq'
cluster='#SBATCH -M magnus'
flagfile=
tst=
extras=''

# parse args and set options
while getopts 'g:d:q:M:f:t' OPTION
do
    case "$OPTION" in
	g)
	    account="#SBATCH --account ${OPTARG}"
	    ;;
        d)
            dep=${OPTARG}
            ;;
	q)
	    queue="#SBATCH -p ${OPTARG}"
	    ;;
	M)
	    cluster="#SBATCH -M ${OPTARG}"
	    ;;
        f)
            flagfile=${OPTARG}
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

# if obsid is empty then just pring help
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

# if no flag file is given look for a "default" flag file, and use it if it exists
if [[ -z ${flagfile} ]]
then
    flagfile="${base}/processing/${obsnum}_tiles_to_flag.txt"
    if [[ ! -e ${flagfile} ]]
    then
	    flagfile=
    fi
else
    # force an abs path
    flagfile=$( realpath ${flagfile} )
fi

# if a flag file is given make sure it exists
if [[ ! -e ${flagfile} ]] 
then
	echo "flagging file doesn't exist: ${flagfile}"
	echo "not submitting job"
	exit 1
fi

script="${base}queue/flag_tiles_${obsnum}.sh"
output="${base}queue/logs/flag_tiles_${obsnum}.o%A"
error="${base}queue/logs/flag_tiles_${obsnum}.e%A"

# build the sbatch header directives
sbatch="#SBATCH --output=${output}\n#SBATCH --error=${error}\n#SBATCH ${queue}\n#SBATCH ${cluster}\n#SBATCH ${account}\n${depend}\n${extras}"

# join directives and replace variables into the template
cat ${base}/bin/flag_tiles.tmpl | sed -e "s:OBSNUM:${obsnum}:g" \
                                      -e "s:BASEDIR:${base}:g" \
                                      -e "s:FLAGFILE:${flagfile}:g" \
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
python ${base}/bin/track_task.py queue --jobid=${jobid} --task='flag_tiles' --submission_time=`date +%s` --batch_file=${script} \
                     --obs_id=${obsnum} --stderr=${error} --stdout=${output}

echo "Submitted ${script} as ${jobid}"
