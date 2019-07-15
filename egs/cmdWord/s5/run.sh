#!/bin/bash

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.
. ./path.sh

n=3 #parallel jobs

run_path=`pwd`
#dataset path
dataset=${run_path}/waves_isp

rm -rf data exp mfcc

# Data preparation
local/prepare_data.sh ${run_path} ${dataset} || exit 1
local/prepare_dict.sh ${dataset}
#utils/prepare_lang.sh --position-dependent-phones false data/dict "<SIL>" data/local/lang data/lang
utils/prepare_lang.sh --position_dependent_phones false data/dict "<SPOKEN_NOISE>" data/local/lang data/lang
local/prepare_lm.sh  ${dataset}

# Feature extraction
for x in train test; do
  #make  mfcc
  steps/make_mfcc.sh --nj $n --cmd "$train_cmd" data/$x exp/make_mfcc/$x mfcc
  #compute cmvn
  steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x mfcc
  utils/fix_data_dir.sh data/$x
done

# Mono training
#steps/train_mono.sh --nj $n --cmd "$train_cmd" --totgauss 400 data/train data/lang exp/mono0a
steps/train_mono.sh --nj $n --cmd "$train_cmd" --boost-silence 3.25 data/train data/lang exp/mono0a

#monophone_ali
steps/align_si.sh --nj $n --cmd "$train_cmd" --boost-silence 3.25 data/train data/lang exp/mono0a exp/mono_ali || exit 1;

#triphone
steps/train_deltas.sh --cmd "$train_cmd" --boost-silence 3.25 2000 10000 data/train data/lang exp/mono0a exp/tri1 || exit 1;

# decode word
# Graph compilation
utils/mkgraph.sh data/graph/lang exp/tri1 exp/tri1/graph_tgpr

# Decoding
steps/decode.sh --nj $n --cmd "$decode_cmd" exp/tri1/graph_tgpr data/test exp/tri1/decode_test

#for x in exp/*/decode*; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done
