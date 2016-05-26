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

import signal,sys

# Make pipeline friendly output for head and tail commands
signal.signal(signal.SIGPIPE, signal.SIG_DFL)


def argsort(seq):
  return sorted(range(len(seq)), key = seq.__getitem__)

if len(sys.argv)==1:
  doc='''Usage: maskbed.py [mask.bed] [sites.bed]
  Executable script to mask insertions sites from a bedfile.
  Dumps text to stdout.
  Bedfile have a format of:
  [chrom] [taStart] [taEnd] [name] [reads] [orientation]
'''
  sys.stdout.write(doc)
  sys.exit(0)

command = sys.argv[1]

if sys.argv[-1]=='-':fid=sys.stdin
else:fid=open(sys.argv[-1])

mask=set(['\t'.join(row.split('\t')[:2]) for row in open(sys.argv[-2],'rbU').read().strip('\n').split('\n')])

while True: 
  line = fid.readline().strip('\r\n').strip('\r').strip('\n')
  if line=='':break
  if (line[0]=='#') | (line[:5]=='track'):
    print(line)
    continue
  row=line.split('\t')
  if '\t'.join(row[:2]) not in mask:print(line)

fid.close()
