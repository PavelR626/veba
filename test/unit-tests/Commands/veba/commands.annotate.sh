#!/bin/bash

# ==============================================================================
# Functionally Annotate All Predicted Proteins
#
# Description:
#   This script performs functional annotation on every protein predicted across
#   all genomes (viral, prokaryotic, and eukaryotic) discovered in the entire
#   analysis. It consists of two main steps:
#
#   1. Aggregation: It finds all predicted protein FASTA files (`.faa`) from
#      all binning outputs, concatenates them into a single file, and runs a
#      quality control filter (`seqkit`) to remove any proteins longer than
#      99,999 amino acids.
#
#   2. Annotation: It runs the VEBA `annotate` module on this aggregated
#      protein file. This module assigns functional annotations to the proteins
#      using databases like UniRef50.
#
# Dependencies:
#   This script must be run *after* all binning and the global clustering steps
#   are complete. It requires `seqkit` to be installed and in the system's PATH.
#
# Inputs:
#   - All `.faa` protein files from `../../Analysis/veba_output/binning/`.
#   - The protein identifier mapping file from the `cluster` step.
#   - VEBA Database.
#
# Outputs:
#   - ../../Analysis/veba_output/misc/all_genomes.all_proteins.lt100k.faa: A
#     single, large FASTA file of all filtered proteins.
#   - ../../Analysis/veba_output/annotation/: The final directory containing
#     all functional annotation tables for the proteins.
#   - logs/annotate.e and logs/annotate.o: Log files for the job.
# ==============================================================================

# --- Configuration ---

# Job and resource settings
job_name="annotate"
n_jobs=8 # Use a higher number of threads for this intensive step

# Input and output file paths
aggregated_proteins_file="../../Analysis/veba_output/misc/all_genomes.all_proteins.lt100k.faa"
identifier_mapping="../../Analysis/veba_output/cluster/output/global/identifier_mapping.proteins.tsv.gz"
output_directory="../../Analysis/veba_output/annotation"

# Database paths
s3_path="/home/ubuntu/jolespin-volume/s3"
veba_database="${s3_path}/newatlantis-raw-veba-db-prod/VEBA/VEBA-DB_v9"


# --- Script Execution ---

echo "Starting functional annotation of all predicted proteins..."

# --- Step 1: Aggregate and filter all protein FASTA files ---
echo "Aggregating proteins from all bins into a single file..."
# This command finds all .faa files in the binning directories, concatenates them,
# filters out any proteins longer than 99,999 amino acids, and saves the result.
cat ../../Analysis/veba_output/binning/*/*/output/genomes/*.faa | seqkit seq -M 99999 > "${aggregated_proteins_file}"


# --- Step 2: Run the VEBA annotation module ---
echo "Running VEBA annotate module..."
# Define the parameters for the VEBA annotate module.
# -a: The aggregated protein FASTA file created in Step 1.
# -i: The identifier mapping file from the cluster step, linking proteins to genomes.
# -o: The final output directory for annotation results.
# -p: The number of processors to use.
# -u: The specific database to use for annotation (e.g., uniref50).
# --veba_database: The main VEBA database path.
params="-a ${aggregated_proteins_file} -i ${identifier_mapping} -o ${output_directory} -p ${n_jobs} -u uniref50 --veba_database ${veba_database}"

# Execute the annotation command with resource monitoring.
/usr/bin/time -v veba --module annotate --params="${params}" 2> logs/${job_name}.e 1> logs/${job_name}.o

echo "Protein annotation complete. Check logs/${job_name}.[eo] for details."
