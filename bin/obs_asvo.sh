#! /bin/bash

usage()
{
echo "obs_asvo.sh [-d dep] [-c calid] [-n calname] [-s timeav] [-k freqav] [-t] obsnum
  -d dep     : job number for dependency (afterok)
  -c calid   : obsid for calibrator. 
               If a calibration solution exists for calid
               then it will be applied this dataset.
  -n calname : The name of the calibrator.
               Implies that this is a calibrator observation 
               and so calibration solutions will be calculated.
  -m minbad  : The minimum number of bad dipoles requried for a 
               tile to be used (not flagged), default = 2
  -s timeav  : time averaging in sec. default = no averaging
  -k freqav  : freq averaging in KHz. default = no averaging
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process" 1>&2;
exit 1;
}

#initialize as empty
calid=
calname=
minbad=2
dep=
tst=
timeav=
freqav=

# parse args and set options
while getopts ':td:c:n:m:s:k:' OPTION
do
    case "$OPTION" in
	d)
	    dep=${OPTARG} ;;
	c)
	    calid=${OPTARG}  ;;
	n)
	    calname=${OPTARG} ;;
	m)
	    minbad=${OPTARG} ;;
	s)
	    timeav=${OPTARG} ;;
	k)
	    freqav=${OPTARG} ;;
	t)
	    tst=1 ;;
	? | : | h)
	    usage ;;
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

if [[ -z ${timeav} ]]
then
    timeav=0.5
fi

if [[ -z ${freqav} ]]
then
    freqav=40
fi

# start the real program

if [[ ! -z ${dep} ]]
then
    depend="--dependency=afterok:${dep}"
fi


base='/astro/mwasci/phancock/D0009/'

script="${base}queue/asvo_${obsnum}.sh"
cat ${base}/bin/asvo_dl_cotter.tmpl | sed -e "s:OBSNUM:${obsnum}:" \
                                          -e "s:TRES:${timeav}:g" \
                                          -e "s:FRES:${freqav}:g" \
                                          -e "s:BASEDIR:${base}:"  > ${script}
# submit extra jobs when the d/l completes
cat ${base}/bin/chain_asvo.tmpl | sed "s:CALNAME:${calname}:" | sed "s:CALID:${calid}:" >> ${script}


output="${base}queue/logs/asvo_${obsnum}.o%A"
error="${base}queue/logs/asvo_${obsnum}.e%A"

sub="sbatch --begin=now+15 --output=${output} --error=${error} ${depend}  ${script}"
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
python ${base}/bin/track_task.py queue --jobid=${jobid} --task='asvo' --submission_time=`date +%s` --batch_file=${script} \
                     --obs_id=${obsnum} --stderr=${error} --stdout=${output}

echo "Submitted ${script} as ${jobid}"
