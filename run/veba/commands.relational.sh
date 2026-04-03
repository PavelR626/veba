#!/usr/bin/env bash

# Setup
module="relational"
job_name="${module}"

# Run
cmd="build-relational-database.py -i ../../Analysis/veba_output/essentials/ -o ../../Analysis/veba_output/essentials/veba.db"
/usr/bin/time -v ${cmd} 2> logs/${job_name}.e 1> logs/${job_name}.o
