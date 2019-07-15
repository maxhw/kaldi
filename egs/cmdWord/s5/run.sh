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
#test monophone model
local/decode.sh --mono true --nj $n "steps/decode.sh" exp/mono0a data


#monophone_ali
steps/align_si.sh --nj $n --cmd "$train_cmd" --boost-silence 3.25 data/train data/lang exp/mono0a exp/mono0a_ali || exit 1;

#triphone
steps/train_deltas.sh --cmd "$train_cmd" --boost-silence 3.25 2000 10000 data/train data/lang exp/mono0a_ali exp/tri1 || exit 1;
#test tri1 model
local/decode.sh --nj $n "steps/decode.sh" exp/tri1 data


#triphone_ali
steps/align_si.sh --nj $n --cmd "$train_cmd" data/train data/lang exp/tri1 exp/tri1_ali || exit 1;

#lda_mllt
steps/train_lda_mllt.sh --cmd "$train_cmd"  --splice-opts "--left-context=3 --right-context=3" 2500 15000 data/train data/lang exp/tri1_ali exp/tri2b || exit 1;
#test tri2b model
local/decode.sh --nj $n "steps/decode.sh" exp/tri2b data


#lda_mllt_ali
steps/align_si.sh  --nj $n --cmd "$train_cmd" --use-graphs true data/train data/lang exp/tri2b exp/tri2b_ali || exit 1;

#sat
steps/train_sat.sh --cmd "$train_cmd" 2500 15000 data/train data/lang exp/tri2b_ali exp/tri3b || exit 1;
#test tri3b model
local/decode.sh --nj $n "steps/decode_fmllr.sh" exp/tri3b data


#sat_ali
steps/align_fmllr.sh --nj $n --cmd "$train_cmd" data/train data/lang exp/tri3b exp/tri3b_ali || exit 1;

#quick
steps/train_quick.sh --cmd "$train_cmd" 4200 40000 data/train data/lang exp/tri3b_ali exp/tri4b || exit 1;
#test tri4b model
local/decode.sh --nj $n "steps/decode_fmllr.sh" exp/tri4b data


#quick_ali
steps/align_fmllr.sh --nj $n --cmd "$train_cmd" data/train data/lang exp/tri4b exp/tri4b_ali || exit 1;

#quick_ali_cv
#steps/align_fmllr.sh --nj $n --cmd "$train_cmd" data/dev data/lang exp/tri4b exp/tri4b_ali_cv || exit 1;

#train dnn model
#local/nnet/run_dnn.sh --stage 0 --nj $n  exp/tri4b exp/tri4b_ali exp/tri4b_ali_cv || exit 1;

for x in exp/*/decode*; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done
