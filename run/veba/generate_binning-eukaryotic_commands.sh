#!/usr/bin/env bash

# Setup
module="binning-eukaryotic"
output_directory="../../Analysis/veba_output/binning/eukaryotic"
commands_file="commands.${module}.list"
veba_database=${VEBA_DATABASE} # If you have VEBA_DATABASE environmental variable set, if not use then put path
n_threads_per_job=4

# Make the directory and clear existing files
mkdir -p ${output_directory}/
mkdir -p logs/

# Iterate through all samples in the identifier list
rm -f ${commands_file}

for id in $(cat ../../identifiers.list);
do
        job_name="${module}__${id}"
        echo ${job_name}
        fasta="../../Analysis/veba_output/binning/prokaryotic/${id}/output/unbinned.fasta"
        bam="../../Analysis/veba_output/assembly/${id}/output/mapped.sorted.bam"
        params="-f ${fasta} -b ${bam}  -n ${id} -o ${output_directory} -p=${n_threads_per_job} -m 1500 --busco_completeness 30 --veba_database ${veba_database}"
        cmd="/usr/bin/time -v veba --module ${module} --params \"${params}\""
        echo "${cmd} 2> logs/${job_name}.e 1> logs/${job_name}.o" >> ${commands_file}

done
