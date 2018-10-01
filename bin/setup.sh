#! /usr/bin/env bash

# SET UP YOUR VARIABLES HERE
base='/group/courses01/${USER}/mwa'
account='courses01'
reservation='courseq'
sed -i -e s:^base=.*:base=${base}:g obs_*.sh
sed -i -e s:account=.*:account=${account}\n#SBATCH --reservation=${reservation}:g *.tmpl asvo_wget.sh
