[![arXiv](https://img.shields.io/badge/arXiv-2206.07861-<COLOR>.svg)](https://arxiv.org/abs/2206.07861)

# fairseq-text-normalizer

This repository contains code for paper [Text normalization for endangered languages: the case of Ligurian](https://arxiv.org/pdf/2206.07861v1.pdf).

## About
fair-normalizer is a streamlined text normalizer factory. 

It's built to train ortographic normalizers with Meta Research's [Fairseq toolkit](https://github.com/facebookresearch/fairseq) with extreme ease.

### Installing

Enter the project directory and install with setup.sh

```
cd fairseq-text-normalizer
sh setup.sh
```

## Usage

#### Train
Copy your monographic dataset into trascricion/data/raw as mono.new

Copy your parallel dataset into trascricion/data/raw as \<target\>-\<source\>.\<source\> and \<target\>-\<source\>.\<target\>

Run train.sh

```
sh train.sh <vocab_alphabet_ratio> <upsample_primary_ratio> <source> <target>
```

where 
- **source** is the orthography you want to normalize (e.g. old)
- **target** is the normalized orthography (e.g. new)
- **vocab_alphabet_ratio** is the ratio between the desired size of the vocabulary and the size of the set of all the characters present in the two orthographies (e.g. 1, which means that each token will represent a character)
- **upsample_primary_ratio** is the number of times real parallel data is show to the final model with respect to the back normalized data (e.g. tokens in monographic dataset divided by tokens in the parallel dataset)

When the training ends a new directory named \<source\>-\<target\>-normalizer will be created

#### Predict
To use the newly created normalizer:

Enter the project directory and setup everything
```
cd <source>-<target>-normalizer
sh setup.sh
```

Run translate.sh on a text in the \<source\> orthography
```
sh translate.sh <input> <output>
```
