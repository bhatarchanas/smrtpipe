#!/usr/bin/env ruby

require 'optimist'
require 'bio'
require 'fileutils'

opts = Optimist::options do
	opt :smrtpipe, "Path for smrtpipe location", :type => :string, :short => "-p"
	opt :outdir, "Path to the directory where resultant data files should be dumped", :type => :string, :short => "-o"
	opt :samplefile, "File with all the sample information", :type => :string, :short => "-s"
	opt :barcodefile, "File with all the barcodes in a FASTA format", :type => :string, :short => "-b"
end 

##### Assigning variables to the input and making sure we got all the inputs
opts[:smrtpipe].nil?    ==false ? smrt_pipe_path = opts[:smrtpipe]              : abort("Must supply a path where smrtpipe resides with '-p'")
opts[:outdir].nil?      ==false ? out_dir        = opts[:outdir]                : abort("Provide the path to the output directory to dump resultant files with '-o'")
opts[:samplefile].nil?  ==false ? sample_file    = File.open(opts[:samplefile]) : abort("Must supply a 'sample file' which is a tab delimited file of sample information with '-s'")
opts[:barcodefile].nil? ==false ? bc_file        = opts[:barcodefile]           : abort("Must supply a path to where the FASTA file with barcodes exists with '-b'")

pools_hash = {}
samples_hash ={}
barcode_ind = ""
pool_id_ind = ""
path_for_lima_ind = ""
sample_ind = ""

# Make the folder where all the output results will be dumped
unless File.directory?(out_dir)
  FileUtils.mkdir_p(out_dir)
end

# Read sample file and make the required dicts
sample_file.each_with_index do |line, index|
	if index == 0
		header_split = line.chomp.split("\t")
		pool_id_ind = header_split.index("pool_id")
		path_for_lima_ind = header_split.index("path_for_lima")
		barcode_ind = header_split.index("barcode")
		sample_ind = header_split.index("sample")
	else
		entry_split = line.chomp.split("\t")
		pools_hash[entry_split[pool_id_ind]] = entry_split[path_for_lima_ind]
		samples_hash[entry_split[sample_ind]] = [entry_split[barcode_ind], entry_split[pool_id_ind]]
	end
end
#puts pools_hash


pools_hash.each do |each_pool, each_path|
	# Run lima on each pool
	if Dir.exist?("#{out_dir}/#{each_pool}_lima")
		FileUtils.rm_rf("#{out_dir}/#{each_pool}_lima")
		puts "#{smrt_pipe_path} pipeline-id pbsmrtpipe.pipelines.sa3_ds_barcode -e eid_barcode:#{bc_file} -e eid_subread:#{each_path} --preset-json=#{File.expand_path(File.dirname(__FILE__))}/preset_barcoding.json --output-dir=#{out_dir}/#{each_pool}_lima"
		`#{smrt_pipe_path} pipeline-id pbsmrtpipe.pipelines.sa3_ds_barcode -e eid_barcode:#{bc_file} -e eid_subread:#{each_path} --preset-json=#{File.expand_path(File.dirname(__FILE__))}/preset_barcoding.json --output-dir=#{out_dir}/#{each_pool}_lima`
	else
		puts "#{smrt_pipe_path} pipeline-id pbsmrtpipe.pipelines.sa3_ds_barcode -e eid_barcode:#{bc_file} -e eid_subread:#{each_path} --preset-json=#{File.expand_path(File.dirname(__FILE__))}/preset_barcoding.json --output-dir=#{out_dir}/#{each_pool}_lima"
		`#{smrt_pipe_path} pipeline-id pbsmrtpipe.pipelines.sa3_ds_barcode -e eid_barcode:#{bc_file} -e eid_subread:#{each_path} --preset-json=#{File.expand_path(File.dirname(__FILE__))}/preset_barcoding.json --output-dir=#{out_dir}/#{each_pool}_lima`
	end

	# Run ccs on each sample in each pool
	Dir.glob("#{out_dir}/#{each_pool}_lima/tasks/barcoding.tasks.lima-0/*.xml") do |subxml_file|
		puts "CCS input:", subxml_file
		bc_for_file = /.*\/lima_output.(lbc\d+--lbc\d+).subreadset.xml/.match(subxml_file)
		#puts bc_for_file[1]
		if Dir.exist?("#{out_dir}/#{each_pool}_lima_#{bc_for_file[1]}_ccs")
			FileUtils.rm_rf("#{out_dir}/#{each_pool}_lima_#{bc_for_file[1]}_ccs")
			puts "#{smrt_pipe_path} pipeline-id pbsmrtpipe.pipelines.sa3_ds_ccs -e eid_subread:#{subxml_file} --preset-json=#{File.expand_path(File.dirname(__FILE__))}/preset_ccs.json --output-dir=#{out_dir}/#{each_pool}_lima_#{bc_for_file[1]}_ccs"
			`#{smrt_pipe_path} pipeline-id pbsmrtpipe.pipelines.sa3_ds_ccs -e eid_subread:#{subxml_file} --preset-json=#{File.expand_path(File.dirname(__FILE__))}/preset_ccs.json --output-dir=#{out_dir}/#{each_pool}_lima_#{bc_for_file[1]}_ccs`
		else
			puts "#{smrt_pipe_path} pipeline-id pbsmrtpipe.pipelines.sa3_ds_ccs -e eid_subread:#{subxml_file} --preset-json=#{File.expand_path(File.dirname(__FILE__))}/preset_ccs.json --output-dir=#{out_dir}/#{each_pool}_lima_#{bc_for_file[1]}_ccs"
			`#{smrt_pipe_path} pipeline-id pbsmrtpipe.pipelines.sa3_ds_ccs -e eid_subread:#{subxml_file} --preset-json=#{File.expand_path(File.dirname(__FILE__))}/preset_ccs.json --output-dir=#{out_dir}/#{each_pool}_lima_#{bc_for_file[1]}_ccs`
		end
	end
