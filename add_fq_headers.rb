#!/usr/bin/env ruby

require 'optimist'
require 'bio'
require 'fileutils'

=begin
This script is to add important header information to the ccs fastq files, including the barcode label and number of passes
Some important assumptions are made with this script, including the bam file format for pacbio outputs doesn't change
and that the standard 96 barcodes are used for pacbio (because of how pacbio labels each file with the forward and reverse barcode id)
Currently only works with symmetrical barcodes
=end


opts = Optimist::options do
	opt :bam_dir,     "Path to demultiplexed ccs bam files (where 'tasks', 'html', etc. folders exist)", type: :string, short: "-d", required: true
	opt :outdir,      "Output directory of modified fastq files", type: :string, short: "-o", default: "correct_header_fqs"
	opt :samplefile,  "File with all sample information", type: :string, short: "-s", required: true
	opt :barcodefile, "File with all barcodes in a FASTA format", type: :string, short: "-b", required: true
end 

File.directory?(opts[:bam_dir])  ? bam_dir     = opts[:bam_dir]     : abort("Directory to Bam files must exist and be a directory")
File.exists?(opts[:samplefile])  ? sample_file = opts[:samplefile]  : abort("'sample file' must exist: a tab delimited file of sample information")
File.exists?(opts[:barcodefile]) ? bc_file     = opts[:barcodefile] : abort("Barcode fasta file must exist")

#Not in the options list, but required for the completion of this script
abort("Missing the ccs.fastq.zip file in your #{bam_dir}!") unless File.exists?("#{bam_dir}/tasks/pbcoretools.tasks.bam2fastq_ccs-0/ccs.fastq.zip")

# Get a list of all ccs bam files
list_of_ccs_bam = Dir.glob("#{bam_dir}/tasks/pbccs.tasks.ccs-*/ccs.bam")
abort("No bam files found!") if list_of_ccs_bam.empty?

#Initialize hash and output file, then loop through bams, read pass number and header for each ccs read into hash
np_hash = {}
passes_file = File.open("all_passes.tsv", 'w')

list_of_ccs_bam.each do |each_ccs_bam|
	`samtools view #{each_ccs_bam} | cut -f1,15`.split("\n").each do |r|
		pass = r.split("\t")
		#Sanity check - read names are unique right?
		abort("Whoa, we've seen this read header before! #{r}") if np_hash.has_key?(pass[0])
		#Parse out the actual passes - POTENTIAL FOR THIS TO BREAK IF PACBIO BAM FILE FORMAT CHANGES
		abort("Whoa, this doesn't look like the number of passes: #{r}") unless num_pass = pass[1].gsub(/np:i:/, '')
		#Finally add these to the hash and ouput file
		np_hash[pass[0]] = num_pass
		passes_file.puts("#{pass[0]}\t#{num_pass}")
	end
end	

passes_file.close

# Create temporary location for the OG fastq files
FileUtils.mkdir_p("tmp") unless File.directory?("tmp")

#Fancy dataframe fun with daru
samp_info = Daru::DataFrame.from_csv(sample_file, opts = {:col_sep => "\t"})

#Unzip the ccs fastqs and put them in a temporary directory
`unzip -o #{bam_dir}/tasks/pbcoretools.tasks.bam2fastq_ccs-0/ccs.fastq.zip -d tmp `

# Create directory in pwd which will have all mod headers fastqs files
FileUtils.mkdir_p(opts[:outdir]) unless File.directory?(opts[:outdir])


# Loop through all the files in reads directory
Dir.glob("tmp/*.fastq") do |fastq_file|
	fq_basename = File.basename(fastq_file, '.fastq')
	bc_num = /\.+(\d+).+/.match(fq_basename)[0]
	samp_name = samp_info.where(samp_info['barcode'].eq(bc_num))['sample'].to_a[0]
	fastq_open = Bio::FlatFile.auto(fastq_file)
	fq_out_file = File.open("#{opts[:outdir]}/#{samp_name}.fq", "w")
	fastq_open.each do |entry|
		fq_out_file.puts("@#{entry.definition};barcodelabel=#{fq_basename};ccs=#{np_hash[entry.definition]};")
		fq_out_file.puts(entry.naseq.upcase)
		fq_out_file.puts("+")
		fq_out_file.puts(entry.quality_string)
	end
end

#remove the tmp dir
FileUtils.rm_rf('tmp')