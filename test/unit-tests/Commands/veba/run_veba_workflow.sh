#!/bin/bash
#source activate VEBA

# Commands list for sample-specific processes
# ===========================================
# Preprocess
echo "Preprocess"
bash generate_preprocess_commands.sh # Output: commands.preprocess.list
number_of_concurrent_jobs=4
cat commands.preprocess.list | parallel -j ${number_of_concurrent_jobs}

# Assembly
echo "Assembly"
bash generate_assembly_commands.sh # Output: commands.assembly.list
number_of_concurrent_jobs=1
cat commands.assembly.list | parallel -j ${number_of_concurrent_jobs}

# Binning Viral
echo "Binning Viral"
bash generate_binning_viral_commands.sh # Output: commands.binning_viral.list
number_of_concurrent_jobs=4
cat commands.binning_viral.list | parallel -j ${number_of_concurrent_jobs}

# Binning Prokaryotic
echo "Binning Prokaryotic"
bash generate_binning_prokaryotic_commands.sh # Output: commands.binning_prokaryotic.list
number_of_concurrent_jobs=4
cat commands.binning_prokaryotic.list | parallel -j ${number_of_concurrent_jobs}

# Binning Eukaryotic
echo "Binning Eukaryotic"
bash generate_binning_eukaryotic_commands.sh # Output: commands.binning_eukaryotics.list
number_of_concurrent_jobs=4
cat commands.binning_eukaryotic.list | parallel -j ${number_of_concurrent_jobs}

#  Commands list for batch processes
#  =================================
# Cluster
echo "Cluster"
bash commands.cluster.sh

# Classify viral
echo "Classify viral"
bash commands.classify_viral.sh

# Classify prokaryotic
echo "Classify prokaryotic"
bash commands.classify_prokaryotic.sh

# Classify eukaryotic
echo "Classify eukaryotic"
bash commands.classify_eukaryotic.sh

# Annotate
echo "Annotate"
bash commands.annotate.sh

# Essentials
echo "Essentials"
bash commands.essentials.sh

# Relational
bash commands.relational.sh
