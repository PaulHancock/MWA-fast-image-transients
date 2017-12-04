# A semi-automated pipeline for the reduction of MWA data

The goal of this pipeline is to reduce the data observed as part of the fast
follow up triggers.

The pipeline is written for the Pawsey-Galaxy system.

## Structure
- bin: executable files and template scripts
- db: database location and python scripts for updating the database
- processing: directory in which all the data is processed
- queue: location from which scripts are run
- queue/logs: log files

## scripts and templates
Templates for scripts are `bin/*.tmpl`, these are modified by the `bin/obs_*.sh` scripts and the completed script is then put in `queue/<obsid>_*.sh` and submitted to SLURM.

### obs_dl.sh
Usage: `obs_dl.sh obsid [depend [calid [calname]]]`
- obsid: MWA observation id
- depend: slurm job id on which this task depends (afterok)
- calid: obsid for the corresponding calibrator
- calname: name of the calibrator

uses templates: 
- `dl.tmpl` (obsnum->OBSNUM) 
  - download data
- `chian.tmpl` (calname->CALNAME/calid->CALID)
  - run cotter (always)
  - if calname is set then create a calibration solution from this data and stop
  - if calid is set then apply the calibration solution from calid and then image

If dependency is not passed or has fewer than 4 digits then it is ingored.
That means that you can pass `0` for the dependency and it is ignored.
This is useful for when you want to supply the clibrator ID and name but don't wnat to set a dependencyy.
