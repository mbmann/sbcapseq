#!/usr/bin/env python

# Copyright (C) 2016 Justin Y. Newberg
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import json,marshal,multiprocessing,os,shlex,signal,sys
from subprocess import Popen,PIPE

signal.signal(signal.SIGPIPE,signal.SIG_DFL)

# standalone copies of library functions
def tag2compliment(tag):
  rosetta={'A':'T','a':'t','C':'G','c':'g','G':'C','g':'c','T':'A','t':'a','N':'N','n':'n'}
  return ''.join([rosetta[i] for i in tag[::-1]])

def sam_flag(x):
  binstr=bin(x)[2:][::-1]
  return [2**i for i in xrange(len(binstr)) if binstr[i]=='1']

def cigar_length(x):
  index,s={},''
  for i in x:
    if ord(i)<65:s+=i
    else:
      if i not in index: index[i]=0
      index[i]+=int(s)
      s=''
  value=index['M'] if 'M' in index else 0
  value+=index['D'] if 'D' in index else 0
  return value

# functions specific to this script
def bam_dump(outputpath,stdin):
  args=shlex.split("samtools view -F4 -uhS - ")
  pipe=Popen(args, stdout=PIPE, stdin=PIPE, stderr=PIPE)
  stdout=pipe.communicate(input=stdin)[0]

  args=shlex.split("samtools sort -m 4G -o - - ")
  pipe=Popen(args, stdout=PIPE, stdin=PIPE, stderr=PIPE)
  stdout2=pipe.communicate(input=stdout)[0]
  open(outputpath,'wb').write(stdout2)

# Display documentation
if len(sys.argv)==1:
  doc='''Usage: fastq2tas.py [indexdir] [sequences.fastq]
  Executable script to maps SBCapture sequencing reads to TA sites.
  Writes results to an output directory derived from the input filename or a user-specified name.
  Options include:
  -n  dataset name, disabled if called with '' (default)
  -o  output folder (default '', gleaned from input file name if called with '')
  -q  mapq filter (default 30)

  --verbose  enable if you want to run additional QC, requires more disk space and time
'''
  sys.stdout.write(doc)
  sys.exit(0)


params={"-n":'',"-o":'',"-q":30,"--verbose":False}

# Parse inputs
i=1
while i<len(sys.argv)-2:
  param=sys.argv[i]
  if param in params:
    if param[:2]=="--":
      params[param]=True
    else:
      if param[0]=='-':
        value=sys.argv[i+1]
        if type(value)==type(params[param]):
          params[param]=value
          i+=1
  i+=1

indexdir=os.path.abspath(os.path.expanduser(os.path.normpath(sys.argv[-2].replace('\\','/'))))

refpath="%s/mm9/onc2.fa"%indexdir
featurepath="%s/onc2/features.fa"%indexdir
taindpath="%s/mm9/onc2.ta.gz"%indexdir

filepath=sys.argv[-1]

if filepath=='-':
  if params["-o"]!='':workdir=params["-o"]
  else:
    sys.stderr.write("Error: need to define WORKDIR if using stdin. Exiting.\n")
    sys.exit(1)
  fid=sys.stdin
else:
  filepath=os.path.abspath(os.path.expanduser(os.path.normpath(filepath.replace('\\','/'))))
  workdir=params["-o"] if params["-o"]!='' else '.'.join(filepath.split('.')[:-1])
  if os.path.exists(filepath)==False: 
    sys.stderr.write("Error: check file path.\n")
    sys.exit(1)
  fid=open(filepath,"rbU")

projectName=params["-n"]
workdir=params["-o"] if params["-o"]!='' else '.'.join(filepath.split('.')[:-1])
mapqfilt=int(params["-q"])

verbose=params["--verbose"]

outname=workdir

nproc=multiprocessing.cpu_count()-1

# Create working directory
if os.path.exists(workdir)==False:os.makedirs(workdir)

# Define transposon specific tags
tag="TACAGTTGAAGTCGG"
tag_=tag2compliment(tag)

