#!/bin/bash -l
#SBATCH --account=mwasci
#SBATCH --partition=gpuq
#SBATCH --time=06:00:00
#SBATCH --nodes=1
#SBATCH --mem=32gb
#SBATCH --output=/scratch2/mwasci/phancock/G0026/queue/make_freq_cubes.sh.o%A
#SBATCH --error=/scratch2/mwasci/phancock/G0026/queue/make_freq_cubes.sh.e%A

aprun='aprun -n 1 -d 8 -b'

cd /scratch2/mwasci/phancock/G0026/ALOUETTE_noflagging
$aprun python ../bin/imstack.py
