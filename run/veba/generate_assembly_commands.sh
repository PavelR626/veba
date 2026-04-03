#!/usr/bin/env bash

# Setup
module="assembly"
output_directory="../../Analysis/veba_output/assembly/"
commands_file="commands.${module}.list"
n_threads_per_job=4

# Make the directory
mkdir -p ${output_directory}/
mkdir -p logs/

# Iterate through all samples in the identifier list
rm -f ${commands_file}

for id in $(cat ../../identifiers.list);
do
        job_name="assembly__${id}"
        echo $job_name
        r1="../../Analysis/veba_output/preprocess/${id}/output/trimmed_1.fastq.gz"
        r2="../../Analysis/veba_output/preprocess/${id}/output/trimmed_2.fastq.gz"
	params="-1 ${r1} -2 ${r2} -n ${id} -o ${output_directory} -p=${n_threads_per_job} --program megahit --megahit_preset meta-large"
        cmd="/usr/bin/time -v veba --module assembly --params='${params}'"
        echo "${cmd} 2> logs/${job_name}.e 1> logs/${job_name}.o" >> ${commands_file}

done