#!/usr/bin/env bash

rootdir="$HOME/nnlab/sbcapseq"
execdir="$rootdir/bin"
srcdir="$rootdir/var/src"
buildir="$rootdir/var/build"
logdir="$rootdir/var/log"
srvdir="$rootdir/srv"
indexdir="$srvdir/mm9"
transposondir="$srvdir/onc2"

mkdir -p "$execdir" "$srcdir" "$buildir" "$logdir" "$indexdir" "$transposondir"

export PATH=$execdir:$PATH

########################################################

toolbox="tabix"
version="0.2.6"
release="$toolbox"-"$version"
if [ ! -f "$srcdir"/"$release".tar.bz2 ]; then curl -L http://sourceforge.net/projects/samtools/files/"$toolbox"/"$release".tar.bz2 > "$srcdir"/"$release".tar.bz2; fi
if [ ! -f "$execdir"/tabix ]; then
  rm -rf "$buildir"/"$release"
  tar -xf "$srcdir"/"$release".tar.bz2 -C "$buildir"
  cd "$buildir"/"$release"
  make > "$logdir"/"$toolbox".make.stdout 2> "$logdir"/"$toolbox".make.stderr
  cp tabix "$execdir"
  cp bgzip "$execdir"
fi

toolbox="samtools"
version="0.1.19"
release="$toolbox"-"$version"
if [ ! -f "$srcdir"/"$release".tar.bz2 ]; then curl -L http://sourceforge.net/projects/samtools/files/"$toolbox"/"$version"/"$release".tar.bz2 > "$srcdir"/"$release".tar.bz2; fi
if [ ! -f "$execdir"/samtools ]; then
  rm -rf "$buildir"/"$release"
  tar -xf "$srcdir"/"$release".tar.bz2 -C "$buildir"
  cd "$buildir"/"$release"
  make > "$logdir"/"$toolbox".make.stdout 2> "$logdir"/"$toolbox".make.stderr
  cp samtools "$execdir"
fi

toolbox="bowtie2"
version="2.2.5"
release="$toolbox"-"$version"
if [ ! -f "$srcdir"/"$release"-source.zip ]; then curl -L http://sourceforge.net/projects/bowtie-bio/files/"$toolbox"/"$version"/"$release"-source.zip > "$srcdir"/"$release"-source.zip; fi
if [ ! -f "$execdir"/bowtie2 ]; then
  rm -rf "$buildir"/"$release"
  unzip -qq "$srcdir"/"$release"-source.zip -d "$buildir"
  cd "$buildir"/"$release"
  make > "$logdir"/"$toolbox".make.stdout 2> "$logdir"/"$toolbox".make.stderr
  cp bowtie2 bowtie2-align-l bowtie2-align-s bowtie2-build bowtie2-build-l bowtie2-build-s bowtie2-inspect bowtie2-inspect-l bowtie2-inspect-s "$execdir"
fi

toolbox="Python"
version="2.7.6"
release="$toolbox"-"$version"
if [ ! -f "$srcdir"/"$release".tgz ]; then curl -L https://www.python.org/ftp/python/"$version"/"$release".tgz > "$srcdir"/"$release".tgz; fi
if [ ! -f "$execdir"/python ]; then
  rm -rf "$buildir"/"$release"
  tar zxf "$srcdir"/"$release".tgz -C "$buildir"
  cd "$buildir"/"$release"
  ./configure --prefix="$rootdir" > "$logdir"/"$toolbox".configure.stdout 2> "$logdir"/"$toolbox".configure.stderr
  make > "$logdir"/"$toolbox".make.stdout 2> "$logdir"/"$toolbox".make.stderr
  make install > "$logdir"/"$toolbox".install.stdout 2> "$logdir"/"$toolbox".install.stderr
fi

########################################################

if [ ! -f "$indexdir"/chromFa.tar.gz ]; 
then
  echo "Downloading mm9 reference"
  curl http://hgdownload.soe.ucsc.edu/goldenPath/mm9/bigZips/chromFa.tar.gz > "$indexdir"/chromFa.tar.gz
