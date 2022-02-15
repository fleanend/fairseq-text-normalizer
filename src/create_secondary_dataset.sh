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

orig=orig

start_folder=$1
raw_langs=$2
main_lang=old-new
langs="$main_lang $2"
token_multiplier=$3

echo '' > $orig/$main_lang/train.tags.$main_lang.old
echo '' > $orig/$main_lang/train.tags.$main_lang.new

for l in $raw_langs; do
	test=$(echo $l | tr "-" " ")

	for i in $test; do
	  cat $start_folder/data/processed/back_$l.$i > $orig/$l/train.tags.$l.$i
	  if [ $i = new ]
	  then
          cat $start_folder/data/processed/back_$l.$i >> $orig/$main_lang/train.tags.$main_lang.new
	  else
          cat $start_folder/data/processed/back_$l.$i >> $orig/$main_lang/train.tags.$main_lang.old
	  fi
	done
done

echo "pre-processing data..."
for l in $langs; do
	test=$(echo $l | tr "-" " ")
	echo $test
	for i in $test; do
		f=train.tags.$l.$i
		tok=train.tags.$l.tok.$i
		echo $f
		echo $tok
		cat $orig/$l/$f \
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
        | sed 's/\s*$//g' > all.tokenized.$l/tmp/$tok
		echo ""
	done
done


for l in $langs; do
	test=$(echo $l | tr "-" " ")
	
	for i in $test; do
		#perl $LC < all.tokenized.$l/tmp/train.tags.$l.tok.$i > all.tokenized.$l/tmp/train.tags.$l.clean.$i
		cat all.tokenized.$l/tmp/train.tags.$l.tok.$i > all.tokenized.$l/tmp/train.tags.$l.clean.$i
	done
done


echo "train1..."

for l in $langs; do
	test=$(echo $l | tr "-" " ")
    echo $l
	for i in $test; do
        cat all.tokenized.$l/tmp/train.tags.$l.clean.$i > all.tokenized.$l/tmp/train1.$i
	done
done



TRAIN=all.tokenized.$main_lang/tmp/train.$main_lang

len_vocab=$( cat $TRAIN | grep -o . | sort | uniq -c | sort -bnr | wc -l )
echo "len vocab on ${len_vocab}..."

BPE_TOKENS=$(awk '{print $1*$2-1+4}' <<<"${len_vocab} ${token_multiplier}")
echo "BPE_TOKENS on ${BPE_TOKENS}..."

echo "encoding train/valid/test with learned BPE..."
for l in $langs; do
	test=$(echo $l | tr "-" " ")
	for i in $test; do
		f=train1.$i
		python "$SPM_ENCODE" \
        --model "$start_folder/sentencepiece_$l.bpe.model" \
        --output_format=piece \
        --inputs all.tokenized.$l/tmp/$f \
        --outputs all.tokenized.$l/$f
	done
done

echo "final preprocessing..."
for l in $langs; do
	test=$(echo $l | tr "-" " ")
    set -- $test
    for i in $test; do
        fairseq-preprocess --source-lang $1 --target-lang $2 \
        --trainpref all.tokenized.$l/train1 \
        --destdir data-bin/tmp/all.tokenized.$l \
        --srcdict data-bin/all.tokenized.$l/dict.$1.txt \
        --tgtdict data-bin/all.tokenized.$l/dict.$2.txt
    done
done

for ext in bin idx; do
    for l in $langs; do
	test=$(echo $l | tr "-" " ")
    	for i in $test; do
            f=train.$l.$i.$ext
            of=train1.$l.$i.$ext
        	cat data-bin/tmp/all.tokenized.$l/$f > data-bin/all.tokenized.$l/$of
        done
    done
done