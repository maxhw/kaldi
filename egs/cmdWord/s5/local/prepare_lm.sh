#!/bin/bash

. ./path.sh

dataset_dir=$1

export PATH=$PATH:`pwd`/../../../tools/srilm/bin/i686-m64

echo Preparing language models for test

mkdir data/graph

ngram-count -order 2 -text ${dataset_dir}/words.txt -lm data/graph/word.arpa

gzip -c data/graph/word.arpa > data/graph/word.arpa.gz || exit 1;
utils/format_lm.sh data/lang data/graph/word.arpa.gz ${dataset_dir}/lexicon.txt data/graph/lang || exit 1;

echo "Succeeded in formatting data."