bamhi="GGATCCCTA"
bamhi_=tag2compliment(bamhi)

# Initialize count dictionary used in breakdown
log_index={"reads":0,"IRDR":0,"IRDR_novector":0,"IRDR_novector_mouse":0,"IRDR_novector_mouse_onc2":0}

# Get fastq data annotate reads
read_index={}
while True:
  header=fid.readline().strip("\r\n").strip('\r').strip('\n')
  sequence=fid.readline().strip("\r\n").strip('\r').strip('\n')
  _=fid.readline().strip("\r\n").strip('\r').strip('\n')
  phred=fid.readline().strip("\r\n").strip('\r').strip('\n')
  if header=='':break

  log_index["reads"]+=1

  key=header[1:]
  ind={"sequence":sequence,
       "phred":phred,
       "transposon_status":"noIRDR",
       "read_order":"unknown",
       "tag_position_cutoff":-1}

  seqLength=len(phred)
  #seqLength=quality_filter_location(phred,15)
  ind["quality_position_cutoff"]=seqLength #assuming input reads are already quality trimmed

  if ind["quality_position_cutoff"]>=20:
    juncPos=sequence.find(tag)
    if juncPos>-1:
      log_index["IRDR"]+=1
      ind["tag_position_cutoff"]=juncPos+1
      ind["read_order"]="mouse,transposon,clipped"
      if (juncPos>=20) & (seqLength>juncPos+15):
        if sequence[:juncPos].find(bamhi)==-1:
          log_index["IRDR_novector"]+=1
          ind["transposon_status"]="IRDR_novector"
        else:
          ind["transposon_status"]="IRDR_vector"
    else:
      juncPos=sequence.find(tag_)
      if juncPos>-1:
        log_index["IRDR"]+=1
        ind["tag_position_cutoff"]=juncPos+len(tag_)-1
        ind["read_order"]="transposon,mouse,clipped"
        if (juncPos>=20) & (seqLength>juncPos+15):
          if sequence[juncPos:].find(bamhi_)==-1:
            log_index["IRDR_novector"]+=1
            ind["transposon_status"]="IRDR_novector"
          else:
            ind["transposon_status"]="IRDR_vector"

  if ind["transposon_status"]=="IRDR_novector":read_index[key]=ind

fid.close()

# Using read_index, generate mouse and transposon fastq files for alignment
mouse,transposon,clipped=[],[],set()
for key in read_index:
  if read_index[key]["transposon_status"]!="IRDR_novector":continue

  sequence=read_index[key]["sequence"]
  phred=read_index[key]["phred"]
  juncPos=read_index[key]["tag_position_cutoff"]
  trimPos=read_index[key]["quality_position_cutoff"]
  if len(sequence[trimPos:]): clipped.add(key)

  seq1="@%s\n%s\n+\n%s" %(key,sequence[:juncPos+1],phred[:juncPos+1])
  seq2="@%s\n%s\n+\n%s" %(key,sequence[juncPos-1:trimPos],phred[juncPos-1:trimPos])

  if read_index[key]["read_order"]=="mouse,transposon,clipped":
    mouse.append(seq1)
    transposon.append(seq2)

  if read_index[key]["read_order"]=="transposon,mouse,clipped":
    transposon.append(seq1)
    mouse.append(seq2)

log_index["IRDR_vector"]=log_index["IRDR"]-log_index["IRDR_novector"]

# Align mouse read-portions to reference
stdin='\n'.join(mouse)
cmd="bowtie2 -p %s --very-sensitive -x %s -" %(nproc,".".join(refpath.split(".")[:-1]))
args=shlex.split(cmd)
pipe=Popen(args,stdout=PIPE,stdin=PIPE,stderr=PIPE)
stdout,mouse_log=pipe.communicate(input=stdin)

# output unfiltered reads that map to mouse reference
if verbose:bam_dump("%s/mouse.bam"%workdir,stdout)

