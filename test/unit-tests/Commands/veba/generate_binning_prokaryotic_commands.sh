#!/bin/bash

# ==============================================================================
# Generate VEBA Prokaryotic Binning Commands
#
# Description:
#   This script generates commands to perform prokaryotic binning on the
#   contigs that were not binned during the viral binning step. It uses
#   the VEBA tool with specified algorithms (MetaBAT2, MetaDecoder) to
#   group the remaining scaffolds into Metagenome-Assembled Genomes (MAGs).
#   Additional binning algorithms are supported but these 2 are deterministic.
# Dependencies:
#   This script must be run *after* both the assembly and viral binning steps
#   are complete. It specifically requires the `unbinned.fasta` file from
#   the 'binning-viral' output.
#
# Inputs:
#   - ../../identifiers.list: A text file containing one sample ID per line.
#   - Unbinned scaffolds: `.../binning/viral/${id}/output/unbinned.fasta`
#   - BAM alignment file: `.../assembly/${id}/output/mapped.sorted.bam` (from assembly)
#   - VEBA Database: A reference database for the binning process.
#
# Outputs:
#   - commands.binning_prokaryotic.list: A file with the full list of commands.
#   - logs/: A directory for standard output and error logs from each job.
#   - The VEBA tool will write the final prokaryotic bins (MAGs) to the
#     `output_directory`.
# ==============================================================================

# --- Configuration ---

# Base path to the locally mounted S3 bucket.
s3_path="/home/ubuntu/jolespin-volume/s3"

# Path to the VEBA reference database required for binning.
veba_database="${s3_path}/newatlantis-raw-veba-db-prod/VEBA/VEBA-DB_v9"

# Directory where the final prokaryotic binning output will be stored.
output_directory="../../Analysis/veba_output/binning/prokaryotic/"


# --- Script Execution ---

# Ensure the main output directory exists.
mkdir -p "${output_directory}"

# Clean up any pre-existing command list file to start fresh.
rm -f commands.binning_prokaryotic.list
echo "Generating VEBA prokaryotic binning commands..."

# Iterate through each sample identifier provided in the list file.
for id in $(cat ../../identifiers.list);
do
        # Create a unique job name for logging purposes.
        job_name="binning-prokaryotic__${id}"
        echo "Processing sample: ${id}"

        # Path to the unbinned scaffolds left over from the viral binning step.
        # This is the primary input for prokaryotic binning.
        fasta="../../Analysis/veba_output/binning/viral/${id}/output/unbinned.fasta"

        # Path to the original sorted BAM file from the assembly step, used for coverage data.
        bam="../../Analysis/veba_output/assembly/${id}/output/mapped.sorted.bam"

        # Assemble the parameters string for the VEBA binning-prokaryotic module.
        # --n_iter: Number of binning iterations.
        # --algorithms: Specific binning tools to run.
        params="-f ${fasta} -b ${bam} -n ${id} -o ${output_directory} -p=8 -m 1500 --veba_database ${veba_database} --n_iter 2 --algorithms metabat2,metadecoder"

        # Construct the full command to run the VEBA binning module.
        cmd="/usr/bin/time -v veba --module binning-prokaryotic --params='${params}'"

        # Append the complete command, with output/error redirection, to the list file.
        echo "${cmd} 2> logs/${job_name}.e 1> logs/${job_name}.o" >> commands.binning_prokaryotic.list

done

echo "Command generation complete. See 'commands.binning_prokaryotic.list'."
