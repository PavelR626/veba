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
2. Make sure your VEBA database path is set which is required for human contamination removal and rRNA filtering
```
echo $VEBA_DATABASE
# If nothing prints, set it manually:
# export VEBA_DATABASE=/path/to/veba/database
```
3. Trim reads, remove human contamination, and filter ribosomal reads
```
N_JOBS=4

HUMAN_INDEX=${VEBA_DATABASE}/Contamination/chm13v2.0/chm13v2.0

RIBOSOMAL_KMERS=${VEBA_DATABASE}/Contamination/kmers/ribokmers.fa.gz

for ID in $(cat identifiers.list); do

	R1=Fastq/${ID}_1.fastq.gz
	R2=Fastq/${ID}_2.fastq.gz
	N=preprocessing__${ID}
	rm -f logs/${N}.*

	CMD="source activate VEBA && veba --module preprocess --params \"-n ${ID} -1 ${R1} -2 ${R2} -p ${N_JOBS} -x ${HUMAN_INDEX} -k ${RIBOSOMAL_KMERS} --retain_contaminated_reads 0 --retain_kmer_hits 0 --retain_non_kmer_hits 0 -o veba_output/preprocess\""

	# Either run this command or use SunGridEngine/SLURM

	done
```

**Your output should look something like this:
* 
*
*

Your proccessed reads will go to:
```
veba_output/preprocess/${ID}/output/cleaned_1.fastq.gz
veba_output/preprocess/${ID}/output/cleaned_2.fastq.gz
```
#### 2. Assemble reads, map reads to assembly, and calculate assembly statistics

