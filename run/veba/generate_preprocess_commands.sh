#!/usr/bin/env bash

# Setup
module="preprocess"
output_directory="../../Analysis/veba_output/preprocess/"
commands_file="commands.${module}.list"
n_threads_per_job=4

# Make the directory
mkdir -p ${output_directory}/
mkdir -p logs/

# Iterate through all samples in the reads table
rm -f ${command_list}

reads_table="../../reads_table.tsv"

while IFS=$'\t' read -r id r1 r2; do
    job_name="preprocess__${id}"
    echo $job_name

    params="-1 ${r1} -2 ${r2} -n ${id} -o ${output_directory} -p=${n_threads_per_job}"
    cmd="/usr/bin/time -v veba --module preprocess --params='${params}'"
    echo "${cmd} 2> logs/${job_name}.e 1> logs/${job_name}.o" >> ${command_list}

done < ${reads_table}