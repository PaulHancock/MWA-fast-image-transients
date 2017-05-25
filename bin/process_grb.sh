#! /bin/bash

grb=$1

if [[ ! ${grb} ]]
then
    echo "get_cal.sh grbname"
    exit 1
fi

# determine the obsid for the calibrator associated with this GRB
res=`sqlite3 db/MWA-GRB.sqlite "SELECT obs_id, obsname FROM observation WHERE grb=\"${grb}\" AND calibration" | tr "|" " "`
calid=${res[0]}
calname=${res[1]}

solutions=`ls processing/${obsid}/${obsid}*solutions.bin`
if [[ $? ]]
then
    # the solutions don't exist so we must make them
    echo "Making calibration solutions"
    ./bin/obs_dl.sh ${calid}
    exit $?
fi

echo "Solutions exist, proceccing target observations"
obsids=(`sqlite3 db/MWA-GRB.sqlite "SELECT obs_id FROM observation WHERE grb=\"${grb}\" AND NOT calibration"`)
for id in obsids
do
    # do all the processing for this obsid
    ./bin/obs_dl.sh ${obsid} 0 ${calid} ${calname}
done
    