fi

echo "Defining transposon vector sequence"
echo ">onc2
ccattcgccattcaggctgcgcaactgttgggaagggcgatcggtgcggg
cctcttcgctattacgccagctggcgaaagggggatgtgctgcaaggcga
ttaagttgggtaacgccagggttttcccagtcacgacgttgtaaaacgac
ggccagtgagcgcgcgtaatacgactcactatagggcgaattggagctcg
gatccctatacagttgaagtcggaagtttacatacacttaagttggagtc
attaaaactcgtttttcaactactccacaaatttcttgttaacaaacaat
agttttggcaagtcagttaggacatctactttgtgcatgacacaagtcat
ttttccaacaattgtttacagacagattatttcacttataattcactgta
tcacaattccagtgggtcagaagtttacatacactaagttgactgtgcct
ttaaacagcttggaaaattccagaaaatgatgtcatggctttagaagctt
gatggccgctctagaactaggattgcagcacgaaacaggaagctgactcc
acatggtcacatgctcactgaagtgttgacttccctgacagctgtgcact
ttctaaaccggttttctcattcatttacagttcagccgatgatgaaattg
ccgcactggttgttagcaacgtagccggtatgtgaaagatggattcgcgg
gaatttagtggatcccccgggctgcaggaattcgatctgaagcctataga
gtacgagccatagataaaataaaagattttatttagtctccagaaaaagg
ggggaatgaaagaccccacctgtaggtttggcaagctagcttaagtaacg
ccattttgcaaggcatggaaaatacataactgagaatagagaagttcaga
tcaaggttaggaacagagagacagcagaatatgggccaaacaggatatct
gtggtaagcagttcctgccccggctcagggccaagaacagatggtcccca
gatgcggtcccgccctcagcagtttctagagaaccatcagatgtttccag
ggtgccccaaggacctgaaaatgaccctgtgccttatttgaactaaccaa
tcagttcgcttctcgcttctgttcgcgcgcttctgctccccgagctcaat
aaaagagcccacaacccctcactcggcgcgccagtcctccgatagactgc
gtcgcccatcaagcttgctactagcaccagaacgcccgcgaggatctctc
aggtaataaagagcgccaaggctggctgcaagcggagcctctgagagcct
ctgagggccagggctactgcacccttggtcctcaacgctggggtcttcag
aactagaatgctgggggtggggtggggattcggttccctattccatcgcg
cgttaagatacattgatgagtttggacaaaccacaactagaatgcagtga
aaaaaatgctttatttgtgaaatttgtgatgctattgctttatttgtaac
cattataagctgcaataaacaagttggccgctcctgtgccagactctggc
gccgctgctctgtcaggtacctgttggtctgaaactcagccttgagcctc
tggagctgctcagcagtgaaggctgtgcgaggccgcttgtcctctttgtt
agggttcttcttctttggttttcgggacctgggacctggttgtcatggag
gagaaagggcagaggttactggttgctggagtctagctacttatccacaa
cccacgcacccaagcttgaggttgcagatactgggggtgggggggggggg
atgacccgcccaaggccatacaagtgttgggcattgggggtggtgatata
aacttgaggctgggcatgtgcccactgaccagaaggaaagtggtgtgtgt
gtgtgaaaatgagatggattggcagatgtagctaaaaggcctatcacaaa
ctaggggatctagcttgtggaaggctactcgaaatgtttgacccaagtta
aacaatttaaaggcaatgctaccaaatactaattgagtgtatgtaaactt
ctgacccactgggaatgtgatgaaagaaataaaagctgaaatgaatcatt
ctctctactattattctgatatttcacattcttaaaataaagtggtgatc
ctaactgacctaagacagggaatttttactaggattaaatgtcaggaatt
gtgaaaaagtgagtttaaatgtatttggctaaggtgtatgtaaacttccg
acttcaactgtatagggatcctctagctagagtcgacctcgagggggggc
ccggtacccagcttttgttccctttagtgagggttaatttcgagcttggc
gtaatcatggtcatagctgtttcctgtgtgaaattgttatccgctcacaa
ttccacacaacatacgagccggaagcataaagtgtaaagcctggggtgcc
taatgagtgagctaactcacattaattgcgttgcgctcactgcccgcttt
ccagtcgggaaacctgtcgtgccagctgcattaatgaatcggccaacgcg
cggggagaggcggtttgcgtattgggcgctcttccgcttcctcgctcact
gactcgctgcgctcggtcgttcggctgcggcgagcggtatcagctcactc
aaaggcggtaatacggttatccacagaatcaggggataacgcaggaaaga
acatgtgagcaaaaggccagcaaaaggccaggaaccgtaaaaaggccgcg
ttgctggcgtttttccataggctccgcccccctgacgagcatcacaaaaa
tcgacgctcaagtcagaggtggcgaaacccgacaggactataaagatacc
aggcgtttccccctggaagctccctcgtgcgctctcctgttccgaccctg
ccgcttaccggatacctgtccgcctttctcccttcgggaagcgtggcgct
ttctcatagctcacgctgtaggtatctcagttcggtgtaggtcgttcgct
ccaagctgggctgtgtgcacgaaccccccgttcagcccgaccgctgcgcc
ttatccggtaactatcgtcttgagtccaacccggtaagacacgacttatc
gccactggcagcagccactggtaacaggattagcagagcgaggtatgtag
gcggtgctacagagttcttgaagtggtggcctaactacggctacactaga
aggacagtatttggtatctgcgctctgctgaagccagttaccttcggaaa
aagagttggtagctcttgatccggcaaacaaaccaccgctggtagcggtg
gtttttttgtttgcaagcagcagattacgcgcagaaaaaaaggatctcaa
gaagatcctttgatcttttctacggggtctgacgctcagtggaacgaaaa
ctcacgttaagggattttggtcatgagattatcaaaaaggatcttcacct
agatccttttaaattaaaaatgaagttttaaatcaatctaaagtatatat
gagtaaacttggtctgacagttaccaatgcttaatcagtgaggcacctat
ctcagcgatctgtctatttcgttcatccatagttgcctgactccccgtcg
tgtagataactacgatacgggagggcttaccatctggccccagtgctgca
atgataccgcgagacccacgctcaccggctccagatttatcagcaataaa
ccagccagccggaagggccgagcgcagaagtggtcctgcaactttatccg
cctccatccagtctattaattgttgccgggaagctagagtaagtagttcg
ccagttaatagtttgcgcaacgttgttgccattgctacaggcatcgtggt
gtcacgctcgtcgtttggtatggcttcattcagctccggttcccaacgat
caaggcgagttacatgatcccccatgttgtgcaaaaaagcggttagctcc
ttcggtcctccgatcgttgtcagaagtaagttggccgcagtgttatcact
catggttatggcagcactgcataattctcttactgtcatgccatccgtaa
gatgcttttctgtgactggtgagtactcaaccaagtcattctgagaatag
tgtatgcggcgaccgagttgctcttgcccggcgtcaatacgggataatac
cgcgccacatagcagaactttaaaagtgctcatcattggaaaacgttctt
cggggcgaaaactctcaaggatcttaccgctgttgagatccagttcgatg
taacccactcgtgcacccaactgatcttcagcatcttttactttcaccag
cgtttctgggtgagcaaaaacaggaaggcaaaatgccgcaaaaaagggaa
taagggcgacacggaaatgttgaatactcatactcttcctttttcaatat
tattgaagcatttatcagggttattgtctcatgagcggatacatatttga
atgtatttagaaaaataaacaaataggggttccgcgcacatttccccgaa
aagtgccacctgacgcgccctgtagcggcgcattaagcgcggcgggtgtg
gtggttacgcgcagcgtgaccgctacacttgccagcgccctagcgcccgc
tcctttcgctttcttcccttcctttctcgccacgttcgccggctttcccc
gtcaagctctaaatcgggggctccctttagggttccgatttagtgcttta
cggcacctcgaccccaaaaaacttgattagggtgatggttcacgtagtgg
gccatcgccctgatagacggtttttcgccctttgacgttggagtccacgt
tctttaatagtggactcttgttccaaactggaacaacactcaaccctatc
tcggtctattcttttgatttataagggattttgccgatttcggcctattg
gttaaaaaatgagctgatttaacaaaaatttaacgcgaattttaacaaaa
tattaacgcttacaattt" > "$transposondir"/vector.fa


