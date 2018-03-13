#! /bin/bash

usage()
{
echo "obs_flag_tiles.sh [-d dep] [-q queue] [-f flagfile] [-t] obsnum
  -d dep      : job number for dependency (afterok)
  -q queue    : job queue, default=gpuq
  -f flagfile : file to use for flagging
                default is processing/<obsnum>_tile_to_flag.txt
  -t          : test. Don't submit job, just make the batch file
                and then return the submission command
  obsnum      : the obsid to process" 1>&2;
exit 1;
}

#initialize as empty                                                                                                                                      
dep=
queue='-p gpuq'
flagfile=
tst=


# parse args and set options                                                                                                                              
while getopts ':td:q:f:' OPTION
do
    case "$OPTION" in
        d)
            dep=${OPTARG}
            ;;
	q)
	    queue="-p ${OPTARG}"
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

depend=""
if [[ ! -z ${dep} ]]
then
depend="--dependency=afterok:${dep}"
fi

base='/astro/mwasci/phancock/D0009/'

if [[ ! -z ${flagfile} ]]
then
    flagfile="${base}/processing/${obsnum}_tiles_to_flag.txt"
fi

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

sub="sbatch --begin=now+15 --output=${output} --error=${error} ${depend} ${queue} ${script}"
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
