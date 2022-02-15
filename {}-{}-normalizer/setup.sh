#!/usr/bin/env bash
#
# pulire e mettere dentro a install

git clone https://github.com/pytorch/fairseq
cd fairseq
pip install fairseq==0.10.2
git clone https://github.com/kahne/fastwer
pip install pybind11
pip install fastwer