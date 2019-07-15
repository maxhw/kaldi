#!/bin/bash

run_dir=$1
dataset_dir=$2

export PATH=$PATH:`pwd`/../../../tools/irstlm/bin

cd $run_dir
echo "Preparing train and test data"
mkdir -p data/{train,test}

#create text, wav.scp, utt2spk, spk2utt
(
i=0
for dir in train test; do
    echo "clean dir data/$dir"
    cd $run_dir/data/$dir
    rm -rf wav.scp utt2spk spk2utt word.txt text
    waves=`find ${dataset_dir}/*/*/*/*.wav | sed "s?${dataset_dir}/??g"`
    for data in ${waves};do
        let i=$i+1
        date_dir=$(echo $data | awk  -F '/' '{print $1}')
        spkid=$(echo $data | awk  -F '/' '{print $2}')
        uttid=$(echo $data | sed 's?/?_?g' | awk  -F '.' '{print $1}')
        idx=$(echo $data | awk  -F '/' '{print $4}'| awk  -F '.' '{print $1}')
        # gen scp
        echo $uttid ${dataset_dir}/$data >> wav.scp
        # gen utt2spk
        echo $uttid $spkid >> utt2spk
        # gen word.txt
        echo $uttid $(cat ${dataset_dir}/${date_dir}/utt2word.txt | grep ${idx} | awk '{print "" $2}') >> word.txt
        # gen phone.txt TODO
    done
    cp word.txt text
    sort wav.scp -o wav.scp
    sort utt2spk -o utt2spk
    sort text -o text
done
echo "all file number is $i"
) || exit 1

utils/utt2spk_to_spk2utt.pl data/train/utt2spk > data/train/spk2utt
utils/utt2spk_to_spk2utt.pl data/test/utt2spk > data/test/spk2utt
