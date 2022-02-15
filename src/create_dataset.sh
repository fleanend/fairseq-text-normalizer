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

for mono in $start_folder/data/raw/mono*.new; do
    python $start_folder/src/utils/split_mono.py $mono
    cat $mono >> $start_folder/data/raw/final_mono.new
done
    
cat $start_folder/data/raw/final_mono.new > $start_folder/data/raw/mono.new 

mkdir -p $orig

for l in $langs; do
	mkdir -p all.tokenized.$l all.tokenized.$l/tmp
done

cd $orig

mkdir -p ./$main_lang
echo '' > ./$main_lang/train.tags.$main_lang.old
echo '' > ./$main_lang/train.tags.$main_lang.new

for l in $raw_langs; do
	mkdir -p $l
	test=$(echo $l | tr "-" " ")

	for i in $test; do
	  cat ../$start_folder/data/raw/$l.$i > ./$l/train.tags.$l.$i
	  if [ $i = new ]
	  then
          cat ../$start_folder/data/raw/$l.$i >> ./$main_lang/train.tags.$main_lang.new
	  else
          cat ../$start_folder/data/raw/$l.$i >> ./$main_lang/train.tags.$main_lang.old
	  fi
	done
done

cd ..

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

echo "pre-processing mono"

cat $start_folder/data/raw/mono.new \
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
        | sed 's/\s*$//g' > all.tokenized.$main_lang/tmp/train.tags.$main_lang.tok.mono.new
echo ""

cat all.tokenized.$main_lang/tmp/train.tags.$main_lang.tok.mono.new > all.tokenized.$main_lang/tmp/train.tags.$main_lang.tok.mono.old


for l in $langs; do
	test=$(echo $l | tr "-" " ")
	
	for i in $test; do
		#perl $LC < all.tokenized.$l/tmp/train.tags.$l.tok.$i > all.tokenized.$l/tmp/train.tags.$l.clean.$i
		cat all.tokenized.$l/tmp/train.tags.$l.tok.$i > all.tokenized.$l/tmp/train.tags.$l.clean.$i
	done
done

for l in old new; do
    #perl $LC < all.tokenized.$main_lang/tmp/train.tags.$main_lang.tok.mono.$l > all.tokenized.$main_lang/tmp/train.tags.$main_lang.mono.clean.$l
    cat all.tokenized.$main_lang/tmp/train.tags.$main_lang.tok.mono.$l > all.tokenized.$main_lang/tmp/train.tags.$main_lang.mono.clean.$l
done


echo "creating train, valid, test..."
echo $main_lang
for l in old new; do
    awk '{if (NR%10 == 0)  print $0; }' all.tokenized.$main_lang/tmp/train.tags.$main_lang.clean.$l > all.tokenized.$main_lang/tmp/test.$l
    awk '{if (NR%10 == 1)  print $0; }' all.tokenized.$main_lang/tmp/train.tags.$main_lang.clean.$l > all.tokenized.$main_lang/tmp/valid.$l
    awk '{if (NR%10 == 2)  print $0; }' all.tokenized.$main_lang/tmp/train.tags.$main_lang.clean.$l > all.tokenized.$main_lang/tmp/valid.$l
    awk '{if (NR%10 > 2)  print $0; }' all.tokenized.$main_lang/tmp/train.tags.$main_lang.clean.$l > all.tokenized.$main_lang/tmp/train.$l
done

for l in $raw_langs; do
	test=$(echo $l | tr "-" " ")
    echo $l
	for i in $test; do
		awk '{if (NR%10 == 0)  print $0; }' all.tokenized.$l/tmp/train.tags.$l.clean.$i > all.tokenized.$l/tmp/valid.$i
		awk '{if (NR%10 == 1)  print $0; }' all.tokenized.$l/tmp/train.tags.$l.clean.$i > all.tokenized.$l/tmp/valid.$i
		awk '{if (NR%10 == 2)  print $0; }' all.tokenized.$l/tmp/train.tags.$l.clean.$i > all.tokenized.$l/tmp/test.$i
		awk '{if (NR%10 > 2)  print $0; }' all.tokenized.$l/tmp/train.tags.$l.clean.$i > all.tokenized.$l/tmp/train.$i
	done
done


echo "encoding train/valid/test with learned BPE..."
for l in $langs; do
	test=$(echo $l | tr "-" " ")
	TRAIN=all.tokenized.$l/tmp/train.$l
    rm -f $TRAIN
    for i in $test; do
        cat all.tokenized.$l/tmp/train.$i >> $TRAIN
    done
    len_vocab=$( cat $TRAIN | grep -o . | sort | uniq -c | sort -bnr | wc -l )
    echo "len vocab on ${len_vocab}..."
    
    BPE_TOKENS=$(awk '{print $1*$2-1+4}' <<<"${len_vocab} ${token_multiplier}")
    echo "BPE_TOKENS on ${BPE_TOKENS}..."
    
    echo "learning joint BPE over $TRAIN..."

    python "$SPM_TRAIN" \
        --input=$TRAIN \
        --model_prefix=$start_folder/sentencepiece_$l.bpe \
        --vocab_size=$BPE_TOKENS \
        --character_coverage=1.0 \
        --model_type=bpe
	for i in $test; do
		for f in train.$i valid.$i test.$i; do
			python "$SPM_ENCODE" \
            --model "$start_folder/sentencepiece_$l.bpe.model" \
            --output_format=piece \
            --inputs all.tokenized.$l/tmp/$f \
            --outputs all.tokenized.$l/$f
		done
	done
done
    
echo "final preprocessing..."
for l in $langs; do
    rm -r -f data-bin/all.tokenized.$l
	test=$(echo $l | tr "-" " ")
    set -- $test
    fairseq-preprocess --source-lang $1 --target-lang $2 \
    --trainpref all.tokenized.$l/train \
    --validpref all.tokenized.$l/valid \
    --testpref all.tokenized.$l/test \
    --destdir data-bin/all.tokenized.$l \
    --joined-dictionary
done