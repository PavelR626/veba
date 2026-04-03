#!/usr/bin/env python
import sys, os, glob, argparse
from collections import OrderedDict
import pandas as pd
from tqdm import tqdm
import xxhash

__program__ = os.path.split(sys.argv[0])[-1]
__version__ = "2026.3.24"


def main(args=None):
    # Path info
    script_directory  =  os.path.dirname(os.path.abspath( __file__ ))
    script_filename = __program__
    # Path info
    description = """
    Running: {} v{} via Python v{} | {}""".format(__program__, __version__, sys.version.split(" ")[0], sys.executable)
    usage = "{} -i <binette_directory> -o <output_directory> -f <scaffolds.fasta> -m 1500".format(__program__)
    epilog = "Copyright 2021 Josh L. Espinoza (jespinoz@jcvi.org)"

    # Parser
    parser = argparse.ArgumentParser(description=description, usage=usage, epilog=epilog, formatter_class=argparse.RawTextHelpFormatter)

    # Pipeline
    parser.add_argument("-i","--binette_directory", type=str, required=True, help = "path/to/binette_directory/")
    parser.add_argument("-o","--output_directory", type=str, help = "path/to/output_directory/ [Default: path/to/binette_directory/filtered/]")
    parser.add_argument("-p","--bin_prefix", type=str, default="BINETTE__", help = "Bin prefix [Default: 'BINETTE__']")
    parser.add_argument("-x","--extension", type=str, default="fa", help = "Fasta file extension for bins [Default: fa]")
    parser.add_argument("-f", "--fasta", type=str, help = "path/to/scaffolds.fasta. Include this only if you want to list of unbinned contigs")
    parser.add_argument("-m", "--minimum_contig_length", type=int, default=1, help="Minimum contig length. [Default: 1]")
    parser.add_argument("--completeness", type=float, default=50.0, help = "CheckM2 completeness [Default: 50.0]")
    parser.add_argument("--contamination", type=float, default=10.0, help = "CheckM2 contamination [Default: 10.0]")
    parser.add_argument("-u", "--unbinned", action="store_true", help="Write unbinned fasta sequences to file")
    parser.add_argument("-e", "--exclude",  help="List of genomes to exclude (e.g., eukaryotic genomes)")
    parser.add_argument("-d","--domain_predictions", type=str,  help = "Tab-seperated table of domain predictions [id_genome]<tab>[id_domain], No header.")

    # Options
    opts = parser.parse_args()
    opts.script_directory  = script_directory
    opts.script_filename = script_filename
    
    # Output filtered 
    if not opts.output_directory:
        opts.output_directory = os.path.join(opts.binette_directory, "filtered")
    os.makedirs(opts.output_directory, exist_ok=True)
    os.makedirs(os.path.join(opts.output_directory,"genomes"), exist_ok=True)
    
    # Exclusion
    exclude_mags = set()
    if opts.exclude:
        with open(opts.exclude, "r") as f:
            for line in f:
                line = line.strip()
                if line:
                    exclude_mags.add(line)
    if exclude_mags:
        print("Excluding the following MAGs:", exclude_mags, file=sys.stderr)
        
    # Compute content-addressable hashes for each MAG
    binette_name_to_hash = dict()
    for filepath in tqdm(glob.glob(os.path.join(opts.binette_directory, "final_bins", "*.{}".format(opts.extension))), "Creating hashes for each MAG", unit=" MAGs"):
        id_mag = os.path.basename(filepath).rsplit(".", 1)[0]
        contigs = set()
        with open(filepath, "r") as f:
            for line in f:
                line = line.strip()
                if line.startswith(">"):
                    header = line[1:]
                    id_contig = header.split(" ", maxsplit=1)[0]
                    contigs.add(id_contig)
        contigs_repr = repr(sorted(contigs))
        binette_name_to_hash[id_mag] = xxhash.xxh32(contigs_repr, seed=0).hexdigest()
                
    # Load quality report (binette v1.2.1 format)
    # Columns: name, origin, is_original, original_name, completeness, contamination, score, checkm2_model, size, N50, coding_density, contig_count
    df_quality_report = pd.read_csv(os.path.join(opts.binette_directory, "final_bins_quality_reports.tsv"), sep="\t", index_col=0)
    
    if opts.domain_predictions:
        print("Adding domain predictions", file=sys.stderr)
        mag_to_domain = pd.read_csv(opts.domain_predictions, sep="\t", index_col=0, header=None).iloc[:,0]
        df_quality_report["domain"] = mag_to_domain
    
    # Quality assessment on MAGs
    binette_name_to_magnew = dict()
    mags = list()

    for id_mag, row in tqdm(df_quality_report.iterrows(), "Filtering MAGs", unit=" MAGs"):
        is_original = row["is_original"]
        original_name = row["original_name"]
        completeness = row["completeness"]
        contamination = row["contamination"]

        # Conditions
        conditions = [
            completeness >= opts.completeness,
            contamination < opts.contamination,
            id_mag not in exclude_mags,
        ]
        if all(conditions):
            if is_original:
                new_mag = original_name
            else:
                new_mag = "{}{}".format(opts.bin_prefix, binette_name_to_hash[id_mag])
            binette_name_to_magnew[id_mag] = new_mag
            mags.append(id_mag)
    pd.Series(binette_name_to_magnew).to_frame().to_csv(os.path.join(opts.output_directory, "initial_to_filtered.tsv"), sep="\t", header=None)

    # Build quality report
    df_quality_report_filtered = df_quality_report.loc[mags,:].copy()
    df_quality_report_filtered.insert(0, "binette_name", df_quality_report_filtered.index)
    df_quality_report_filtered.index = df_quality_report_filtered.index.map(lambda x: binette_name_to_magnew[x])
    
    # Write quality report
    df_quality_report_filtered = df_quality_report_filtered.sort_index()
    df_quality_report_filtered.index.name = "bin_id"
    df_quality_report_filtered.to_csv(os.path.join(opts.output_directory,"checkm2_results.filtered.tsv"), sep="\t") 

    # bins.list
    with open(os.path.join(opts.output_directory, "bins.list"), "w") as f_bins:
        for id_mag in sorted(mags):
            print(binette_name_to_magnew[id_mag], file=f_bins)

    # binned.list
    f_binned_list = open(os.path.join(opts.output_directory, "binned.list"), "w")

    binned_contigs = set() 
    scaffold_to_mag = OrderedDict()
    for id_mag in tqdm(mags, "Copying fasta files and writing binned contigs", unit=" MAGs"):

        src = os.path.join(opts.binette_directory, "final_bins", "{}.{}".format(id_mag, opts.extension))
        dst = os.path.join(opts.output_directory, "genomes", "{}.fa".format(binette_name_to_magnew[id_mag]))
        # Use file copy instead of shutil.copyfile to handle edge cases
        from shutil import copyfile
        copyfile(src, dst)

        # Write contigs to list
        with open(src, "r") as f_fasta:
            for line in f_fasta:
                line = line.strip()
                if line.startswith(">"):
                    header = line[1:]
                    id_contig = header.split(" ")[0].strip()
                    print(id_contig, file=f_binned_list)
                    binned_contigs.add(id_contig)
                    scaffold_to_mag[id_contig] = binette_name_to_magnew[id_mag]
    f_binned_list.close()
    scaffold_to_mag = pd.Series(scaffold_to_mag)
    scaffold_to_mag.to_frame().to_csv(os.path.join(opts.output_directory,"scaffolds_to_bins.tsv"), sep="\t", header=None)

    # Get unbinned contigs
    if opts.fasta:
        import pyfastx

        f_unbinned_list = open(os.path.join(opts.output_directory, "unbinned.list"), "w")

        if opts.unbinned:
            f_unbinned_fasta = open(os.path.join(opts.output_directory, "unbinned.fasta"), "w")
            for id_contig, seq in tqdm(pyfastx.Fasta(opts.fasta, build_index=False), "Writing unbinned contigs", unit=" contig"):
                
                conditions = [
                    id_contig not in binned_contigs,
                    len(seq) >= opts.minimum_contig_length,
                ]
               
                if all(conditions):
                    print(id_contig, file=f_unbinned_list)
                    print(">{}\n{}".format(id_contig, seq), file=f_unbinned_fasta)
            f_unbinned_fasta.close()
        else:
            for id_contig, seq in tqdm(pyfastx.Fasta(opts.fasta, build_index=False), "Writing unbinned contigs", unit=" contig"):
                conditions = [
                    id_contig not in binned_contigs,
                    len(seq) >= opts.minimum_contig_length,
                ]
                if all(conditions):
                    print(id_contig, file=f_unbinned_list)
        f_unbinned_list.close()

if __name__ == "__main__":
    main()