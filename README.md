# A semi-automated pipeline for the reduction of MWA data

The goal of this pipeline is to reduce the data observed as part of the fast
follow up triggers.

The pipeline is written for the Pawsey-Galaxy system which uses a SLURM job scheduler.

## Credits
Please credit Paul Hancock, Gemma Anderson and Natasha Hurley-Walker if you use this code, or
incorporate it into your own workflow, as per the [licence](LICENCE).
Please acknowledge the use of this code by citing this repository, and until
we have a publication accepted on this work, we request that we be added as
co-authors on papers that rely on this code.

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

### obs_asvo.sh
Use the [ASVO-mwa](https://asvo.mwatelescope.org) service to do the cotter conversion
and then download the resulting measurement set. This replaces the operation of `obs_dl.sh` and `obs_cotter.sh`.

usage:
```
obs_asvo.sh [-g group] [-d dep] [-c calid] [-n calname] [-s timeav] [-k freqav] [-t] obsnum
  -g group   : pawsey group (account) to run as, default=pawsey0345
  -d dep     : job number for dependency (afterok)
  -c calid   : obsid for calibrator. 
               If a calibration solution exists for calid
               then it will be applied this dataset.
  -n calname : The name of the calibrator.
               Implies that this is a calibrator observation 
               and so calibration solutions will be calculated.
  -m minbad  : The minimum number of bad dipoles requried for a 
               tile to be used (not flagged), default = 2
               NOTE: Currently not supported by asvo-mwa so this is IGNORED.
  -s timeav  : time averaging in sec. default = no averaging
  -k freqav  : freq averaging in KHz. default = no averaging
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process
```
uses templates:
- `asvo_dl_cotter.tmpl` (obsnum->OBSNUM/timeav->TRES/freqav->FRES)
- `chain_asvo.tmpl` (calname->CALNAME/calid->CALID)
  - if calname is set then create a calibration solution from this data and stop
  - if calid is set then apply the calibration solution from calid and then create an image (see `obs_image.sh`)

### obs_peel.sh
Peel a sky model from a given observation.

Usage:
```
obs_infield_cal.sh [-g group] [-d dep] [-q queue] [-M cluster] [-p model] [-n minuvm] [-x maxuvm] [-s steps] [-a] [-t] obsnum
  -g group   : pawsey group (account) to run as, default=pawsey0345
  -d dep     : job number for dependency (afterok)
  -q queue   : job queue, default=workq
  -M cluster : cluster, default=zeus
  -p model   : model to peel, 'AO' format
  -n minuvm  : minuv distance in m
  -x maxuvm  : maxuv distance in m
  -s steps   : number of timesteps to average over, default = all
  -a         : turn ON applybeam, default=assume model has beem applied
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process
```

uses template:
- `peel.tmpl`


### obs_calibrate.sh
Generate calibration solutions for a given observation.
This is done in a two stage process, and results in the final calibration solutions being applied to the dataset.

Usage:
```
obs_calibrate.sh [-g group] [-d dep] [-q queue] [-M cluster] [-n calname] [-a] [-t] obsnum
  -g group   : pawsey group (account) to run as, default=pawsey0345
  -d dep     : job number for dependency (afterok)
  -q queue   : job queue, default=workq
  -M cluster : cluster, default=zeus
  -n calname : The name of the calibrator.
               Implies that this is a calibrator observation 
               and so calibration will be done.
  -a         : turn OFF aoflagger and second iteration of calibration
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process
```

uses templates:
- `calibrate.tmpl` (cal->CALIBRATOR)
  - creates a new calibration solution using the calibrator model corresponding to the given name: file is `<obsnum>_<calmodel>_solutions_initial.bin`
  - plots the calibration solutions
  - applies the calibration solution to the data
  - runs `aoflagger` on the calibrated data
  - creates a new calibration solution: file is `<obsnum>_<calmodel>_solutions.bin`
  - replot the solutions
  

### obs_infield_cal.sh
Generate calibration solutions for an observation using the sources within the
field of view.
The model is generated from the points sources within the FoV that are within
the GLEAM catalogue.
Note that GLEAM does not include all areas of sky, and has some bright sources
cropped.
This calibration is done in a two stage process as per obs_calibrate.sh

Usage:
```
obs_infield_cal.sh [-g group] [-d dep] [-q queue] [-M cluster] [-c catalog] [-a] [-t] obsnum
  -g group   : pawsey group (account) to run as, default=pawsey0345
  -d dep     : job number for dependency (afterok)
  -q queue   : job queue, default=workq
  -M cluster : cluster, default=zeus
  -c catalog : catalogue file to use, default=GLEAM_EGC.fits
  -a         : turn OFF aoflagger and second iteration of calibration
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process
```

uses templates:
- `infield_cal.tmpl` (obsnum->OBSNUM, catalog->CATFILE)

### obs_apply_cal.sh
Apply a pre-existing calibration solution to a measurement set.

Usage:
```
obs_apply_cal.sh [-g group] [-d dep] [-q queue] [-M cluster] [-c calid] [-t] obsnum
  -g group   : pawsey group (account) to run as, default=pawsey0345
  -d dep      : job number for dependency (afterok)
  -q queue    : job queue, default=workq
  -M cluster : cluster, default=zeus
  -c calid    : obsid for calibrator.
                processing/calid/calid_*_solutions.bin will be used
                to calibrate if it exists, otherwise job will fail.
  -t          : test. Don't submit job, just make the batch file
                and then return the submission command
  obsnum      : the obsid to process
```

uses tempaltes:
- `apply_cal.tmpl` (obsnum->OBSNUM, cal->CALOBSID)
  - applies the calibration solution from one data set to another


### obs_image.sh
Image a single observation.

Usage: 
```
obs_image.sh [-g group] [-d dep] [-q queue] [-M cluster] [-s imsize] [-p pixscale] [-c] [-t] obsnum
  -g group   : pawsey group (account) to run as, default=pawsey0345
  -d dep     : job number for dependency (afterok)
  -q queue   : job queue, default=workq
  -M cluster : cluster, default=zeus
  -s imsize  : image size will be imsize x imsize pixels, default 4096
  -p pixscale: image pixel scale, default is 32asec
  -c         : clean image. Default False.
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process
```
uses tempaltes:
- `image.tmpl` (obsnum->OBSNUM/imsize->IMSIZE/scale->SCALE/clean->CLEAN)
  - make a single time/freq image and clean
  - perform primary beam correction on this image.

### obs_im05s.sh 
Image an observation once per 0.5 seconds

Usage:
```
obs_im05s.sh [-g group] [-d dep] [-q queue] [-M cluster] [-s imsize] [-p pixscale] [-t] obsnum
  -g group   : pawsey group (account) to run as, default=pawsey0345
  -d dep     : job number for dependency (afterok)
  -q queue   : job queue, default=workq
  -M cluster : cluster, default=zeus
  -s imsize  : image size will be imsize x imsize pixels, default 4096
  -p pixscale: image pixel scale, default is 32asec
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process
```

uses tempaltes:
- `im05s.tmpl` (obsnum->OBSNUM/imsize->IMSIZE/scale->SCALE)
  - make one image per 0.5sec time interval with no cleaning
  - perform primary beam correction on these images

### obs_im5s.sh
Image an observation once per 5 seconds

Usage:
```
obs_im5s.sh [-g group] [-d dep] [-q queue] [-M cluster] [-s imsize] [-p pixscale] [-t] obsnum
  -g group   : pawsey group (account) to run as, default=pawsey0345
  -d dep     : job number for dependency (afterok)
  -q queue   : job queue, default=workq
  -M cluster : cluster, default=zeus
  -s imsize  : image size will be imsize x imsize pixels, default 4096
  -p pixscale: image pixel scale, default is 32asec
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process
```
uses tempaltes:
- `im5s.tmpl` (obsnum->OBSNUM/imsize->IMSIZE/scale->SCALE)
  - make one image per 5sec time interval with no cleaning
  - perform primary beam correction on these images

### obs_im05s_24c.sh 
Image each of the 24 coarse channels for an observation once per 0.5 seconds

Usage:
```
obs_im05s_24c.sh [-g group] [-d dep] [-q queue] [-M cluster] [-s imsize] [-p pixscale] [-t] obsnum
  -g group   : pawsey group (account) to run as, default=pawsey0345
  -d dep     : job number for dependency (afterok)
  -q queue   : job queue, default=workq
  -M cluster : cluster, default=zeus
  -s imsize  : image size will be imsize x imsize pixels, default 4096
  -p pixscale: image pixel scale, default is 32asec
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process
```

uses tempaltes:
- `im05s_24c_pbcorr.tmpl` (obsnum->OBSNUM/imsize->IMSIZE/scale->SCALE)
  - makes 24 images (one for each coarse channel) per 0.5sec time interval with no cleaning
  - perform primary beam correction on these images

### obs_im28s.sh
Image an observation once per 28 seconds

Usage:
```
obs_im28s.sh [-g group] [-d dep] [-q queue] [-M cluster] [-s imsize] [-p pixscale] [-c] [-t] obsnum
  -g group   : pawsey group (account) to run as, default=pawsey0345
  -d dep     : job number for dependency (afterok)
  -q queue   : job queue, default=workq
  -M cluster : cluster, default=zeus
  -s imsize  : image size will be imsize x imsize pixels, default 4096
  -p pixscale: image pixel scale, default is 32asec
  -c         : clean image. Default False.
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process
```

uses tempaltes:
- `im28s.tmpl` (obsnum->OBSNUM/imsize->IMSIZE/scale->SCALE/clean->CLEAN)
  - make one image per 28sec time interval and clean
  - perform primary beam correction on these images

### obs_flag.sh
Perform flagging on a measurement set.
This consists of running `aoflagger` on the dataset.


Usage:
```
obs_flag.sh [-g group] [-d dep] [-q queue] [-M cluster] [-t] obsnum
  -g group   : pawsey group (account) to run as, default=pawsey0345
  -d dep      : job number for dependency (afterok)
  -q queue    : job queue, default=workq
  -M cluster : cluster, default=zeus
  -t          : test. Don't submit job, just make the batch file
                and then return the submission command
  obsnum      : the obsid to process
```

uses tempaltes:
- `flag.tmpl` (obsnum->OBSNUM)

No job is submitted if the flagging file doesn't exist so this script is safe to include always.

### obs_flag_tiles.sh
Flags a single observation using the corresponding flag file.
The flag file should contain a list of integers being the tile numbers (all on one line, space separated).
This does *not* run `aoflagger`.


usage: 
```
obs_flag_tiles.sh [-g group] [-d dep] [-q queue] [-M cluster] [-f flagfile] [-t] obsnum
  -g group   : pawsey group (account) to run as, default=pawsey0345
  -d dep      : job number for dependency (afterok)
  -q queue    : job queue, default=workq
  -M cluster : cluster, default=zeus
  -f flagfile : file to use for flagging
                default is processing/<obsnum>_tiles_to_flag.txt
  -t          : test. Don't submit job, just make the batch file
                and then return the submission command
  obsnum      : the obsid to process
```

uses templates:
- `flag_tiles.tmpl` (obsnum->OBSNUM, flagfile->FLAGFILE)

### obs_sfind.sh
Run source finding on all the 2m, 28s, and 0.5s cadence stokes I, beam
corrected images for a given observation. 
(Or at least the subset which exist).

usage:
```
obs_sfind.sh [-g group] [-d dep] [-q queue] [-M cluster] [-t] obsnum
  -g group   : pawsey group (account) to run as, default=pawsey0345
  -d dep     : job number for dependency (afterok)
  -q queue   : job queue, default=workq
  -M cluster : cluster, default=zeus
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process
```

uses tempaltes:
- `sfind.tmpl` (obsnum->OBSNUM)
  - run `BANE` and then `aegean` on each of the images

### obs_diff.sh
Create difference images for adjacent pairs of 0.5sec images.

usage:
```
obs_diff.sh [-g group] [-d dep] [-q queue] [-M cluster] [-t] obsnum
  -g group   : pawsey group (account) to run as, default=pawsey0345
  -d dep     : job number for dependency (afterok)
  -q queue   : job queue, default=workq
  -M cluster : cluster, default=zeus
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process
```

uses template:
- `diff.tmpl` (obsnum->OBSNUM)
  - create difference images
