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

import multiprocessing,os,signal,sys

signal.signal(signal.SIGPIPE, signal.SIG_DFL)

# Display documentation
if len(sys.argv)==1:
  doc="""Usage: tas2bed.py [options] [sites.tsv]
  Executable script to convert mapped TA insertion sites to BED format. 
  Dumps text to stdout. 
  Options include:
  -f  score/depth type (reads,fragments)
  -l  length filter (default 0)
  -n  naming convention ("compact", default "debug")
  -s  score/depth filter (default 0)
"""
  sys.stdout.write(doc)
  sys.exit(0)

# Parse inputs
params={"-l":0,"-n":"debug","-s":-1,"-f":"fragments"}

i=1
while i<len(sys.argv)-1:
  if sys.argv[i] in params:
    if type(params[sys.argv[i]]) is int: 
      try: sys.argv[i+1]=int(sys.argv[i+1])
      except ValueError: 
        sys.stderr.write("Incorrect inputs: check input variables\n")
        sys.exit(1)
    params[sys.argv[i]]=sys.argv[i+1]
  i+=2

filepath=sys.argv[-1]

if filepath=='-':fid=sys.stdin
else:
  if os.path.exists(filepath)==False: 
    sys.stderr.write("Error: check file path.\n")
    sys.exit(1)
  fid=open(filepath,"rbU")

length_filter=int(params["-l"])
naming_convention=params["-n"].lower()
score_filter=int(params["-s"])
feature_type=params["-f"].lower()

if feature_type in ("reads","read","depth"):feature_type="reads"
if feature_type in ("fragments","fragment","frag","frags","uniquereads","uniquereads","unique_reads","unique_read","unique"):feature_type="fragments"

nproc=multiprocessing.cpu_count()-1

refdir="/srv" if sys.platform=="darwin" else "/dev/shm"

while True:
  # Loading data
  line=fid.readline().strip('\n')
  if line=='':break
  if line[0]=='#':continue
  chrom,chromStart,chromEnd,name,lengths,reads,fragments,orientation=line.split('\t')

  # Deriving properties
  reads=[int(i) for i in reads.split('|')]
  lengths=[int(i) for i in lengths.split('|')]
  fragments=[int(i) for i in fragments.split('|')]
  length=max(lengths)
  depths=[i for i in fragments] if feature_type=="fragments" else [i for i in reads]
  score=sum(depths)

  # Applying fiters
  if score==0:continue # skip sites with zero score
  if orientation=='.':continue # skip sites with ambigious sb insertion orientation
  if length<length_filter:continue # skip sites with short reads
  if score<score_filter:continue # skip sites with score less than input value

  if naming_convention=="compact":
    name="%s.reads=%s|%s" %(name,depths[0],depths[1])

  else:
    left="%s.left.bases=%s.reads=%s" %(name,lengths[0],depths[0])
    right="%s.right.bases=%s.reads=%s" %(name,lengths[1],depths[1])

    names=[]
    if depths[0]>0:names.append(left)
    if depths[1]>0:names.append(right)

    name='|'.join(names)

  row=[chrom,chromStart,chromEnd,name,str(score),orientation]

  sys.stdout.write('\t'.join([str(r) for r in row])+'\n')

fid.close()
