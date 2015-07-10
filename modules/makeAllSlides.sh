#!/bin/bash

for dir in *_*
do
 cd $dir
 cat /dev/null > AllSlides.txt
 for file in *.adoc
 do
   tst=`echo $file|egrep "00_.*Complete|Labs"`
   if [ -z "$tst" ]
   then
     echo "include::$file[]" >> AllSlides.txt
   fi
 done
 cd ..
done