echo "Defining transposon features sequences"
echo ">ColE_Ori_T3
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNt
agggatcctctagctagagtcgacctcgagggggggcccggtacccagct
tttgttccctttagtgagggttaatttcgagcttggcgtaatcatggtca
tagctgtttcctgtgtgaaattgttatccgctcacaattccacacaacat
acgagccggaagcataaagtgtaaagcctggggtgcctaatgagtgagct
aactcacattaattgcgttgcgctcactgcccgctttccagtcgggaaac
ctgtcgtgccagctgcattaatgaatcggccaacgcgcggggagaggcgg
tttgcgtattgggcgctcttccgcttcctcgctcactgactcgctgcgct
cggtcgttcggctgcggcgagcggtatcagctcactcaaaggcggtaata
cggttatccacagaatcaggggataacgcaggaaagaacatgtgagcaaa
aggccagcaaaaggccaggaaccgtaaaaaggccgcgttgctggcgtttt
tccataggctccgcccccctgacgagcatcacaaaaatcgacgctcaagt
cagaggtggcgaaacccgacaggactataaagataccaggcgtttccccc
tggaagctccctcgtgcgctctcctgttccgaccctgccgcttaccggat
acctgtccgcctttctcccttcgggaagcgtggcgctttctcatagctca
cgctgtaggtatctcagttcggtgtaggtcgttcgctccaagctgggctg
tgtgcacgaaccccccgttcagcccgaccgctgcgccttatccggtaact
atcgtcttgagtccaacccggtaagacacgacttatcgccactggcagca
gccactggtaacaggattagcagagcgaggtatgtaggcggtgctacaga
gttcttgaagtggtggcctaactacggctacactagaaggacagtatttg
gtatctgcgctctgctgaagccagttaccttcggaaaaagagttggtagc
tcttgatccggcaaacaaaccaccgctggtagcggtggtttttttgtttg
caagcagcagattacgcgcagaaaaaaaggatctcaagaagatcctttga
tcttttctacggggtctgacgctcagtggaacgaaaactcacgttaaggg
attttggtcatgagattatcaaaaaggatcttcacctagatccttttaaa
ttaaaaatgaagttttaaatcaatctaaagtatatatgagtaaacttggt
ctgacagttaccaatgcttaatcagtgaggcacctatctcagcgatctgt
ctatttcgttcatccatagttgcctgactccccgtcgtgtagataactac
gatacgggagggcttaccatctggccccagtgctgcaatgataccgcgag
acccacgctcaccggctccagatttatcagcaataaaccagccagccgga
agggccgagcgcagaagtggtcctgcaactttatccgcctccatccagtc
tattaattgttgccgggaagctagagtaagtagttcgccagttaatagtt
tgcgcaacgttgttgccattgctacaggcatcgtggtgtcacgctcgtcg
tttggtatggcttcattcagctccggttcccaacgatcaaggcgagttac
atgatcccccatgttgtgcaaaaaagcggttagctccttcggtcctccga
tcgttgtcagaagtaagttggccgcagtgttatcactcatggttatggca
gcactgcataattctcttactgtcatgccatccgtaagatgcttttctgt
gactggtgagtaNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNN
>F1_Ori_T7
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNc
tcaaccaagtcattctgagaatagtgtatgcggcgaccgagttgctcttg
cccggcgtcaatacgggataataccgcgccacatagcagaactttaaaag
tgctcatcattggaaaacgttcttcggggcgaaaactctcaaggatctta
ccgctgttgagatccagttcgatgtaacccactcgtgcacccaactgatc
ttcagcatcttttactttcaccagcgtttctgggtgagcaaaaacaggaa
ggcaaaatgccgcaaaaaagggaataagggcgacacggaaatgttgaata
ctcatactcttcctttttcaatattattgaagcatttatcagggttattg
tctcatgagcggatacatatttgaatgtatttagaaaaataaacaaatag
gggttccgcgcacatttccccgaaaagtgccacctgacgcgccctgtagc
ggcgcattaagcgcggcgggtgtggtggttacgcgcagcgtgaccgctac
acttgccagcgccctagcgcccgctcctttcgctttcttcccttcctttc
tcgccacgttcgccggctttccccgtcaagctctaaatcgggggctccct
ttagggttccgatttagtgctttacggcacctcgaccccaaaaaacttga
ttagggtgatggttcacgtagtgggccatcgccctgatagacggtttttc
gccctttgacgttggagtccacgttctttaatagtggactcttgttccaa
actggaacaacactcaaccctatctcggtctattcttttgatttataagg
gattttgccgatttcggcctattggttaaaaaatgagctgatttaacaaa
aatttaacgcgaattttaacaaaatattaacgcttacaatttccattcgc
cattcaggctgcgcaactgttgggaagggcgatcggtgcgggcctcttcg
ctattacgccagctggcgaaagggggatgtgctgcaaggcgattaagttg
ggtaacgccagggttttcccagtcacgacgttgtaaaacgacggccagtg
agcgcgcgtaatacgactcactatagggcgaattggagctcggatcccta
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
>Transposon
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNt
acagttgaagtcggaagtttacatacacttaagttggagtcattaaaact
cgtttttcaactactccacaaatttcttgttaacaaacaatagttttggc
aagtcagttaggacatctactttgtgcatgacacaagtcatttttccaac
aattgtttacagacagattatttcacttataattcactgtatcacaattc
cagtgggtcagaagtttacatacactaagttgactgtgcctttaaacagc
ttggaaaattccagaaaatgatgtcatggctttagaagcttgatggccgc
tctagaactaggattgcagcacgaaacaggaagctgactccacatggtca
catgctcactgaagtgttgacttccctgacagctgtgcactttctaaacc
ggttttctcattcatttacagttcagccgatgatgaaattgccgcactgg
ttgttagcaacgtagccggtatgtgaaagatggattcgcgggaatttagt
ggatcccccgggctgcaggaattcgatctgaagcctatagagtacgagcc
atagataaaataaaagattttatttagtctccagaaaaaggggggaatga
aagaccccacctgtaggtttggcaagctagcttaagtaacgccattttgc
aaggcatggaaaatacataactgagaatagagaagttcagatcaaggtta
ggaacagagagacagcagaatatgggccaaacaggatatctgtggtaagc
agttcctgccccggctcagggccaagaacagatggtccccagatgcggtc
ccgccctcagcagtttctagagaaccatcagatgtttccagggtgcccca
aggacctgaaaatgaccctgtgccttatttgaactaaccaatcagttcgc
ttctcgcttctgttcgcgcgcttctgctccccgagctcaataaaagagcc
cacaacccctcactcggcgcgccagtcctccgatagactgcgtcgcccat
caagcttgctactagcaccagaacgcccgcgaggatctctcaggtaataa
agagcgccaaggctggctgcaagcggagcctctgagagcctctgagggcc
agggctactgcacccttggtcctcaacgctggggtcttcagaactagaat
gctgggggtggggtggggattcggttccctattccatcgcgcgttaagat
acattgatgagtttggacaaaccacaactagaatgcagtgaaaaaaatgc
tttatttgtgaaatttgtgatgctattgctttatttgtaaccattataag
ctgcaataaacaagttggccgctcctgtgccagactctggcgccgctgct
ctgtcaggtacctgttggtctgaaactcagccttgagcctctggagctgc
tcagcagtgaaggctgtgcgaggccgcttgtcctctttgttagggttctt
cttctttggttttcgggacctgggacctggttgtcatggaggagaaaggg
cagaggttactggttgctggagtctagctacttatccacaacccacgcac
ccaagcttgaggttgcagatactgggggtggggggggggggatgacccgc
ccaaggccatacaagtgttgggcattgggggtggtgatataaacttgagg
ctgggcatgtgcccactgaccagaaggaaagtggtgtgtgtgtgtgaaaa
tgagatggattggcagatgtagctaaaaggcctatcacaaactaggggat
ctagcttgtggaaggctactcgaaatgtttgacccaagttaaacaattta
aaggcaatgctaccaaatactaattgagtgtatgtaaacttctgacccac
tgggaatgtgatgaaagaaataaaagctgaaatgaatcattctctctact
attattctgatatttcacattcttaaaataaagtggtgatcctaactgac
ctaagacagggaatttttactaggattaaatgtcaggaattgtgaaaaag
tgagtttaaatgtatttggctaaggtgtatgtaaacttccgacttcaact
gtaNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NN" > "$transposondir"/features.fa



