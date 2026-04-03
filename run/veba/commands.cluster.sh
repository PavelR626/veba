#!/usr/bin/env bash

# Setup
module="cluster"
job_name="${module}"
n_threads=16
mkdir -p ../../Analysis/veba_output/misc/
identifier_mapping_table="../../Analysis/veba_output/misc/genomes_table.tsv"
compile_genomes_table.py -i ../../Analysis/veba_output/binning/ -o ${identifier_mapping_table}

# Run
params="-i ${identifier_mapping_table} -o ../../Analysis/veba_output/cluster -p ${n_threads}"
/usr/bin/time -v veba --module ${module} --params "${params}" 2> logs/${job_name}.e 1> logs/${job_name}.o
