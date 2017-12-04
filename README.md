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
This is useful for when you want to supply the clibrator ID and name but don't wnat to set a dependency.

### obs_cotter.sh
Usage: `obs_cotter.sh obsid [depend]`
- obsid: MWA observation id
- depend: slurm job id on which this task depends (afterok)

uses templates:
- `cotter.tmpl` (obsnum->OBSNUM)
  - run cotter to convert gpubox .fits files into a measurement set apply online flag files if present
  
 ### obs_calibrate.sh
 Usage: `obs_calibrat.sh obsnum cal [depend]`
- obsid: MWA observation id
- cal: calibrator name
- depend: slurm job id on which this task depends (afterok)

uses templates:
- `calibrate.tmpl` (cal->CALIBRATOR)
  - creates a new calibration solution using the calibrator model corresponding to the given name: file is <obsnum>_<calmodel>_solutions_initial.bin
  - plots the calibration solutions
  - applies the calibration solution to the data
  - runs aoflagger on the calibrated data
  - creates a new calibration solution: file is <obsnum>_<calmodel>_solutions.bin
  - replot the solutions
  
### obs_apply_cal.sh
Usage: `obs_apply_cal.sh obsnum cal [depend]`
- obsid: MWA observation id
- cal: calibrator obsid
- depend: slurm job id on which this task depends (afterok)

uses tempaltes:
- `apply_cal.tmpl` (obsnum->OBSNUM, cal->CALOBSID)
  - applies the calibration solution from one data set to another


