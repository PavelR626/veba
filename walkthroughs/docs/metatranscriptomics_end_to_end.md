### Annotating proteins from metatranscriptomics

In metatranscriptomics, only viral genomes can be reliably recovered from transcript assemblies — prokaryotic and eukaryotic genome binning is not applicable because transcript data does not contain the full genomic structure needed to reconstruct complete genomes.

This pipeline works around that by recovering viral virus genomes normally through VEBA's viral binning module and processing the unbinned transcripts in metagenomic mode using Pyrodigal to identify expressed protein-coding regions. All the proteins recovered this way represent the active gene expression at the time of sampling.


## Pipeline Overview

![Pipeline Paulo provided](images/VEBAMetatranscriptomicsPipeline.png)

_____________________________________________________

#### Steps:

1. Preprocess reads and get directory set up
2. Assemble reads, map reads to assembly, and calculate assembly statistics
3. Recover viruses from metatranscriptomics assemblies
4. Identify expressed proteins from unbinned transcripts
5. Annotate viral and expressed prokaryotic proteins

*Remember to use each step's respective Conda Environment

#### 1. Preprocess reads and get directory set up

This is a quick rundown of how to download and preproccess Human lower respiratory tract samples although you can find a more detailed walkthrough of how to work with other reads here: [downloading and preprocessing reads workflow](download_and_preprocess_reads.md)

1.set up list of identifiers and create directories
```
conda activate VEBA-preprocess_env
mkdir -p logs/
mkdir -p Fastq/
cat identifiers.list
```
2. Download raw fastq files from TBA
3. Trim, remove contamination, count ribosomal reads
```
