#!/usr/bin/env bash

# Setup
veba_database=${VEBA_DATABASE} # If you have VEBA_DATABASE environmental variable set, if not use then put path
cat ../../Analysis/veba_output/binning/*/*/output/genomes/*.faa | seqkit seq -M 99999 > ../../Analysis/veba_output/misc/all_genomes.all_proteins.lt100k.faa
n_threads=16

# Set up log names and output paths
module="annotate"
job_name="${module}"

# Input filepaths
proteins=../../Analysis/veba_output/misc/all_genomes.all_proteins.lt100k.faa
identifier_mapping=../../Analysis/veba_output/cluster/output/global/identifier_mapping.proteins.tsv.gz

# Run
params="-a ${proteins} -i ${identifier_mapping} -o ../../Analysis/veba_output/annotation -p ${n_threads} -u uniref50 --veba_database ${veba_database}"
/usr/bin/time -v veba --module ${module} --params "${params}" 2> logs/${job_name}.e 1> logs/${job_name}.o


