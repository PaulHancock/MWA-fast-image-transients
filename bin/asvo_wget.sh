#! /bin/bash -l
#SBATCH --export=NONE
#SBATCH -M zeus
#SBATCH -p copyq
#SBATCH --account=courses01
#SBATCH --time=12:00:00
#SBATCH --nodes=1

base=/group/courses01/${USER}/
datadir=${base}/processing
# target
#obsnum=1061674824
# calibrator
obsnum=1061673704

# setup a clean environment
source /group/mwa/software/module-reset.sh
module load mwapy
module load manta-ray-client

set -x

{
# start task
mkdir -p ${datadir}/${obsnum}
cd ${datadir}/${obsnum}

outfile="${obsnum}_ms.zip"
msfile="${obsnum}.ms"

if [[ -e "${outfile}" ]]
then
    echo "${outfile} exists, not downloading again"
elif [[ -e "${msfile}" ]]
then
    echo "${msfile} exists, not downloading again"
else
    wget -O ${obsnum}_ms.zip "https://asvo.mwatelescope.org:8778/api/download?job_id=57209&file_name=1061673704_ms.zip"
    # wget -O ${obsnum}_ms.zip "https://asvo.mwatelescope.org:8778/api/download?job_id=56678&file_name=1061674824_ms.zip"
    # NOTE THAT THE LINK IS OF THIS FORMAT:
    # https://asvo.mwatelescope.org:8778/api/download?job_id=56678&file_name=1061674824_ms.zip
    #                                                        ^^job id        ^^^obsid
    # since the conversion job hasn't finished you can either
    # figuer out the link for *your* job using the above
    # - or - 
    # just use the link for my job (since it's unsecured)
fi

# unzip the file and delete the zip
if [[ -e "${outfile}" ]]
then
    unzip -n ${outfile}
    rm ${outfile}
fi
} 2> >(awk '{print strftime("%F %T")";",$0; fflush()}' >&2) > >(awk '{print strftime("%F %T")";",$0; fflush()}')
