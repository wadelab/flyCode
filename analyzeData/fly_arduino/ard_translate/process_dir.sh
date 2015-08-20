#!/bin/bash
for filename in ~/Documents/research/grants/summer_15/Olivia_Martin/*.SVP; do

echo $(basename $filename)
./ard_human_ERG "$filename" > $(basename $filename)

done
