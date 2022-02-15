#!/usr/bin/env bash
#


start_folder=$1
langs=$2
SCRIPTS=fairseq/scripts
SPM_ENCODE=$SCRIPTS/spm_encode.py

for l in $langs; do
    test=$(echo $l | tr "-" " ")
    set -- $test
    
    mv all.tokenized.$l/tmp/test.$2 all.tokenized.$l/tmp/test_bk.$2
    mv all.tokenized.$l/tmp/test.$1 all.tokenized.$l/tmp/test_bk.$1
	
    cp all.tokenized.old-new/tmp/train.tags.old-new.mono.clean.old all.tokenized.$l/tmp/test.$2
    cp all.tokenized.old-new/tmp/train.tags.old-new.mono.clean.new all.tokenized.$l/tmp/test.$1
	for i in $test; do
		f=test.$i
		python "$SPM_ENCODE" \
        --model "$start_folder/sentencepiece_$l.bpe.model" \
        --output_format=piece \
        --inputs all.tokenized.$l/tmp/$f \
        --outputs all.tokenized.$l/$f
	done
   fairseq-preprocess --source-lang $1 --target-lang $2 \
    --testpref all.tokenized.$l/test \
    --destdir data-bin/all.tokenized.$l \
    --srcdict data-bin/all.tokenized.$l/dict.$1.txt \
    --tgtdict data-bin/all.tokenized.$l/dict.$2.txt

    fairseq-generate data-bin/all.tokenized.$l \
    --path $start_folder/models/back_$l.pt \
    --batch-size 128 --beam 5 --results-path back_$l
    python $start_folder/src/utils/back_translate.py $l -s -o $start_folder/data/processed
    
    mv all.tokenized.$l/tmp/test_bk.$2 all.tokenized.$l/tmp/test.$2
    mv all.tokenized.$l/tmp/test_bk.$1 all.tokenized.$l/tmp/test.$1
    
    for i in $test; do
		f=test.$i
		python "$SPM_ENCODE" \
        --model "$start_folder/sentencepiece_$l.bpe.model" \
        --output_format=piece \
        --inputs all.tokenized.$l/tmp/$f \
        --outputs all.tokenized.$l/$f
	done
    fairseq-preprocess --source-lang $1 --target-lang $2 \
    --testpref all.tokenized.$l/test \
    --destdir data-bin/all.tokenized.$l \
    --srcdict data-bin/all.tokenized.$l/dict.$1.txt \
    --tgtdict data-bin/all.tokenized.$l/dict.$2.txt
done