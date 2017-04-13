#!/bin/bash -l
#SBATCH --account=mwasci
#SBATCH --partition=gpuq
#SBATCH --time=20:00:00
#SBATCH --nodes=1
#SBATCH --mem=32gb
#SBATCH --output=/scratch2/mwasci/phancock/G0026/queue/make_images.sh.o%A
#SBATCH --error=/scratch2/mwasci/phancock/G0026/queue/make_images.sh.e%A

aprun='aprun -n 1 -d 8 -b'

# Get the new version of Aegean
#export PATH=/group/mwaops/phancock/code/Aegean:$PATH
#export PYTHONPATH=/group/mwaops/phancock/code/Aegean:$PYTHONPATH

datadir=/scratch2/mwasci/phancock/G0026

cd $datadir

obsnum=1102604896
ncpus=8

$aprun wsclean -name ALOUETTE_noflagging/${obsnum}-sm -size 320 320 \
               -weight briggs 0.5 -mfsweighting -scale 25.0amin \
               -pol I -niter 0 \
               -interval 0 232 -intervalsout 232 \
               -channelrange 0 768 -channelsout 768 \
               -maxuv-l 32 -minuv-l 0.03 -smallinversion -j ${ncpus} \
               satellite/${obsnum}/${obsnum}_norfi.ms
               #-joinchannels -stopnegative -joinpolarizations -niter 4000 -threshold 1.0 \ # don't clean
