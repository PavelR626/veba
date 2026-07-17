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
5. Annotate viral and Proteins predicted from unbinned transcripts

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
# Set the number of threads to use for each sample
N_JOBS=4

# Set the reference paths used for human-read removal and rRNA filtering
HUMAN_INDEX=${VEBA_DATABASE}/Contamination/chm13v2.0/chm13v2.0
RIBOSOMAL_KMERS=${VEBA_DATABASE}/Contamination/kmers/ribokmers.fa.gz

# Iterate through the sample identifiers
for ID in $(cat identifiers.list); do

	# Get the forward and reverse raw reads
	R1=Fastq/${ID}_1.fastq.gz
	R2=Fastq/${ID}_2.fastq.gz

	# Set a useful name for the job and its log files
	N=preprocessing__${ID}
	rm -f logs/${N}.*

	# Trim reads, remove human contamination, and filter ribosomal reads
	CMD="source activate VEBA && veba --module preprocess --params \"-n ${ID} -1 ${R1} -2 ${R2} -p ${N_JOBS} -x ${HUMAN_INDEX} -k ${RIBOSOMAL_KMERS} --retain_contaminated_reads 0 --retain_kmer_hits 0 --retain_non_kmer_hits 0 -o veba_output/preprocess\""

	# Either run this command or use SunGridEngine/SLURM

	done
```

**The following output files will be produced for each sample:**
* veba_output/preprocess/${ID}/output/cleaned_1.fastq.gz - Cleaned and trimmed forward reads
* veba_output/preprocess/${ID}/output/cleaned_2.fastq.gz - Cleaned and trimmed reverse reads
* seqkit_stats.concatenated.tsv - Read statistics from the intermediate preprocessing steps

The main files used in the next step are `cleaned_1.fastq.gz` and `cleaned_2.fastq.gz`. These contain the paired reads remaining after trimming, human-contamination removal, and ribosomal-read filtering.

#### 2. Assemble reads, map reads to assembly, and calculate assembly statistics

Here we assemble the cleaned reads into transcripts using `rnaSPAdes`

```
N_JOBS=4

# Use the customized metatranscriptomics assembly directory
OUT_DIR=veba_output/transcript_assembly

# Iterate through the sample identifiers
for ID in $(cat identifiers.list); do

	N="assembly__${ID}"
	rm -f logs/${N}.*

	# Get the cleaned forward and reverse reads from preprocessing
	R1=veba_output/preprocess/${ID}/output/cleaned_1.fastq.gz
	R2=veba_output/preprocess/${ID}/output/cleaned_2.fastq.gz

	# Assemble transcripts with rnaSPAdes, map reads, and calculate statistics
	CMD="source activate VEBA && veba --module assembly --params \"-1 ${R1} -2 ${R2} -n ${ID} -o ${OUT_DIR} -p ${N_JOBS} -P rnaspades.py\""

	# Either run this command or use SunGridEngine/SLURM

	done
```
**The following output files will be produced for each sample:**
* featurecounts.tsv.gz - featureCounts output for transcript-level counts
* mapped.sorted.bam - Sorted read-alignment file
* mapped.sorted.bam.bai - Index for the sorted BAM file
* genes_to_transcripts.tsv - Gene identifier to transcript identifier mapping
* transcripts.fasta - Assembled transcript sequences
* transcripts.fasta.*.bt2 - Bowtie2 index files
* transcripts.fasta.saf - SAF-formatted transcript features
* seqkit_stats.tsv.gz - Transcript assembly statistics

The main files used in the next step are `transcripts.fasta` and `mapped.sorted.bam`. The FASTA file contains the assembled transcript sequences, while the BAM file contains the reads mapped back to those transcripts for coverage information.

#### 3. Recover viruses from metatranscriptomic assemblies

We use *geNomad* to detect and *CheckV* to filter viral sequences from the transcript assembly. This is only viral binning and prokaryotic and eukaryotic binning does not apply to transcript data. Unbinned transcripts will be handled in the next step.

```
N_JOBS=4

