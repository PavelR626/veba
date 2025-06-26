#!/bin/bash

# ==============================================================================
# Classify Representative Eukaryotic Genomes
#
# Description:
#   This script runs the VEBA `classify-eukaryotic` module, the final
#   classification step in the pipeline. It assigns taxonomic and functional
#   annotations to the eukaryotic genomes discovered.
#
#   Following the same efficient strategy as the other classification steps,
#   it uses the `mags_to_slcs.tsv` mapping file from the `cluster` step to
#   identify unique, representative eukaryotic genomes. It classifies these
#   representatives and then propagates the annotations back to all
#   corresponding eukaryotic bins from the original samples.
#
# Dependencies:
#   This script must be run *after* both the eukaryotic binning and the global
#   clustering steps are complete.
#
# Inputs:
#   - ../../Analysis/veba_output/binning/eukaryotic/: The directory containing
#     all original eukaryotic bins from all samples.
#   - ../../Analysis/veba_output/cluster/output/global/mags_to_slcs.tsv: The
#     mapping file from the clustering step.
#   - VEBA Database: The reference database required for classification.
#
# Outputs:
#   - ../../Analysis/veba_output/classify/eukaryotic/: The final directory
#     containing all eukaryotic classification and annotation tables.
#   - logs/classify-eukaryotic.e and logs/classify-eukaryotic.o: Log files.
# ==============================================================================

# --- Configuration ---

# A simple name for the log files for this step.
job_name="classify-eukaryotic"

# Number of processors/threads to allocate for the job.
n_jobs=8

# Base path to the locally mounted S3 bucket.
s3_path="/home/ubuntu/jolespin-volume/s3"

# Path to the VEBA reference database required for classification.
veba_database="${s3_path}/newatlantis-raw-veba-db-prod/VEBA/VEBA-DB_v9"


# --- Script Execution ---

echo "Starting classification of representative eukaryotic genomes..."

# Define the parameters for the VEBA classify-eukaryotic module.
# -i: Path to the original eukaryotic bins directory.
# -c: The cluster mapping file linking original bins to representative genomes.
# -o: The final output directory for all classification results.
# --n_jobs: Number of processors to use.
# --veba_database: The reference database for annotation.
params="-i ../../Analysis/veba_output/binning/eukaryotic/ -c ../../Analysis/veba_output/cluster/output/global/mags_to_slcs.tsv -o ../../Analysis/veba_output/classify/eukaryotic/ --n_jobs ${n_jobs} --veba_database ${veba_database}"

# Run the VEBA classify-eukaryotic module with resource monitoring.
# This performs annotation on the unique cluster representatives and maps results back.
/usr/bin/time -v veba --module classify-eukaryotic --params="${params}" 2> logs/${job_name}.e 1> logs/${job_name}.o

echo "Eukaryotic classification complete. Check logs/${job_name}.[eo] for details."
