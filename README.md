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
- done: location for final data products (images, catalogues)

## scripts and templates
Templates for scripts are `bin/*.tmpl`, these are modified by the `bin/obs_*.sh` scripts and the completed script is then put in `queue/<obsid>_*.sh` and submitted to SLURM.

## track_task.py
Used by the following scripts to track the submission/start/finish/fail of each of the jobs.
Not intended for use outside of these scripts.

## process_grb.sh
Usage: `process_grb.sh grbname`
- grbname: The name of the GRB as per the database (eg, GRB110715A) which may differ from the official name due to lazyness in implementing the naming strategy.

Currently:
- download the calibrator data
- make calibration solution
- for each of the observations of this GRB:
  - download, cotter and apply calibration solutions with `obs_dl.sh` (+ `chain.tmpl`)

Eventually:
- as above then
- for each observation:
  - image
  - source find
  - push images/catalogues to the `done` directory
  
Do the above in a smart manner that will not process GRBs that are flagged as junk or broken.
Start the processing at the required step by inspecting the db for previous jobs.
Restart broken jobs.


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
  - if calid is set then apply the calibration solution from calid and then create an image (see `obs_image.sh`)

If dependency is not passed or has fewer than 4 digits then it is ingored.
That means that you can pass `0` for the dependency and it is ignored.
This is useful for when you want to supply the clibrator ID and name but don't wnat to set a dependency.

### obs_cotter.sh
usage:
```
obs_cotter.sh [-d dep] [-q queue] [-t] obsnum
  -d dep      : job number for dependency (afterok)
  -q queue    : job queue, default=gpuq
  -t          : test. Don't submit job, just make the batch file
                and then return the submission command
  obsnum      : the obsid to process
```

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


### obs_image.sh
Usage: `obs_image.sh obsnum [depend]`
- obsid: MWA observation id
- depend: slurm job id on which this task depends (afterok)

uses tempaltes:
- `image.tmpl` (obsnum->OBSNUM)
  - make a single time/freq image and clean
  - perform primary beam correction on this image.

### obs_im05s.sh
Usage: `obs_im05s.sh obsnum [depend]`
- obsid: MWA observation id
- depend: slurm job id on which this task depends (afterok)

uses tempaltes:
- `im05s.tmpl` (obsnum->OBSNUM)
  - make one image per 0.5sec time interval with no cleaning
  - perform primary beam correction on these images


### obs_im28s.sh
Usage: `obs_im28s.sh obsnum [depend]`
- obsid: MWA observation id
- depend: slurm job id on which this task depends (afterok)

uses tempaltes:
- `im28s.tmpl` (obsnum->OBSNUM)
  - make one image per 28sec time interval and clean
  - perform primary beam correction on these images

### obs_flag.sh
Usage: `obs_flag.sh obsnum [depend]`
- obsid: MWA observation id
- depend: slurm job id on which this task depends (afterok)

uses tempaltes:
- `flag.tmpl` (obsnum->OBSNUM)
  - if `processing/<obsnum>/tiles_to_flag.txt` exists then the tiles listed are flagged.

No job is submitted if the flagging file doesn't exist so this script is safe to include always.

### obs_flag_tiles.sh
Flags a single observation using the corresponding flag file. The flag file
format is `<obsid>_tiles_to_flag.txt` (different from above), and should
contain a list of integers being the tile numbers (all on one line, space separated).

usage: 
```
obs_flag_tiles.sh [-d dep] [-f flagfile] [-t] obsnum
  -d dep      : job number for dependency (afterok)
  -f flagfile : file to use for flagging
                default is processing/<obsnum>_tile_to_flag.txt
  -t          : test. Don't submit job, just make the batch file
                and then return the submission command
  obsnum      : the obsid to process
```

uses templates:
- `flag_tiles.tmpl` (obsnum->OBSNUM)

### obs_sfind.sh <<UNDER DEVELOPMENT/TESTING>>
Usage: `obs_flag.sh obsnum [depend]`
- obsid: MWA observation id
- depend: slurm job id on which this task depends (afterok)

uses tempaltes:
- `sfind.tmpl` (obsnum->OBSNUM)
  - run `BANE` and then `aegean` on each of the images
  

