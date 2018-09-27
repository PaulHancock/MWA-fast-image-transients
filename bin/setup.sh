#! /usr/bin/env bash

# SET UP YOUR VARIABLES HERE
base='/astro/mwasci/phancock/RadioSchool/MWA-fast-image-transients/'
account='mwasci'

sed -i -e s:^base=.*:base=${base}:g obs_*.sh
sed -i -e s:account=.*:account=${account}:g *.tmpl asvo_wget.sh
