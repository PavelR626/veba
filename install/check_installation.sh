#!/bin/bash
# __version__ = "2026.4.1"

eval "$(conda shell.bash hook)"

CONDA_ENVS_PATH=${1:-"$(conda info --base)/envs/"}

for ENV_NAME in VEBA-annotate_env VEBA-assembly_env VEBA-binning-eukaryotic_env VEBA-binning-prokaryotic_env VEBA-binning-viral_env VEBA-biosynthetic_env VEBA-classify-eukaryotic_env VEBA-classify-prokaryotic_env VEBA-classify-viral_env VEBA-cluster_env VEBA-database_env VEBA-mapping_env VEBA-phylogeny_env VEBA-preprocess_env;
do 
    ENV_PREFIX=${CONDA_ENVS_PATH}/${ENV_NAME}
    (conda activate ${ENV_PREFIX} && echo "[PASS] ${ENV_NAME} SUCCESSFULLY created.") || (echo "[FAIL] ${ENV_NAME} was NOT created.")
    conda activate ${ENV_PREFIX} && if [ -z "${VEBA_DATABASE}" ]; then echo "[FAIL] VEBA_DATABASE environment variable NOT set in ${ENV_NAME}"; else echo "[PASS] VEBA_DATABASE environment SUCCESSFULLY set in ${ENV_NAME}"; fi
done

#CheckM2
for ENV_NAME in VEBA-binning-prokaryotic_env; 
do 
    ENV_PREFIX=${CONDA_ENVS_PATH}/${ENV_NAME}
    conda activate ${ENV_PREFIX}
    if [ -z "${CHECKM2DB}" ]; then echo "[FAIL] CHECKM2DB environment variable NOT set in ${ENV_NAME}"; else echo "[PASS] CHECKM2DB environment SUCCESSFULLY set in ${ENV_NAME}"; fi
done 

#GTDB-Tk
for ENV_NAME in VEBA-classify-prokaryotic_env; 
do 
    ENV_PREFIX=${CONDA_ENVS_PATH}/${ENV_NAME}
    conda activate ${ENV_PREFIX}
    if [ -z "${GTDBTK_DATA_PATH}" ]; then echo "[FAIL] GTDBTK_DATA_PATH environment variable NOT set in ${ENV_NAME}"; else echo "[PASS] GTDBTK_DATA_PATH environment SUCCESSFULLY set in ${ENV_NAME}"; fi
done 


# CheckV
for ENV_NAME in VEBA-binning-viral_env; 
do 
    ENV_PREFIX=${CONDA_ENVS_PATH}/${ENV_NAME}
    conda activate ${ENV_PREFIX}
    if [ -z "${CHECKVDB}" ]; then echo "[FAIL] CHECKVDB environment variable NOT set in ${ENV_NAME}"; else echo "[PASS] CHECKVDB environment SUCCESSFULLY set in ${ENV_NAME}"; fi
done
