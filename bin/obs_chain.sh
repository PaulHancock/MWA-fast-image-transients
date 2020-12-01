#! /bin/bash

usage()
{
echo "obs_chain.sh [-g group] [-d dep] [-c calid] [-t] obsnum
  -g group   : pawsey group (account) to run as, default=mwasci
  -d dep     : job number for dependency (afterok)
  -c calid   : obsid for calibrator. 
               If a calibration solution exists for calid
               then it will be applied this dataset.
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process" 1>&2;
exit 1;
}

#initialize as empty
account="#SBATCH --account mwasci"
dep=
queue='-p workq'
cluster='-M garrawarla'
calid=
tst=


# parse args and set options
while getopts 'g:d:c:t' OPTION
do
    case "$OPTION" in
	g)
	    account="#SBATCH --account ${OPTARG}"
	    ;;
	d)
	    dep=${OPTARG} ;;
	c)
	    calid=${OPTARG}  ;;
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


# start the real program

if [[ ! -z ${dep} ]]
then
    depend="#SBATCH --dependency=afterok:${dep}"
else
    depend=''
fi


base='/astro/mwasci/phancock/D0009/'

script="${base}queue/chain_${obsnum}.sh"
output="${base}queue/logs/chain_${obsnum}.o%A"
error="${base}queue/logs/chain_${obsnum}.e%A"

# build the sbatch header directives
sbatch="#SBATCH --output=${output}\n#SBATCH --error=${error}\n${queue}\n${cluster}\n${account}\n${depend}\n${extras}"

# join directives and replace variables into the template
cat ${base}/bin/chain.tmpl | sed -e "s:OBSNUM:${obsnum}:" \
                                 -e "s:CALID:${calid}:g" \
                                 -e "s:BASEDIR:${base}:"  \
                                 -e "0,/#! .*/a ${sbatch}" > ${script}
# submit extra jobs when the d/l completes
#cat ${base}/bin/chain_asvo.tmpl | sed "s:CALNAME:${calname}:" | sed "s:CALID:${calid}:" >> ${script}


#sub="sbatch --begin=now+15 ${script}"
if [[ ! -z ${tst} ]]
then
    echo "script is ${script}"
    echo "submit via:"
    echo "${sub}"
    exit 0
fi


# Run script

chmod +x ${script}
${script}

# submit job
##jobid=($(${sub}))
##jobid=${jobid[3]}

# rename the err/output files as we now know the jobid
##error=`echo ${error} | sed "s/%A/${jobid}/"`
##output=`echo ${output} | sed "s/%A/${jobid}/"`
# record submission
##python ${base}/bin/track_task.py queue --jobid=${jobid} --task='chain' --submission_time=`date +%s` --batch_file=${script} \
##                     --obs_id=${obsnum} --stderr=${error} --stdout=${output}

##echo "Submitted ${script} as ${jobid}"
