#!/bin/bash

for dir in *_*
do
 cd $dir
 cat /dev/null > AllSlides.txt
 for file in 0*; do echo "include::$file[]" >> AllSlides.txt ; done
 cd ..
done
