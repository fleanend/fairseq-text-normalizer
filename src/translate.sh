#!/usr/bin/env bash
#
# Adapted from https://github.com/facebookresearch/MIXER/blob/master/prepareData.sh

pip install sentencepiece

echo 'Cloning Moses github repository (for tokenization scripts)...'
git clone https://github.com/moses-smt/mosesdecoder.git

SCRIPTS=fairseq/scripts
SPM_TRAIN=$SCRIPTS/spm_train.py
SPM_ENCODE=$SCRIPTS/spm_encode.py
MOS=mosesdecoder/scripts
LC=$MOS/tokenizer/lowercase.perl
CLEAN=$MOS/training/clean-corpus-n.perl

if [ ! -d "$SCRIPTS" ]; then
    echo "Please set SCRIPTS variable correctly to point to sentencepiece scripts."
    exit
fi

file_to_translate=$1
src_lang=$2
tgt_lang=$3
model=$4
sentence_piece_model=$5
src_dict=$6
tgt_dict=$7
output=$8

f=$file_to_translate
tok=$file_to_translate.tok
echo $f
echo $tok
cat $file_to_translate \
| grep -v '<url>' \
| grep -v '<talkid>' \
| grep -v '<keywords>' \
| grep -v '<speaker>' \
| grep -v '<reviewer' \
| grep -v '<translator' \
| grep -v '<doc' \
| grep -v '</doc>' \
| sed -e 's/<title>//g' \
| sed -e 's/<\/title>//g' \
| sed -e 's/<description>//g' \
| sed -e 's/<\/description>//g' \
| sed 's/^\s*//g' \
| sed 's/\s*$//g' > $tok
echo ""

clean=$file_to_translate.clean

perl $LC < $tok > $clean
rm -f $tok

sub=$file_to_translate.sub

python "$SPM_ENCODE" \
    --model $sentence_piece_model \
    --output_format=piece \
    --inputs $clean \
    --outputs $sub.$src_lang

rm -f $clean

cat $sub.$src_lang > $sub.$tgt_lang

fairseq-preprocess --source-lang $src_lang --target-lang $tgt_lang\
    --testpref $sub \
    --destdir . \
    --srcdict $src_dict --tgtdict $tgt_dict

rm -f $sub.$src_lang
rm -f $sub.$tgt_lang

fairseq-generate . --source-lang $src_lang --target-lang $tgt_lang \
    --path $model \
    --batch-size 128 --beam 5 --results-path output

grep ^H output/generate-test.txt | LC_ALL=C sort -V | cut -f3- > hyp.txt
cat hyp.txt | sed 's/ //g' | sed 's/▁/ /g' > $output