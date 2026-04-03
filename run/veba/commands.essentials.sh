module="essentials"
job_name="${module}"
/usr/bin/time -v veba --module ${module} --params "-i ../../Analysis/veba_output/ -o ../../Analysis/veba_output/essentials/" 2> logs/${job_name}.e 1> logs/${job_name}.o
