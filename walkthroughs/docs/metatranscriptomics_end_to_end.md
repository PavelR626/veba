### Annotating proteins from metatranscriptomics

In metatranscriptomics, only viral genomes can be reliably recovered from transcript assemblies — prokaryotic and eukaryotic genome binning is not applicable because transcript data does not contain the full genomic structure needed to reconstruct complete genomes.

This walkthrough works around that by recovering viral genomes normally through VEBA's viral binning module and processing the unbinned transcripts in metagenomic mode using Pyrodigal to predict potential protein-coding regions. Then it annotates those proteins together with proteins from the recovered viral genomes.


## Pipeline Overview

![Pipeline Paulo provided](../../images/VEBAMetatranscriptomicsPipeline.png)

*Diagram made by Paulo Tanicala*
_____________________________________________________

#### Steps:

1. Preprocess reads and get directory set up
2. Assemble reads, map reads to assembly, and calculate assembly statistics
3. Recover viruses from metatranscriptomics assemblies
4. Identify expressed proteins from unbinned transcripts
5. Annotate viral and expressed prokaryotic proteins

#### 1. Preprocess reads and get directory set up

This is a quick rundown of how to preprocess already downloaded Human lower respiratory tract samples although you can find a more detailed walkthrough of how to work with other reads here: [downloading and preprocessing reads workflow](download_and_preprocess_reads.md)

Before starting, make sure you have:
* An `identifiers.list` file containing one sample identifier per line
* Paired reads named `Fastq/${ID}_1.fastq.gz` and `Fastq/${ID}_2.fastq.gz`

1.Set up list of identifiers and create directories
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
	N=preprocess__${ID}
	rm -f logs/${N}.*

	CMD="source activate VEBA && veba --module preprocess --params \"-n ${ID} -1 ${R1} -2 ${R2} -p ${N_JOBS} -x ${HUMAN_INDEX} -k ${RIBOSOMAL_KMERS} --retain_contaminated_reads 0 --retain_kmer_hits 0 --retain_non_kmer_hits 0 -o veba_output/preprocess\""

	# Either run this command or use SunGridEngine/SLURM

	done
```

**Your output should look like this:
* 
*
*

Your processed reads will go to:
```
veba_output/preprocess/${ID}/output/cleaned_1.fastq.gz
veba_output/preprocess/${ID}/output/cleaned_2.fastq.gz
```
#### 2. Assemble reads, map reads to assembly, and calculate assembly statistics

Here we assemble the cleaned reads into transcripts using `rnaSPAdes`

```
N_JOBS=4

# Output directory
OUT_DIR=veba_output/transcript_assembly

mkdir -p logs

for ID in $(cat identifiers.list); do

	N="assembly__${ID}"
	rm -f logs/${N}.*

	R1=veba_output/preprocess/${ID}/output/cleaned_1.fastq.gz
	R2=veba_output/preprocess/${ID}/output/cleaned_2.fastq.gz

	CMD="source activate VEBA && veba --module assembly --params \"-1 ${R1} -2 ${R2} -n ${ID} -o ${OUT_DIR} -p ${N_JOBS} -P rnaspades.py\""

	# Either run this command or use SunGridEngine/SLURM

	done
```
**Your output should look like this:
* 
*
*

#### 3. Recover viruses from metatranscriptomic assemblies

We use *geNomad* to detect and *CheckV* to filter viral sequences from the transcript assembly. This is only viral binning and prokaryotic and eukaryotic binning does not apply to transcript data. Unbinned transcripts will be handled in the next step.

```
N_JOBS=4

for ID in $(cat identifiers.list); do

	N="binning-viral__${ID}"
	rm -f logs/${N}.*

	FASTA=veba_output/transcript_assembly/${ID}/output/transcripts.fasta
	BAM=veba_output/transcript_assembly/${ID}/output/mapped.sorted.bam

	CMD="source activate VEBA && veba --module binning-viral --params \"-f ${FASTA} -b ${BAM} -n ${ID} -p ${N_JOBS} -m 1500 -o veba_output/binning/viral -a genomad\""

	# Either run this command or use SunGridEngine/SLURM

	done
```

**Your output should look like this:
* 
*
*

#### 4. Identify expressed proteins from unbinned transcripts

Anything not classified as viral is used here to identify putative prokaryotic protein-coding regions. We will use Pyrodigal on the unbinned transcripts from the last step to identify these protein producing regions.

```
CODE=""

N_JOBS=4

mkdir -p logs

for ID in $(cat identifiers.list); do

	N="pyrodigal__${ID}"
	rm -f logs/${N}.*

	FASTA=veba_output/binning/viral/${ID}/output/unbinned.fasta
	OUT_DIR=veba_output/expressed_proteins/${ID}
	mkdir -p ${OUT_DIR}

	CMD="source activate VEBA-binning-prokaryotic_env && pyrodigal \
		-p meta \
		-j ${N_JOBS} \
		-i ${FASTA} \
		-g 11 \
		-f gff \
		-d ${OUT_DIR}/expressed_genes.ffn \
		-a ${OUT_DIR}/expressed_proteins.faa \
		-o ${OUT_DIR}/gene_models.gff \
		--min-gene 90 \
		--min-edge-gene 60 \
		--max-overlap 60"

	# Either run this command or use SunGridEngine/SLURM
	
	done
```

An example of running Pyrodigal using SLURM:

```
	sbatch \
		--mail-type=ALL \
		--mail-user=YOUR_EMAIL \
        --job-name=${N} \
        --output=logs/${N}.out \
        --error=logs/${N}.err \
        --partition=ind-shared \
        --nodes=1 \
        --ntasks-per-node=1 \
        --cpus-per-task=${N_JOBS} \
        --mem=12G \
        --time=04:00:00 \
        --wrap="${CMD}"
```

**Your output should look like this:
* 
*
*

#### 5. Annotate viral and expressed prokaryotic proteins

Now we combine the viral proteins from step 3 with the expressed prokaryotic proteins from step 4 and annotate them together using VEBA's annotation module. This searches each protein against multiple reference databases to assign function labels.

1. Concatenate viral and expressed proteins for each sample
```
for ID in $(cat identifiers.list); do

	OUT_DIR=veba_output/annotation/${ID}
	mkdir -p ${OUT_DIR}

	cat veba_output/binning/viral/${ID}/output/genomes/*.faa \
	    veba_output/expressed_proteins/${ID}/expressed_proteins.faa \
	    > ${OUT_DIR}/all_proteins.faa

	done
```

2. Run VEBA's annotation module on the combined protein file
```
N_JOBS=4

for ID in $(cat identifiers.list); do

	N="annotate__${ID}"
	rm -f logs/${N}.*

	PROTEINS=veba_output/annotation/${ID}/all_proteins.faa

	CMD="source activate VEBA && veba --module annotate --params \"-a ${PROTEINS} -o veba_output/annotation/${ID} -p ${N_JOBS}\""

	# Either run this command or use SunGridEngine/SLURM

	done
```

**Your output should look like this:
* 
*
*
