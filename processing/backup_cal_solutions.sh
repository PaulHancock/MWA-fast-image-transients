#! /usr/bin/env bash
for d in $( ls -d * ); do mkdir -p ../done/calibration_solutions/${d}; cp ${d}/*.{bin,txt,png} ../done/calibration_solutions/${d}/; done;
