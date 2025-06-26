#!/bin/bash

# ==============================================================================
# Create a Relational Database from VEBA Summary Files
#
# Description:
#   This script executes the final data consolidation step by creating a single,
#   queryable relational database from the curated summary files. It uses the
#   `build-relational-database.py` helper script to parse the various output
#   files within the `essentials` output directory and load them into a
#   portable SQLite database file (`veba.db`).
#
#   This centralizes the key findings of the entire pipeline, making the
#   results significantly easier to query, visualize, and analyze
#   programmatically with tools that understand SQL.
#
# Dependencies:
#   This script must be run *after* the `essentials` module has completed,
#   as it requires the curated files in that output directory. It also requires
#   the `build-relational-database.py` script to be available in the system's PATH.
#
# Inputs:
#   - ../../Analysis/veba_output/essentials/: The input directory containing the
#     curated set of essential summary files.
#
# Outputs:
#   - ../../Analysis/veba_output/essentials/veba.db: A single SQLite database
#     file containing all the summarized project data.
#   - logs/relational.e and logs/relational.o: Log files for the job.
# ==============================================================================

# --- Configuration ---

# A descriptive name for the log files for this job.
job_name="relational"

# Define the input directory and the output database file path.
input_essentials_directory="../../Analysis/veba_output/essentials/"
output_database_file="../../Analysis/veba_output/essentials/veba.db"


# --- Script Execution ---

echo "Creating relational database from summary files..."

# Run the Python script to build the database, with resource monitoring.
# -i: The input directory containing the essential summary files.
# -o: The full path for the output SQLite database file.
/usr/bin/time -v build-relational-database.py \
    -i "${input_essentials_directory}" \
    -o "${output_database_file}" \
    2> logs/${job_name}.e 1> logs/${job_name}.o

echo "Database creation complete. The database is located at: ${output_database_file}"
