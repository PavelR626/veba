#!/bin/bash
source activate VEBA

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
number_of_concurrent_jobs=4
cat commands.assembly.list | parallel -j ${number_of_concurrent_jobs}

# Binning Viral
echo "Binning Viral"
bash generate_binning-viral_commands.sh # Output: commands.binning-viral.list
number_of_concurrent_jobs=4
cat commands.binning-viral.list | parallel -j ${number_of_concurrent_jobs}

# Binning Prokaryotic
echo "Binning Prokaryotic"
bash generate_binning-prokaryotic_commands.sh # Output: commands.binning-prokaryotic.list
number_of_concurrent_jobs=4
cat commands.binning-prokaryotic.list | parallel -j ${number_of_concurrent_jobs}

# Binning Eukaryotic
echo "Binning Eukaryotic"
bash generate_binning-eukaryotic_commands.sh # Output: commands.binning-eukaryotics.list
number_of_concurrent_jobs=4
cat commands.binning-eukaryotic.list | parallel -j ${number_of_concurrent_jobs}

#  Commands list for batch processes
#  =================================
# Cluster
echo "Cluster"
bash commands.cluster.sh

# Classify viral
echo "Classify viral"
bash commands.classify-viral.sh

# Classify prokaryotic
echo "Classify prokaryotic"
bash commands.classify-prokaryotic.sh

# Classify eukaryotic
echo "Classify eukaryotic"
bash commands.classify-eukaryotic.sh

# Annotate
echo "Annotate"
bash commands.annotate.sh

# Biosynthetic
echo "Biosynthetic"
bash commands.biosynthetic.sh

