#!/usr/bin/env python

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
