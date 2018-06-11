#Program: compile-data.py
#Author: Daniel Hawthorne
#Python: 3.6.2

import os  #for files in folder

rawFolder = r"X:\Google Drive\School\Dissertation\Results\Raw"
fields = ["date_time", "system_hash", "uuid", "device_id", "cpu_model", "cpu_sig", "cpu_arch", "memory", "aes_inst", "aes_bench", "flops_bench"]

outFile = open("results.csv", 'w')

#write fields as headers
outFile.write(','.join(fields) + '\n')

for fileName in os.listdir(rawFolder):

    if fileName.endswith('.txt'):
        print(fileName)
        #open, read, close the file
        recordFile = open(os.path.join(rawFolder,fileName), 'r')
        fileLines = list(filter(None, recordFile.read().splitlines()))
        recordFile.close()
        lines = []
        for line in fileLines:
            #remove any commas from cpu strings
            line = line.replace(',', '_')
            #fields
            if len(line.split()) > 1:
                lines.append('_'.join(line.split()[1:]))
            else:
                lines.append('')
            #last line
            if line.startswith('flops_bench'):
                lines.append('\n')
                outFile.write(','.join(lines))
                lines = []
outFile.close()
        
