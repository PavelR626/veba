#!/bin/bash

# ==============================================================================
# Generate VEBA Eukaryotic Binning Commands
#
# Description:
#   This script generates commands for the final binning step in the pipeline:
#   eukaryotic binning. It processes the remaining unbinned contigs after
#   both viral and prokaryotic binning have been performed, using the VEBA
#   tool to identify potential eukaryotic bins.
#
# Dependencies:
#   This script is the final step in the binning workflow and must be run
#   *after* the prokaryotic binning step is complete. It uses the
#   `unbinned.fasta` file from the 'binning-prokaryotic' output.
#
# Inputs:
#   - ../../identifiers.list: A text file containing one sample ID per line.
#   - Unbinned scaffolds: `.../binning/prokaryotic/${id}/output/unbinned.fasta`
#   - BAM alignment file: `.../assembly/${id}/output/mapped.sorted.bam` (from assembly)
#   - VEBA Database: A reference database for the binning process.
#   - BUSCO Database (Optional): Path to offline BUSCO datasets for quality assessment.
#
# Outputs:
#   - commands.binning_eukaryotic.list: A file with the full list of commands.
#   - logs/: A directory for standard output and error logs from each job.
#   - The VEBA tool will write the final eukaryotic bins to the `output_directory`.
# ==============================================================================

# --- Configuration ---

# Base path to the locally mounted S3 bucket.
s3_path="/home/ubuntu/jolespin-volume/s3"

# Path to the VEBA reference database required for binning.
veba_database="${s3_path}/newatlantis-raw-veba-db-prod/VEBA/VEBA-DB_v9"

# Path to offline BUSCO datasets for assessing genome completeness and quality.
# The corresponding parameter in the command below is currently commented out.
busco_database="${s3_path}/newatlantis-raw-veba-db-prod/BUSCO/"

# Directory where the final eukaryotic binning output will be stored.
# This should be on a shared file system like EFS.
output_directory="../../Analysis/veba_output/binning/eukaryotic/"


# --- Script Execution ---

# Ensure the main output directory exists.
mkdir -p "${output_directory}"

# Clean up any pre-existing command list file to start fresh.
rm -f commands.binning_eukaryotic.list
echo "Generating VEBA eukaryotic binning commands..."

# Iterate through each sample identifier provided in the list file.
for id in $(cat ../../identifiers.list);
do
        # Create a unique job name for logging purposes.
        job_name="binning-eukaryotic__${id}"
        echo "Processing sample: ${id}"

        # Path to the unbinned scaffolds left over from the prokaryotic binning step.
        # These are the contigs that were not classified as viral or prokaryotic.
        fasta="../../Analysis/veba_output/binning/prokaryotic/${id}/output/unbinned.fasta"

        # Path to the original sorted BAM file from the assembly step, used for coverage data.
        bam="../../Analysis/veba_output/assembly/${id}/output/mapped.sorted.bam"

        # Assemble the parameters string for the VEBA binning-eukaryotic module.
        # Note: To enable offline BUSCO analysis for quality control, uncomment
        # the `--busco_offline` parameter at the end of the line.
        params="-f ${fasta} -b ${bam} -n ${id} -o ${output_directory} -p=8 -m 1500 --veba_database ${veba_database}" # --busco_offline ${busco_database}"

        # Construct the full command to run the VEBA binning module.
        cmd="/usr/bin/time -v veba --module binning-eukaryotic --params='${params}'"

        # Append the complete command, with output/error redirection, to the list file.
        echo "${cmd} 2> logs/${job_name}.e 1> logs/${job_name}.o" >> commands.binning_eukaryotic.list

done

echo "Command generation complete. See 'commands.binning_eukaryotic.list'."
