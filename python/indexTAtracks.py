#!/usr/bin/env python

import re,sys

def subfun(chrom,lines):
  sequence=''.join(lines).upper()
  sites=[m.start() for m in re.finditer("TA",sequence)]

  st=sites[0]
  starts=[st]
  w=2
  for i in sites[1:]:
    if i!=st+w:st,w=i,2
    else:w+=2
    starts.append(st)

  en=sites[-1]
  ends=[en+1]
  w=2
  for i in reversed(sites[:-1]):
    if i!=en-w:en,w=i,2
    else:w+=2
    ends.append(en+1)

  ends=ends[::-1]

  repeats=[(ends[i]-starts[i]-1)/2 for i in xrange(len(sites))]

  sys.stdout.write('\n'.join(["%s\t%s\t%s\t%s\t%s" %(chrom,sites[i]+1,sites[i]+2,starts[i]+1,repeats[i]+1) for i in xrange(len(sites))])+'\n')

  return


# Display documentation
if len(sys.argv)==1:
  doc="""Usage: indexTAtracks.py [reference.fa]
  Executable script to index all repeat-TA tracks in reference genome.
  Dumps text to stdout.
"""
  sys.stdout.write(doc)
  sys.exit(0)

if sys.argv[-1]=='-':fid=sys.stdin
else:fid=open(sys.argv[-1],"rbU")

chrom=''
lines=[]

#for line in lines:
while True:
  line=fid.readline().strip('\n')
  if line=='':break
  if line[0]!='>':
    lines.append(line)
  else:
    if chrom!='':run_thing(chrom,lines)
    chrom=line[1:]
    lines=[]

if chrom!='':subfun(chrom,lines)

fid.close()
