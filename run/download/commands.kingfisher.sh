output_directory="../../Fastq/"
mkdir -p ${output_directory}

for id in $(cat ../../identifiers.list); 
do
	job_name="kingfisher__${id}"
	kingfisher get -r ${id} --output-directory  ${output_directory}	-m ena-ftp -f fastq.gz 2> logs/${job_name}.e 1> logs/${job_name}.o
done
