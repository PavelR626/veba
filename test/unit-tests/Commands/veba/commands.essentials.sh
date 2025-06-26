#!/bin/bash

# ==============================================================================
# Generate Essential Summary Package for Export
#
# Description:
#   This script executes the final step of the VEBA pipeline: summarization.
#   It runs the VEBA `essentials` module, which scans the entire VEBA output
#   directory and collects the most important, high-level summary files
#   (e.g., final classification tables, cluster representatives, quality reports)
#   into a single, clean directory.
#
#   The purpose of this step is to create a lightweight, portable summary of
#   the entire project's results that can be easily shared or archived without
#   including all of the large, intermediate files.
#
# Dependencies:
#   This script should be the very last one executed, as it requires all previous
#   VEBA modules (binning, clustering, classification, annotation) to have
#   completed successfully.
#
# Inputs:
#   - ../../Analysis/veba_output/: The root directory containing all generated
#     outputs from the previous VEBA pipeline steps.
#
# Outputs:
#   - ../../Analysis/veba_output/essentials/: A new directory containing a
#     curated set of the most important summary files.
#   - logs/essentials.e and logs/essentials.o: Log files for the job.
# ==============================================================================

# --- Configuration ---

# The name of the VEBA module to run.
module_name="essentials"

# A simple name for the log files.
job_name="${module_name}"

# Define the root input and final output directories.
veba_output_root="../../Analysis/veba_output/"
essentials_output_directory="${veba_output_root}/essentials/"


# --- Script Execution ---

echo "Starting VEBA summary generation..."

# Ensure the final output directory exists.
mkdir -p "${essentials_output_directory}"

# Define the parameters for the VEBA essentials module.
# -i: The root VEBA output directory to scan for results.
# -o: The destination directory for the curated summary files.
params="-i ${veba_output_root} -o ${essentials_output_directory}"

# Run the VEBA essentials module with resource monitoring.
# This command will gather all key result files into the output directory.
/usr/bin/time -v veba --module ${module_name} --params="${params}" 2> logs/${job_name}.e 1> logs/${job_name}.o

echo "Summary generation complete. Essential files are in '${essentials_output_directory}'."
