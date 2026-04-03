#!/usr/bin/env bash

# Setup
org_type="prokaryotic"
module="classify-${org_type}"
job_name="${module}"
n_threads=16
veba_database=${VEBA_DATABASE} # If you have VEBA_DATABASE environmental variable set, if not use then put path

# Run
params="-i ../../Analysis/veba_output/binning/${org_type} -c ../../Analysis/veba_output/cluster/output/global/mags_to_slcs.tsv -p ${n_threads} --veba_database ${veba_database} -o ../../Analysis/veba_output/classify/${org_type}"
/usr/bin/time -v veba --module ${module} --params "${params}" 2> logs/${job_name}.e 1> logs/${job_name}.o