# Annotate reads with mouse information
references=[]
sequence_index={}
mousefail=[0,0,0,0]
log_index["IRDR_novector_onc2"]=0
log_index["IRDR_novector_XS"]=0
log_index["IRDR_novector_unmapped"]=0
log_index["IRDR_novector_mapq"]=0
for line in stdout.strip('\n').split('\n'):
  if (line[0]=='@'):references.append(line)
  else:
    row=line.split('\t')
    header,flag,chrom,position,mapq,cigar,sequence,phred=row[0],row[1],row[2],int(row[3]),int(row[4]),row[5],row[9],row[10]

    flags=sam_flag(int(row[1]))

    if chrom=="onc2":
      log_index["IRDR_novector_onc2"]+=1
      continue
    if line.find("XS:i:")+1:
      log_index["IRDR_novector_XS"]+=1
      continue
    if 4 in flags:
      log_index["IRDR_novector_unmapped"]+=1
      continue
    if mapq<mapqfilt:
      log_index["IRDR_novector_mapq"]+=1
      continue

    log_index["IRDR_novector_mouse"]+=1

    genome_length=cigar_length(cigar)

    strand='-' if 16 in flags else '+'
    read_order=read_index[header]["read_order"]
    if (read_order=="mouse,transposon,clipped") & (strand=='+'):tasite=position+genome_length-2
    if (read_order=="transposon,mouse,clipped") & (strand=='-'):tasite=position+genome_length-2
    if (read_order=="transposon,mouse,clipped") & (strand=='+'):tasite=position
    if (read_order=="mouse,transposon,clipped") & (strand=='-'):tasite=position
    sequence_index[header]={"strand":strand,
                            "chrom":chrom,
                            "position":position,
                            "cigar":cigar,
                            "sequence":sequence,
                            "phred":phred,
                            "mapq":mapq,
                            "flag":flag,
                            "trimmed_read_length":genome_length,
                            "tasite":tasite,
                            "side":"unknown"}

# Align transposon read-portions to reference
stdin='\n'.join(transposon)
args=shlex.split("bowtie2 -p %s --very-sensitive -x %s -" %(nproc,".".join(featurepath.split(".")[:-1])))
pipe=Popen(args, stdout=PIPE, stdin=PIPE, stderr=PIPE)
stdout,transposon_log=pipe.communicate(input=stdin)

if verbose:bam_dump("%s/transposon.bam"%workdir,stdout)

