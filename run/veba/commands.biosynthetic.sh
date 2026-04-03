#!/usr/bin/env bash

# Setup
module="biosynthetic"
job_name="${module}"
n_threads=16
mkdir -p ../../Analysis/veba_output/misc/
identifier_mapping_table="../../Analysis/veba_output/misc/genomes_table.tsv"
biosynthetic_mapping_table="../../Analysis/veba_output/misc/genomes_table.biosynthetic.tsv"
cat ${identifier_mapping_table} | grep "prokaryotic" | cut -f3,4,7 > ${biosynthetic_mapping_table}

# Run
params="-i ${biosynthetic_mapping_table} -o ../../Analysis/veba_output/biosynthetic -p ${n_threads}"
/usr/bin/time -v veba --module ${module} --params "${params}" 2> logs/${job_name}.e 1> logs/${job_name}.o
