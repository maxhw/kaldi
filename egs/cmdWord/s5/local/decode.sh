#!/bin/bash
#Copyright 2016  Tsinghua University (Author: Dong Wang, Xuewei Zhang).  Apache 2.0.

#decoding wrapper for thchs30 recipe
#run from ../

nj=8
mono=false

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. ./path.sh ## Source the tools/utils (import the queue.pl)

. utils/parse_options.sh || exit 1;
decoder=$1
srcdir=$2
datadir=$3


if [ $mono = true ];then
  echo  "using monophone to generate graph"
  opt="--mono"
fi

# decode word
# Graph compilation
utils/mkgraph.sh $opt data/graph/lang $srcdir $srcdir/graph_tgpr || exit 1;

# Decoding
#steps/decode.sh --nj $n --cmd "$decode_cmd" exp/tri1/graph_tgpr data/test exp/tri1/decode_test 
$decoder --cmd "$decode_cmd" --nj $nj $srcdir/graph_tgpr $datadir/test $srcdir/decode_test || exit 1

# decode phone
#utils/mkgraph.sh $opt data/graph_phone/lang $srcdir $srcdir/graph_phone  || exit 1;
#$decoder --cmd "$decode_cmd" --nj $nj $srcdir/graph_phone $datadir/test_phone $srcdir/decode_test_phone || exit 1