# Annotate reads with transposon information
headers=set(sequence_index.keys())
sbfail=[0,0,0,0]
log_index["IRDR_novector_mouse_XS"]=0
log_index["IRDR_novector_mouse_mapq"]=0
log_index["IRDR_novector_mouse_vector"]=0
for line in stdout.strip('\n').split('\n'):
  if (line[0]=='@'):continue
  row=line.split('\t')
  header,flag,reference,read_position,mapq,cigar=row[0],row[1],row[2],int(row[3]),int(row[4]),row[5]

  if header not in headers:
    continue
  if line.find("XS:i:")!=-1:
    log_index["IRDR_novector_mouse_XS"]+=1
    continue
  if mapq<mapqfilt:
    log_index["IRDR_novector_mouse_mapq"]+=1
    continue
  if reference!="Transposon":
    log_index["IRDR_novector_mouse_vector"]+=1
    continue

  log_index["IRDR_novector_mouse_onc2"]+=1

  read_order=read_index[header]["read_order"]
  mouse_strand=sequence_index[header]["strand"]
  mouse_sequence=sequence_index[header]["sequence"]
  mouse_position=sequence_index[header]["position"]
  mouse_phred=sequence_index[header]["phred"]
  mouse_cigar=sequence_index[header]["cigar"]
  transposon_sequence_length=cigar_length(cigar)-2
  mouse_sequence_length=cigar_length(sequence_index[header]["cigar"])-1

  if (read_order=="mouse,transposon,clipped") & (mouse_strand=='+'):
    sequence=mouse_sequence+''.join(['N' for nt in xrange(transposon_sequence_length)])
    phred=mouse_phred+''.join(['M' for nt in xrange(transposon_sequence_length)])
    cigar=mouse_cigar+"%sM"%transposon_sequence_length
    position=mouse_position
    readstart=position
    label="mtp"
  if (read_order=="transposon,mouse,clipped") & (mouse_strand=='+'):
    sequence=''.join(['N' for nt in xrange(transposon_sequence_length)])+mouse_sequence
    phred=''.join(['M' for nt in xrange(transposon_sequence_length)])+mouse_phred
    cigar="%sM"%transposon_sequence_length+mouse_cigar
    position=mouse_position-transposon_sequence_length
    readstart=position
    label="tmp"
  if (read_order=="transposon,mouse,clipped") & (mouse_strand=='-'):
    sequence=mouse_sequence+''.join(['N' for nt in xrange(transposon_sequence_length)])
    phred=mouse_phred+''.join(['M' for nt in xrange(transposon_sequence_length)])
    cigar=mouse_cigar+"%sM"%transposon_sequence_length
    position=mouse_position
    readstart=position+mouse_sequence_length+1+transposon_sequence_length
    label="ttm"
  if (read_order=="mouse,transposon,clipped") & (mouse_strand=='-'):
    sequence=''.join(['N' for nt in xrange(transposon_sequence_length)])+mouse_sequence
    phred=''.join(['M' for nt in xrange(transposon_sequence_length)])+mouse_phred
    cigar="%sM"%transposon_sequence_length+mouse_cigar
    position=mouse_position-transposon_sequence_length
    readstart=mouse_position+mouse_sequence_length+1
    label="mtm"
  sequence_index[header]["side"]="IRDRL" if read_position<1200 else "IRDRR"
  sequence_index[header]["sequence"]=sequence
  sequence_index[header]["phred"]=phred
  sequence_index[header]["cigar"]=cigar
  sequence_index[header]["position"]=position
  sequence_index[header]["readstart"]=readstart
  sequence_index[header]["label"]=label


# Pre-cache tabix sites for speed boost
sites=set()
for header in sequence_index:
  if header in clipped: continue
  chrom,tasite,side,readstrand=sequence_index[header]["chrom"],int(sequence_index[header]["tasite"]),sequence_index[header]["side"],sequence_index[header]["strand"]
  sites.add("%s:%s-%s" %(chrom,tasite,int(tasite)+1))

sites=sorted(sites)

#print taindpath
tabix_index={}
buffer=[]
for i in xrange(len(sites)):
  buffer.append(sites[i])
  if i%2000==0:
    cmd="tabix %s %s" %(taindpath,' '.join(buffer))
    args=shlex.split(cmd)
    pipe=Popen(args,stdout=PIPE,stdin=None,stderr=PIPE)
    stdout=pipe.communicate()[0]
    for line in stdout.strip('\n').split('\n'):
      row=line.split('\t')
      site="%s:%s" %(row[0],row[1])
      tabix_index[site]=row[3]
    buffer=[]

if buffer!=[]:
  cmd="tabix %s %s" %(taindpath,' '.join(buffer))
  args=shlex.split(cmd)
  pipe=Popen(args,stdout=PIPE,stdin=None,stderr=PIPE)
  stdout=pipe.communicate()[0]
  for line in stdout.strip('\n').split('\n'):
    row=line.split('\t')
    site="%s:%s" %(row[0],row[1])
    tabix_index[site]=row[3]
  buffer=[]

