#! /usr/bin/env bash

# SET UP YOUR VARIABLES HERE
base='/path/to/working/directory'


sed -i s:^base=.*:base=${base}:g obs_*.sh