for ID in $(cat identifiers.list); do

	N="binning-viral__${ID}"
	rm -f logs/${N}.*

	# Get the transcript assembly and its corresponding read alignments
	FASTA=veba_output/transcript_assembly/${ID}/output/transcripts.fasta
	BAM=veba_output/transcript_assembly/${ID}/output/mapped.sorted.bam

	# Detect viruses with geNomad and evaluate the recovered sequences with CheckV
	CMD="source activate VEBA && veba --module binning-viral --params \"-f ${FASTA} -b ${BAM} -n ${ID} -p ${N_JOBS} -m 1500 -o veba_output/binning/viral -a genomad\""

	# Either run this command or use SunGridEngine/SLURM

	done
```

**The following output files will be produced for each sample:**
* binned.list - List of transcript sequences assigned to viral bins
* bins.list - List of recovered viral genome identifiers
* checkv_results.filtered.tsv - Filtered CheckV quality results
* featurecounts.orfs.tsv.gz - ORF-level counts
* genome_statistics.tsv - Assembly statistics for the recovered viral genomes
* gene_statistics.cds.tsv - Statistics for predicted coding sequences
* genomes/ - Directory containing the recovered viral genomes and their predicted genes
* genomes/[id_genome].fa - Viral genome nucleotide sequence
* genomes/[id_genome].faa - Predicted viral protein sequences
* genomes/[id_genome].ffn - Predicted viral coding sequences
* genomes/[id_genome].gff - Viral gene models
* genomes/identifier_mapping.tsv - Mapping between ORF, transcript, and viral genome identifiers
* scaffolds_to_bins.tsv - Mapping between transcript sequences and viral bins
* unbinned.fasta - Sequences not included in the recovered viral bins
* unbinned.list - List of the unbinned sequence identifiers

The main files used in the next steps are `unbinned.fasta` and the viral protein files in `genomes/*.faa`.

#### 4. Identify expressed proteins from unbinned transcripts

Anything not classified as viral is used here to identify putative prokaryotic protein-coding regions. We will use Pyrodigal on the unbinned transcripts from the last step to identify these protein producing regions.

```
N_JOBS=4

for ID in $(cat identifiers.list); do

	N="pyrodigal__${ID}"
	rm -f logs/${N}.*

	# Use transcripts that were not included in the recovered viral bins
	FASTA=veba_output/binning/viral/${ID}/output/unbinned.fasta

	# Create a separate Pyrodigal output directory for each sample
	OUT_DIR=veba_output/expressed_proteins/${ID}
	mkdir -p ${OUT_DIR}

	# Predict protein-coding regions in metagenomic mode using genetic code 11
    # Write nucleotide sequences, protein sequences, and GFF gene models
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
	# Submit the Pyrodigal command to the shared partition
	# Request one node, one task, four CPUs, 12 GB of memory, and four hours
	# Standard output and error messages are written to the logs directory
	sbatch \
		--account=Your_Allocation \
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

**The following output files will be produced for each sample:**
* expressed_genes.ffn - 
*expressed_proteins.faa - 
*gene_models.gff - 

#### 5. Annotate viral and Proteins predicted from unbinned transcripts

Now we combine the viral proteins from step 3 with the Proteins predicted from unbinned transcripts from step 4 and annotate them together using VEBA's annotation module. This searches each protein against multiple reference databases to assign function labels.

1. Concatenate viral and expressed proteins for each sample
```
for ID in $(cat identifiers.list); do

	# Create a separate annotation directory for each sample
	OUT_DIR=veba_output/annotation/${ID}
	mkdir -p ${OUT_DIR}

	# Combine proteins from recovered viral genomes with proteins predicted from the unbinned transcripts
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

	# Use the combined viral and unbinned-transcript protein file
	PROTEINS=veba_output/annotation/${ID}/all_proteins.faa

	# Search the proteins against VEBA's functional annotation databases
	CMD="source activate VEBA && veba --module annotate --params \"-a ${PROTEINS} -o veba_output/annotation/${ID} -p ${N_JOBS}\""

	# Either run this command or use SunGridEngine/SLURM

	done
```

**The following output files will be produced for each sample:**
* 
*
*
