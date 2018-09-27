#! /usr/bin/env bash

# SET UP YOUR VARIABLES HERE
base='/astro/mwasci/phancock/RadioSchool/MWA-fast-image-transients/'


sed -i s:^base=.*:base=${base}:g obs_*.sh
