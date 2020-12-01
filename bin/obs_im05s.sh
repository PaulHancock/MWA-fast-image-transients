#! /bin/bash

usage()
{
echo "obs_im05s.sh [-g group] [-d dep] [-q queue] [-M cluster] [-s imsize] [-p pixscale] [-P padding] [-t] obsnum
  -g group   : pawsey group (account) to run as, default=pawsey0345
  -d dep     : job number for dependency (afterok)
  -q queue   : job queue, default=workq
  -M cluster : cluster, default=magnus
  -s imsize  : image size will be imsize x imsize pixels, default 4096
  -p pixscale: image pixel scale, default is 32asec
  -P padding : padding value in wsclean, default 1.2
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process" 1>&2;
exit 1;
}

#initialize as empty
account="#SBATCH --account pawsey0345"
dep=
queue='#SBATCH -p workq'
cluster='#SBATCH -M magnus'
imsize=
pixscale=
padding=
tst=
extras=''

# parse args and set options
while getopts 'g:d:q:M:s:p:P:t' OPTION
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
	s)
	    imsize=${OPTARG}
	    ;;
	p)
	    pixscale=${OPTARG}
	    ;;
        P)
            padding=${OPTARG}
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

script="${base}queue/im05s_${obsnum}.sh"
output="${base}queue/logs/im05s_${obsnum}.o%A"
error="${base}queue/logs/im05s_${obsnum}.e%A"

# build the sbatch header directives
sbatch="#SBATCH --output=${output}\n#SBATCH --error=${error}\n${queue}\n${cluster}\n${account}\n${depend}\n${extras}"

# join directives and replace variables into the template
cat ${base}/bin/im05s.tmpl | sed -e "s:OBSNUM:${obsnum}:g" \
                                 -e "s:IMSIZE:${imsize}:g" \
                                 -e "s:SCALE:${pixscale}:g" \
                                 -e "s:PADDING:${padding}:g" \
                                 -e "s:BASEDIR:${base}:g"  \
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
python ${base}/bin/track_task.py queue --jobid=${jobid} --task='im05s' --submission_time=`date +%s` --batch_file=${script} \
                     --obs_id=${obsnum} --stderr=${error} --stdout=${output}

echo "Submitted ${script} as ${jobid}"
