#!/usr/bin/env bash
#

start_folder=$1
langs=$2

for l in $langs; do
	test=$(echo $l | tr "-" " ")
    set -- $test
   
    CUDA_VISIBLE_DEVICES=0 fairseq-train data-bin/all.tokenized.$l \
--arch transformer --share-all-embeddings --encoder-layers 4 --decoder-layers 4 --encoder-ffn-embed-dim 1024 \
--decoder-ffn-embed-dim 1024 --encoder-embed-dim 256 \
    --decoder-embed-dim 256 --encoder-attention-heads 4 \
    --decoder-attention-heads 4 --encoder-normalize-before \
    --decoder-normalize-before  --dropout 0.3 \
    --save-dir checkpoints/fconv \
    --batch-size 20 --optimizer adam --lr-scheduler inverse_sqrt \
    --warmup-init-lr 1e-7 --warmup-updates 4000 --lr 1e-3 \
    --max-epoch 250 --clip-norm 0.1 \
  --criterion label_smoothed_cross_entropy --label-smoothing 0.1 \
  --adam-betas '(0.9, 0.98)' --keep-last-epochs 30 
  
    mv checkpoints/fconv/checkpoint_best.pt $start_folder/models/back_$l.pt
    rm -r -f checkpoints
done