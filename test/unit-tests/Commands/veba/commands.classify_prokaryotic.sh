#!/bin/bash

# ==============================================================================
# Classify Representative Prokaryotic Genomes (MAGs)
#
# Description:
#   This script runs the VEBA `classify-prokaryotic` module to assign
#   taxonomic and functional annotations to the prokaryotic genomes (MAGs)
#   discovered in the pipeline.
#
#   It follows the same efficient strategy as the viral classification step:
#   it uses the mapping file (`mags_to_slcs.tsv`) from the `cluster` step to
#   identify the unique, representative MAGs. It then classifies these
#   representatives and propagates the annotations back to all corresponding
#   prokaryotic bins from the original samples.
#
# Dependencies:
#   This script must be run *after* both the prokaryotic binning and the global
#   clustering steps are complete.
#
# Inputs:
#   - ../../Analysis/veba_output/binning/prokaryotic/: The directory with all
#     original prokaryotic bins from all samples.
#   - ../../Analysis/veba_output/cluster/output/global/mags_to_slcs.tsv: The
#     mapping file from the clustering step that links original bins to their
#     representative cluster genome.
#   - VEBA Database: The reference database required for classification.
#
# Outputs:
#   - ../../Analysis/veba_output/classify/prokaryotic/: The final directory
#     containing all prokaryotic classification and annotation tables.
#   - logs/classify-prokaryotic.e and logs/classify-prokaryotic.o: Log files.
# ==============================================================================

# --- Configuration ---

# A simple name for the log files for this step.
job_name="classify-prokaryotic"

# Number of processors/threads to allocate for the job.
n_jobs=8

# Base path to the locally mounted S3 bucket.
s3_path="/home/ubuntu/jolespin-volume/s3"

# Path to the VEBA reference database required for classification.
veba_database="${s3_path}/newatlantis-raw-veba-db-prod/VEBA/VEBA-DB_v9"


# --- Script Execution ---

echo "Starting classification of representative prokaryotic genomes..."

# Define the parameters for the VEBA classify-prokaryotic module.
# -i: Path to the original prokaryotic bins directory.
# -c: The cluster mapping file linking original bins to representative genomes.
# -o: The final output directory for all classification results.
# --n_jobs: Number of processors to use.
# --veba_database: The reference database for annotation.
params="-i ../../Analysis/veba_output/binning/prokaryotic/ -c ../../Analysis/veba_output/cluster/output/global/mags_to_slcs.tsv -o ../../Analysis/veba_output/classify/prokaryotic/ --n_jobs ${n_jobs} --veba_database ${veba_database}"

# Run the VEBA classify-prokaryotic module with resource monitoring.
# This performs annotation on the unique cluster representatives and maps results back.
/usr/bin/time -v veba --module classify-prokaryotic --params="${params}" 2> logs/${job_name}.e 1> logs/${job_name}.o

echo "Prokaryotic classification complete. Check logs/${job_name}.[eo] for details."
