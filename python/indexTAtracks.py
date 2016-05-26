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
    if chrom!='':subfun(chrom,lines)
    chrom=line[1:]
    lines=[]

if chrom!='':subfun(chrom,lines)

fid.close()
