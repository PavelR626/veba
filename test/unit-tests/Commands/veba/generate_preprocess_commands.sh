#!/bin/bash

# ==============================================================================
# Generate VEBA Preprocessing Commands
#
# Description:
#   This script generates a list of shell commands to preprocess raw sequencing
#   data using the VEBA tool. It reads a list of sample identifiers, locates
#   the corresponding FASTQ files, and constructs a command for each sample.
#
# Inputs:
#   - ../../identifiers.list: A text file containing one sample ID per line.
#   - Raw FASTQ files located in the `s3_path` directory structure.
#
# Outputs:
#   - commands.preprocess.list: A file containing the full list of commands
#     that can be run sequentially or in parallel (e.g., using GNU Parallel).
#   - logs/: A directory created to store standard output and error logs
#     from each VEBA job.
#   - The VEBA tool will write its output to the `output_directory`.
# ==============================================================================

# --- Configuration ---

# Base path to the locally mounted S3 bucket containing raw FASTQ data.
s3_path="/home/ubuntu/jolespin-volume/s3/"

# Directory for the final preprocessed output from VEBA.
# This is expected to be on a shared file system like EFS for accessibility.
output_directory="../../Analysis/veba_output/preprocess/"


# --- Script Execution ---

# Ensure the main output and log directories exist.
mkdir -p "${output_directory}"
mkdir -p "logs/"

# Clean up any pre-existing command list file to start fresh.
rm -f commands.preprocess.list
echo "Generating VEBA preprocess commands..."

# Iterate through each sample identifier provided in the list file.
for id in $(cat ../../identifiers.list);
do
        # Create a unique job name for logging purposes.
        job_name="preprocess__${id}"
        echo "Processing sample: ${id}"

        # Construct the full paths to the paired-end FASTQ files (Read 1 and Read 2).
        r1="${s3_path}/newatlantis-testing-db-prod/Fastq/${id}_1.fastq.gz"
        r2="${s3_path}/newatlantis-testing-db-prod/Fastq/${id}_2.fastq.gz"

        # Assemble the parameters string to be passed to the VEBA tool.
        params="-1 ${r1} -2 ${r2} -n ${id} -o ${output_directory} -p=8"

        # Construct the full command, wrapping 'veba' with '/usr/bin/time -v' for resource monitoring.
        cmd="/usr/bin/time -v veba --module preprocess --params='${params}'"

        # Append the complete command, with output and error redirection, to the command list file.
        # This allows the jobs to be executed later.
        echo "${cmd} 2> logs/${job_name}.e 1> logs/${job_name}.o" >> commands.preprocess.list

done

echo "Command generation complete. See 'commands.preprocess.list'."