echo "chr1	103837375	103837376
chr1	103953080	103953081
chr1	104811697	104811698
chr1	110920665	110920666
chr1	112137744	112137745
chr1	116625250	116625251
chr1	117675286	117675287
chr1	118478624	118478625
chr1	120303523	120303524
chr1	122552913	122552914
chr1	124111790	124111791
chr1	127992908	127992909
chr1	128361413	128361414
chr1	131317593	131317594
chr1	13924680	13924681
chr1	143041666	143041667
chr1	143133716	143133717
chr1	146613967	146613968
chr1	146992528	146992529
chr1	15101950	15101951
chr1	168600756	168600757
chr1	181662580	181662581
chr1	18369907	18369908
chr1	18736562	18736563
chr1	196840374	196840375
chr1	21349158	21349159
chr1	21743669	21743670
chr1	23335814	23335815
chr1	27524257	27524258
chr1	28919418	28919419
chr1	30997947	30997948
chr1	31891760	31891761
chr1	37700074	37700075
chr1	41308276	41308277
chr1	43532550	43532551
chr1	44722351	44722352
chr1	4500924	4500925
chr1	48652973	48652974
chr1	51249011	51249012
chr1	53566623	53566624
chr1	63130042	63130043
chr1	63470758	63470759
chr1	63556682	63556683
chr1	66245286	66245287
chr1	7531549	7531550
chr1	79288156	79288157
chr1	82880942	82880943
chr1	84649102	84649103
chr1	9849188	9849189
chr1	99831354	99831355
chr10	100097975	100097976
chr10	101390700	101390701
chr10	105558605	105558606
chr10	13778669	13778670
chr10	31224310	31224311
chr10	34108906	34108907
chr10	35918723	35918724
chr10	44630926	44630927
chr10	5272747	5272748
chr10	54319502	54319503
chr10	61445943	61445944
chr10	66388407	66388408
chr10	69580497	69580498
chr10	84382273	84382274
chr10	93104331	93104332
chr11	109499709	109499710
chr11	11749647	11749648
chr11	28487283	28487284
chr11	30087946	30087947
chr11	3087991	3087992
chr11	45867793	45867794
chr11	50596311	50596312
chr11	58975430	58975431
chr11	61783858	61783859
chr11	7229180	7229181
chr11	72372851	72372852
chr11	76445470	76445471
chr11	76627834	76627835
chr11	82407782	82407783
chr11	92150382	92150383
chr11	93970754	93970755
chr12	11111198	11111199
chr12	28478068	28478069
chr12	35352043	35352044
chr12	50246467	50246468
chr12	63470666	63470667
chr12	7620048	7620049
chr12	79112365	79112366
chr12	88210117	88210118
chr12	99693097	99693098
chr13	106198511	106198512
chr13	115857652	115857653
chr13	25372305	25372306
chr13	39613839	39613840
chr13	40475080	40475081
chr13	52977017	52977018
chr13	6998729	6998730
chr13	97373917	97373918
chr14	100451800	100451801
chr14	108545246	108545247
chr14	119360084	119360085
chr14	120949250	120949251
chr14	14342539	14342540
chr14	24466497	24466498
chr14	24840186	24840187
chr14	34228902	34228903
chr14	37147280	37147281
chr14	40570001	40570002
chr14	48667457	48667458
chr14	69854789	69854790
chr14	97651211	97651212
chr14	98689606	98689607
chr15	16807334	16807335
chr15	21913217	21913218
chr15	63574080	63574081
chr15	72319118	72319119
chr15	74566790	74566791
chr15	88031748	88031749
chr16	15934210	15934211
chr16	20904637	20904638
chr16	24443398	24443399
chr16	33897336	33897337
chr16	55220450	55220451
chr16	62676303	62676304
chr16	64183012	64183013
chr16	64562587	64562588
chr16	69444082	69444083
chr16	72353225	72353226
chr16	73281313	73281314
chr16	75813718	75813719
chr16	88273809	88273810
chr16	89552803	89552804
chr16	94781777	94781778
chr16	97772791	97772792
chr17	15646628	15646629
chr17	33661546	33661547
chr17	73738305	73738306
chr18	10365663	10365664
chr18	20563156	20563157
chr18	23202940	23202941
chr18	32717498	32717499
chr18	40139224	40139225
chr18	5059365	5059366
chr18	71618252	71618253
chr19	16245224	16245225
chr19	21678948	21678949
chr19	32218411	32218412
chr19	37394081	37394082
chr2	118186403	118186404
chr2	119167905	119167906
chr2	122872961	122872962
chr2	131956287	131956288
chr2	139841105	139841106
chr2	144271234	144271235
chr2	157195399	157195400
chr2	163034737	163034738
chr2	163821826	163821827
chr2	179709387	179709388
chr2	20975485	20975486
chr2	25321943	25321944
chr2	26336362	26336363
chr2	44648314	44648315
chr2	68857666	68857667
chr2	81156576	81156577
chr2	98502963	98502964
chr2	98505066	98505067
chr2	98505322	98505323
chr2	98506463	98506464
chr2	98506519	98506520
chr2	98506584	98506585
chr3	117876876	117876877
chr3	119980378	119980379
chr3	129360369	129360370
chr3	133156377	133156378
chr3	151013291	151013292
chr3	18038182	18038183
chr3	27794371	27794372
chr3	61816886	61816887
chr3	65745957	65745958
chr3	75143905	75143906
chr4	102524071	102524072
chr4	10436239	10436240
chr4	105982601	105982602
chr4	109283762	109283763
chr4	109532575	109532576
chr4	130130857	130130858
chr4	140292880	140292881
chr4	142901300	142901301
chr4	152409723	152409724
chr4	15810475	15810476
chr4	23704560	23704561
chr4	26756577	26756578
chr4	28529979	28529980
chr4	29617870	29617871
chr4	37510688	37510689
chr4	50011481	50011482
chr4	65613854	65613855
chr4	66671039	66671040
chr4	74197114	74197115
chr4	77420615	77420616
chr4	83679890	83679891
chr5	107967726	107967727
chr5	117760528	117760529
chr5	13074123	13074124
chr5	143111738	143111739
chr5	22993477	22993478
chr5	26698714	26698715
chr5	32756232	32756233
chr5	34028498	34028499
chr5	39808265	39808266
chr5	39832534	39832535
chr5	4875108	4875109
chr5	76641045	76641046
chr5	79225607	79225608
chr5	79944692	79944693
chr5	84836166	84836167
chr5	97973066	97973067
chr6	10140729	10140730
chr6	10140733	10140734
chr6	103599083	103599084
chr6	103599140	103599141
chr6	119341595	119341596
chr6	134128240	134128241
chr6	137896346	137896347
chr6	141153898	141153899
chr6	147242322	147242323
chr6	20054815	20054816
chr6	31046744	31046745
chr6	71206097	71206098
chr6	76538893	76538894
chr6	8896545	8896546
chr6	92594109	92594110
chr6	98987112	98987113
chr7	129143514	129143515
chr7	143484627	143484628
chr7	143698787	143698788
chr7	17322188	17322189
chr7	18635340	18635341
chr7	28381898	28381899
chr7	35949749	35949750
chr7	38418113	38418114
chr7	59807257	59807258
chr7	65942460	65942461
chr7	68586542	68586543
chr7	70232282	70232283
chr7	73581078	73581079
chr7	99883946	99883947
chr8	111435554	111435555
chr8	126449362	126449363
chr8	32514785	32514786
chr8	37323646	37323647
chr8	44293265	44293266
chr8	44753623	44753624
chr8	45108860	45108861
chr8	51100787	51100788
chr8	82338215	82338216
chr8	88490753	88490754
chr8	9073259	9073260
chr9	102802834	102802835
chr9	113597152	113597153
chr9	11659913	11659914
chr9	117108601	117108602
chr9	13328356	13328357
chr9	14634695	14634696
chr9	22870132	22870133
chr9	29138701	29138702
chr9	3025482	3025483
chr9	3030164	3030165
chr9	31313554	31313555
chr9	42813441	42813442
chr9	44992724	44992725
chr9	5541584	5541585
chr9	60646705	60646706
chr9	61234077	61234078
chr9	61883322	61883323
chr9	6604262	6604263
chr9	70536697	70536698
chr9	74898106	74898107
chr9	81842107	81842108
chr9	83630656	83630657
chr9	85890671	85890672
chr9	97068172	97068173
chrX	106817039	106817040
chrX	136878418	136878419
chrX	139917602	139917603
chrX	139917634	139917635
chrX	154541165	154541166
chrX	19813645	19813646
chrX	37189042	37189043
chrX	61011393	61011394
chrX	72889462	72889463" > "$srvdir"/protonMaskSites.bed


