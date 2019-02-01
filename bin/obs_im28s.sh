#! /bin/bash

usage()
{
echo "obs_im28s.sh [-d dep] [-q queue] [-M cluster] [-s imsize] [-p pixscale] [-c] [-t] obsnum
  -d dep     : job number for dependency (afterok)
  -q queue   : job queue, default=workq
  -M cluster : cluster, default=zeus
  -s imsize  : image size will be imsize x imsize pixels, default 4096
  -p pixscale: image pixel scale, default is 32asec
  -c         : clean image. Default False.
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process" 1>&2;
exit 1;
}

#initialize as empty
dep=
queue='-p workq'
cluster='-M zeus --ntasks=28'
imsize=
pixscale=
clean=
tst=

# parse args and set options
while getopts 'd:q:M:s:p:ct' OPTION
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
	s)
	    imsize=${OPTARG}
	    ;;
	p)
	    pixscale=${OPTARG}
	    ;;
	c)
	    clean="yes"
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


if [[ ! -z ${dep} ]]
then
    depend="--dependency=afterok:${dep}"
fi

base='/astro/mwasci/phancock/D0009/'

script="${base}queue/im28s_${obsnum}.sh"
cat ${base}/bin/im28s.tmpl | sed -e "s:OBSNUM:${obsnum}:g" \
                                 -e "s:BASEDIR:${base}:g"  \
                                 -e "s:IMSIZE:${imsize}:g" \
                                 -e "s:SCALE:${pixscale}:g" \
                                 -e "s:CLEAN:${clean}:g" > ${script}

output="${base}queue/logs/im28s_${obsnum}.o%A"
error="${base}queue/logs/im28s_${obsnum}.e%A"

sub="sbatch --begin=now+15 --output=${output} --error=${error} ${depend} ${cluster} ${queue} ${script}"
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
python ${base}/bin/track_task.py queue --jobid=${jobid} --task='im28s' --submission_time=`date +%s` --batch_file=${script} \
                     --obs_id=${obsnum} --stderr=${error} --stdout=${output}

echo "Submitted ${script} as ${jobid}"
