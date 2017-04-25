#! bin/bash

obsnum=@1


sed 's/OBSNUM/${obsnum}/g' dl.tmpl > ../queue/dl_${obsnum}.sh


# submit job
jobid=`sbatch image_${osbnum}.sh`
# retun jobid