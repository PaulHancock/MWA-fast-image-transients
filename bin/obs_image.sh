#! bash

obsnum=@1
dep=@2

sed 's/OBSNUM/${obsnum}/g' image.tmpl > ../queue/image_${obsnum}.sh

depend=""
if [[ ! -z ${dep} ]] 
then
depend="-depend=${dep}"
fi

# submit job
jobid=`sbatch ${depend} ../queue/image_${osbnum}.sh`