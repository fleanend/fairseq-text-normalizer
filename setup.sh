#!/usr/bin/env bash
#
# pulire e mettere dentro a install

# new-casaccia new-gazzo new-piaggio new-balilla1872
chmod 755 ./src/create_dataset.sh 
chmod 755 ./src/train_back_translators.sh 
chmod 755 ./src/back_translate.sh 
chmod 755 ./src/create_secondary_dataset.sh 

git clone https://github.com/pytorch/fairseq
cd fairseq
pip install fairseq==0.10.2
git clone https://github.com/kahne/fastwer
pip install pybind11
pip install fastwer

