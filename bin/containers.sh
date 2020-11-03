# Set up the containers to be pass through by default
Creduce=''
Ccotter=''
Cmwalib=''
Crobbie=''
Cwsclean=''

# If we are on garrawarla then set up the containers
if [[ ${SLURM_CLUSTER_NAME} == 'garrawarla' ]] ; then
  container_base="/pawsey/mwa/singularity"
  container_exec="singularity exec -B $PWD"
  
  # need to super-hack the path to make sure that the .h5 beam file is found within the right python path within the container
  Creduce="${container_exec} -B /pawsey/mwa:/usr/lib/python3/dist-packages/mwapy/data ${container_base}/mwa-reduce/mwa-reduce.img"
  # these work nice as is
  Ccotter="${container_exec} ${container_base}/cotter/cotter_latest.sif"
  Cmwalib="${container_exec} ${container_base}/pymwalib/pymwalib_latest.sif"
  Crobbie="${container_exec} ${container_base}/robbie/robbie-next.sif"
  Cwsclean="${container_exec} ${container_base}/wsclean/wsclean_2.9.2.img"
fi

