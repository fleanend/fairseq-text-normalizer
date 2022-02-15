#!/usr/bin/env bash
#
# pulire e mettere dentro a install

token_multiplier=$1
upsample_primary=$2
source_lang=$3
target_lang=$4
lang_name=$target_lang-$source_lang


./src/create_dataset.sh . $lang_name $token_multiplier
./src/train_back_translators.sh . $lang_name
./src/back_translate.sh . $lang_name
./src/create_secondary_dataset.sh . $lang_name $token_multiplier

rm -r -f checkpoints/fconv
mkdir checkpoints checkpoints/fconv
CUDA_VISIBLE_DEVICES=0 fairseq-train data-bin/all.tokenized.$lang_name --source-lang $source_lang --target-lang $target_lang \
--arch transformer --share-all-embeddings --encoder-layers 4 --decoder-layers 4 --encoder-ffn-embed-dim 1024 \
--decoder-ffn-embed-dim 1024 --encoder-embed-dim 256 \
    --decoder-embed-dim 256 --encoder-attention-heads 4 \
    --decoder-attention-heads 4 --encoder-normalize-before \
    --decoder-normalize-before  --dropout 0.3 \
    --save-dir checkpoints/fconv \
    --batch-size 20 --optimizer adam --lr-scheduler inverse_sqrt \
    --warmup-init-lr 1e-7 --warmup-updates 4000 --lr 1e-3 \
    --patience 20 --clip-norm 0.1 \
  --criterion label_smoothed_cross_entropy --label-smoothing 0.1 \
  --adam-betas '(0.9, 0.98)' --keep-last-epochs 30 \
  --upsample-primary $upsample_primary
  
fairseq-generate data-bin/all.tokenized.$lang_name --source-lang $source_lang --target-lang $target_lang \
    --path checkpoints/fconv/checkpoint_best.pt \
    --batch-size 128 --beam 5 --results-path output \
    --remove-bpe
    
python src/utils/score.py


mkdir $source_lang-$target_lang-normalizer
cp checkpoints/fconv/checkpoint_best.pt $source_lang-$target_lang-normalizer/normalizer_model.pt
cp sentencepiece_$lang_name.bpe.model $source_lang-$target_lang-normalizer/sentencepiece_old-new.bpe.model
cp sentencepiece_$lang_name.bpe.vocab $source_lang-$target_lang-normalizer/sentencepiece_old-new.bpe.vocab
cp data-bin/all.tokenized.$lang_name/dict.$source_lang.txt $source_lang-$target_lang-normalizer/dict.old.txt
cp data-bin/all.tokenized.$lang_name/dict.$target_lang.txt $source_lang-$target_lang-normalizer/dict.new.txt
cp "{}-{}-normalizer/"* $source_lang-$target_lang-normalizer/