echo "Installing python scripts"

cp python/indexTAtracks.py "$execdir"
chmod 744 "$execdir"/indexTAtracks.py

cp python/sam2fastq.py "$execdir"
chmod 744 "$execdir"/sam2fastq.py

cp python/fastq2tas.py "$execdir"
chmod 744 "$execdir"/fastq2tas.py

cp python/tas2bed.py "$execdir"
chmod 744 "$execdir"/tas2bed.py

cp python/maskbed.py "$execdir"
chmod 744 "$execdir"/maskbed.py

########################################################

if [ ! -f "$indexdir"/onc2.fa ];
then
  echo "Unzipping mm9 reference"
  tar -xf "$indexdir"/chromFa.tar.gz -C "$indexdir"
  rm "$indexdir"/chr*_random.fa

  echo "Making onc2.fa reference"
  cat "$indexdir"/chr*.fa > "$indexdir"/onc2.fa
  cat "$transposondir"/vector.fa >> "$indexdir"/onc2.fa

  rm "$indexdir"/chr*.fa
fi

########################################################

if [ ! -f "$indexdir"/onc2.ta.gz.tbi ];
then
  echo "Generating TA track on onc2.fa (takes 10 minutes)"
  indexTAtracks.py "$indexdir"/onc2.fa > "$indexdir"/onc2.ta

  echo "Block-compressing TA track"
  bgzip "$indexdir"/onc2.ta

  echo "Indexing TA track"
  tabix -p bed "$indexdir"/onc2.ta.gz 
fi

########################################################

if [ ! -f "$transposondir"/vector.1.bt2 ];
then
  echo "Generating Bowtie2 indexes on vector.fa"
  bowtie2-build "$transposondir"/vector.fa "$transposondir"/vector
fi

if [ ! -f "$transposondir"/features.1.bt2 ];
then
  echo "Generating Bowtie2 indexes on features.fa"
  bowtie2-build "$transposondir"/features.fa "$transposondir"/features
fi

if [ ! -f "$indexdir"/onc2.1.bt2 ];
then
  echo "Generating Bowtie2 indexes on onc2.fa (takes 2 hours)"
  bowtie2-build "$indexdir"/onc2.fa "$indexdir"/onc2
fi

