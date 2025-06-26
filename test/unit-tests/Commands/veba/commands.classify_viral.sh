#!/bin/bash

# ==============================================================================
# Classify Representative Viral Genomes
#
# Description:
#   This script runs the VEBA `classify-viral` module to assign taxonomic
#   and functional annotations to the viral genomes discovered in the pipeline.
#
#   Crucially, it operates on the *results* of the `cluster` step. It takes
#   the mapping file (`mags_to_slcs.tsv`), which links all original viral bins
#   to their representative cluster genomes. The module then classifies these
#   representative genomes and uses the map to propagate the annotations
#   back to all corresponding bins from the original samples. This is a highly
#   efficient approach to classification.
#
# Dependencies:
#   This script must be run *after* both the viral binning and the global
#   clustering steps are complete.
#
# Inputs:
#   - ../../Analysis/veba_output/binning/viral/: The directory containing all
#     original viral bins from all samples.
#   - ../../Analysis/veba_output/cluster/output/global/mags_to_slcs.tsv: The
#     mapping file from the clustering step that links original bins to their
#     representative cluster genome.
#   - VEBA Database: The reference database required for classification.
#
# Outputs:
#   - ../../Analysis/veba_output/classify/viral/: The final directory
#     containing all classification and annotation tables.
#   - logs/classify-viral.e and logs/classify-viral.o: Log files for the job.
# ==============================================================================

# --- Configuration ---

# A simple name for the log files for this step.
job_name="classify-viral"

# Number of processors/threads to allocate for the job.
n_jobs=8

# Base path to the locally mounted S3 bucket.
s3_path="/home/ubuntu/jolespin-volume/s3"

# Path to the VEBA reference database required for classification.
veba_database="${s3_path}/newatlantis-raw-veba-db-prod/VEBA/VEBA-DB_v9"


# --- Script Execution ---

echo "Starting classification of representative viral genomes..."

# Define the parameters for the VEBA classify-viral module.
# -i: Path to the original viral bins directory.
# -c: The cluster mapping file linking original bins to representative genomes.
# -o: The final output directory for all classification results.
# --n_jobs: Number of processors to use.
# --veba_database: The reference database for annotation.
params="-i ../../Analysis/veba_output/binning/viral/ -c ../../Analysis/veba_output/cluster/output/global/mags_to_slcs.tsv -o ../../Analysis/veba_output/classify/viral/ --n_jobs ${n_jobs} --veba_database ${veba_database}"

# Run the VEBA classify-viral module with resource monitoring. This command
# performs the heavy lifting of annotation on the unique cluster representatives.
/usr/bin/time -v veba --module classify-viral --params="${params}" 2> logs/${job_name}.e 1> logs/${job_name}.o

echo "Viral classification complete. Check logs/${job_name}.[eo] for details."