# Index sites
fragments=set()
site_index={}
sites={}
for header in sequence_index:
  if header in clipped: continue
  read_order=read_index[header]["read_order"]
  name=header.split(":")[0] if projectName=="" else projectName
  chrom,tasite,side,readstrand=sequence_index[header]["chrom"],int(sequence_index[header]["tasite"]),sequence_index[header]["side"],sequence_index[header]["strand"]

  # Reposition tasite to start of TA-repeat region
  site="%s:%s" %(chrom,tasite)
  if site not in sites:
    sites[site]=None if site not in tabix_index else tabix_index[site]

  if sites[site]==None:continue
  tasite=int(sites[site])

  if (read_order=="mouse,transposon,clipped") & (readstrand=='+'):feature_order="mouse,transposon"
  if (read_order=="mouse,transposon,clipped") & (readstrand=='-'):feature_order="transposon,mouse"
  if (read_order=="transposon,mouse,clipped") & (readstrand=='+'):feature_order="transposon,mouse"
  if (read_order=="transposon,mouse,clipped") & (readstrand=='-'):feature_order="mouse,transposon"

  orientation="."
  if (feature_order=="mouse,transposon") & (side=="IRDRL"):orientation='+'
  if (feature_order=="transposon,mouse") & (side=="IRDRR"):orientation='+'
  if (feature_order=="mouse,transposon") & (side=="IRDRR"):orientation='-'
  if (feature_order=="transposon,mouse") & (side=="IRDRL"):orientation='-'

  ind=0 if feature_order=="mouse,transposon" else 1

  chromStart,chromEnd=tasite-1,tasite
  site=(chrom,chromStart,chromEnd,name)
  if site not in site_index:site_index[site]={"orientation":{'+':0,'-':0,'.':0},"reads":[0,0],"lengths":[0,0],"unique_reads":[0,0]}

  site_index[site]["orientation"][orientation]+=1
  site_index[site]["reads"][ind]+=1
  site_index[site]["lengths"][ind]=max(sequence_index[header]["trimmed_read_length"],site_index[site]["lengths"][ind])

  if "readstart" in sequence_index[header]:
    fragment=(feature_order,sequence_index[header]["readstart"])
    if fragment not in fragments: 
      site_index[site]["unique_reads"][ind]+=1
      fragments.add(fragment)

sites=[]
log_index["mapped_reads"]=0
for site in sorted(site_index.keys()):
  chrom,chromStart,chromEnd,name=site
  chromStart,chromEnd=chromStart+1,chromEnd+1
  log_index["mapped_reads"]+=site_index[site]["reads"][0]+site_index[site]["reads"][1]

  orientation='.'
  if site_index[site]["orientation"]['+']>site_index[site]["orientation"]['-']:orientation='+'
  if site_index[site]["orientation"]['+']<site_index[site]["orientation"]['-']:orientation='-'

  lengths='|'.join([str(i) for i in site_index[site]["lengths"]])
  reads='|'.join([str(i) for i in site_index[site]["reads"]])
  unique_reads='|'.join([str(i) for i in site_index[site]["unique_reads"]])

  sites.append([chrom,str(chromStart),str(chromEnd),name,str(lengths),str(reads),str(unique_reads),str(orientation)])

log_index['sites']=len(sites)

fid_tsv=open("%s/insertions.txt"%workdir,"wb")
fid_tsv.write("#chrom\tchromStart\tchromEnd\tname\tlengths\treads\tunique_reads\torientation\n")
fid_tsv.write('\n'.join(['\t'.join(site) for site in sites])+'\n')
fid_tsv.close()

fid_log=open("%s/log.json"%workdir,"wb")
fid_log.write(json.dumps(log_index)+'\n')
fid_log.close()

if verbose:
  rows=[]
  for header in sequence_index:
    if "readstart" in sequence_index[header]:
      flag,chrom,position,mapq,cigar,sequence,phred=sequence_index[header]["flag"],sequence_index[header]["chrom"],str(sequence_index[header]["position"]),str(sequence_index[header]["mapq"]),sequence_index[header]["cigar"],sequence_index[header]["sequence"],sequence_index[header]["phred"]
      rows.append([header,flag,chrom,position,mapq,cigar,'*','0','0',sequence,phred])

  stdin='\n'.join(references)+'\n'+'\n'.join(['\t'.join(row) for row in rows])+'\n'
  bam_dump("%s/filtered.bam"%workdir,stdin)
