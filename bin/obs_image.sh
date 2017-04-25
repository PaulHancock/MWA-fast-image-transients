#! bin/bash

obsnum=@1
dep=@2

sed 's/OBSNUM/${obsnum}/g' image.tmpl > image_${obsnum}.sh

depend=""
if [[ ! -z ${dep} ]] 
then
depend="-depend=${dep}"
fi

jobid=`sbatch ${depend} image_${osbnum}.sh`