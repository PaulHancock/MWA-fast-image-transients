#! /usr/bin/env bash
for d in $( ls -d [0-9]*[0-9] ); do mkdir -p ../done/calibration_solutions/${d}; cp ${d}/*.{bin,txt,png} ../done/calibration_solutions/${d}/; done;
