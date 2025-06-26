#!/bin/bash

# ==============================================================================
# Aggregate and Cluster All Discovered Genomes
#
# Description:
#   This script performs the final major step of the analysis pipeline:
#   genome clustering. It first runs a helper script (`compile_genomes_table.py`)
#   to scan all the binning output directories (viral, prokaryotic, eukaryotic)
#   and create a single master table of all discovered genomes.
#
#   Then, it uses the VEBA `cluster` module to process this master table. This
#   module dereplicates the genomes, clustering similar ones together to
#   create a non-redundant set of high-quality, representative genomes from
#   across all samples.
#
# Dependencies:
#   This script must be run *after* all binning steps (viral, prokaryotic,
#   and eukaryotic) are complete. It also requires the `compile_genomes_table.py`
#   script to be available in the system's PATH.
#
# Inputs:
#   - All binning outputs located under `../../Analysis/veba_output/binning/`
#
# Outputs:
#   - ../../Analysis/veba_output/misc/genomes_table.tsv: An intermediate master
#     table of all genomes.
#   - ../../Analysis/veba_output/cluster/: The final directory containing the
#     clustering and dereplication results.
#   - logs/cluster.e and logs/cluster.o: Standard error and output log files.
# ==============================================================================

# --- Configuration ---

# A simple name for the log files for this step.
job_name="cluster"

# Number of processors/threads to use for the clustering step.
n_jobs=8


# --- Script Execution ---

echo "Starting genome aggregation and clustering..."

# Create a miscellaneous directory for intermediate files like the master genome table.
mkdir -p ../../Analysis/veba_output/misc/

# --- Step 1: Aggregate all discovered genomes ---
# This helper script scans the binning output directories and creates a single
# master table listing all genome bins found across all samples.
echo "Compiling master genome table..."
compile_genomes_table.py -i ../../Analysis/veba_output/binning/ -o ../../Analysis/veba_output/misc/genomes_table.tsv

# --- Step 2: Execute VEBA clustering ---
# Define the parameters for the VEBA cluster module.
# -i: The master genome table created in the previous step.
# -o: The final output directory for clustering results.
# -p: The number of processors to use.
params="-i ../../Analysis/veba_output/misc/genomes_table.tsv -o ../../Analysis/veba_output/cluster -p ${n_jobs}"

# Run the VEBA cluster module with resource monitoring. This command takes the
# master genome table and performs dereplication to produce a set of unique,
# representative genomes.
echo "Running VEBA cluster module..."
/usr/bin/time -v veba --module cluster --params="${params}" 2> logs/${job_name}.e 1> logs/${job_name}.o

echo "Clustering process complete. Check logs/${job_name}.[eo] for details."