end

# Get a list of all ccs bam files
list_of_ccs_bam = Dir.glob("#{out_dir}/*_lima_*_ccs/tasks/pbccs.tasks.ccs-*/ccs.bam")

# Create directory in pwd which will have all np files
unless File.directory?("np_files")
  	FileUtils.mkdir_p("np_files")
end

# Loop through the ccs bam list, get number of passes from bam file and store it in the np_files directory 
list_of_ccs_bam.each do |each_ccs_bam|
	#puts each_ccs_bam
	ccs_bam_split = each_ccs_bam.split("/")
	#puts ccs_bam_split[4]
	`samtools view #{each_ccs_bam} | cut -f1,15 > np_files/#{ccs_bam_split[4]}_#{ccs_bam_split[6]}.txt`
end	



# Read each of the np files and create a hash with read name and num of passes
np_hash = {}
Dir.glob("np_files/*.txt") do |np_file|
	np_file = File.open(np_file)
	np_file.each do |line|
		line_split = line.split("\t")
		np_hash[line_split[0]] = line_split[1].chomp.split(":")[2]
	end
end
#puts np_hash, np_hash.length


# Create directory in pwd which will have all fastq files
unless File.directory?("reads")
  	FileUtils.mkdir_p("reads")
end

# Loop through each sample, copy files to reads directory in pwd, report missing files
samples_hash.each do |key, value|
	#puts key, value.inspect
	ccs_bc = value[0].to_i - 1
	if File.exists?("#{out_dir}/#{value[1]}_lima_lbc#{value[0]}--lbc#{value[0]}_ccs/tasks/pbcoretools.tasks.bam2fastq_ccs-0/ccs.fastq.zip")
		FileUtils.cp("#{out_dir}/#{value[1]}_lima_lbc#{value[0]}--lbc#{value[0]}_ccs/tasks/pbcoretools.tasks.bam2fastq_ccs-0/ccs.fastq.zip", "reads/#{key}.fastq.zip")
		`unzip -o reads/#{key}.fastq.zip && mv ccs.unknown.*.fastq reads/#{key}.fastq`
	else
		puts "Missing file #{key}.fastq"
	end
end

# Create directory in pwd which will have all mod headers fastqs files
unless File.directory?("reads_2")
  	FileUtils.mkdir_p("reads_2")
end

# Loop through all the files in reads directory
Dir.glob("reads/*.fastq") do |fastq_file|
	#puts fastq_file
	fastq_file_name = /reads\/(.*).fastq/.match(fastq_file)
	#puts fastq_file_name[1]
	fastq_open = Bio::FlatFile.auto(fastq_file)
	fq_out_file = File.open("reads_2/#{fastq_file_name[1]}_mod_headers.fastq", "w")
	fastq_open.each do |entry|
		fq_out_file.puts("@#{entry.definition};barcodelabel=#{fastq_file_name[1]};ccs=#{np_hash[entry.definition]};")
		fq_out_file.puts(entry.naseq.upcase)
		fq_out_file.puts("+")
		fq_out_file.puts(entry.quality_string)
	end
end


