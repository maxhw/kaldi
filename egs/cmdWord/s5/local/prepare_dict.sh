#!/bin/bash

dataset_dir=$1

mkdir -p data/dict

cp input/extra_questions.txt data/dict/extra_questions.txt

cp input/nonsilence_phones.txt data/dict/nonsilence_phones.txt

echo "sil" > data/dict/optional_silence.txt

echo "sil" > data/dict/silence_phones.txt

cat ${dataset_dir}/lexicon.txt | grep -v '<s>' | grep -v '</s>' | sort -u > data/dict/lexicon.txt

echo "Dictionary preparation succeeded"
