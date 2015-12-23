
for module in `ls -d [0-9]*` ; do
  echo ${module}
  export COMPLETE_FILE=`ls ${module}/00*`

  echo >  ${COMPLETE_FILE}
  for file in   `ls ${module}/[0-9]*.adoc | grep -v 00 | sort` ; do
    cat ${file} >> ${COMPLETE_FILE};
  done

done



for module in `ls -d [0-9]*` ; do
  echo ${module}
  export COMPLETE_FILE=`ls ${module}/00*`
  ../AsciiDocSplitter.pl ${COMPLETE_FILE} ${module}

done



for module in `ls -d [0-9]*` ; do
  git add ${module}/*
done


module=01_Introduction_to_Course
echo ${module}
export COMPLETE_FILE=`ls ${module}/00*`

echo >  ${COMPLETE_FILE}
for file in   `ls ${module}/[0-9]*.adoc | grep -v 00 | sort` ; do
  cat ${file} >> ${COMPLETE_FILE};
done

  ../AsciiDocSplitter.pl ${COMPLETE_FILE} ${module}

for module in `ls -d [0-9]*` ; do
  echo ${module}
  export COMPLETE_FILE=`ls ${module}/00*`
  ../AsciiDocSplitter.pl ${COMPLETE_FILE} ${module}

done


for FILE in $(ls -d [0-9]*)
do
    echo Processing ${FILE}

    awk '{if (NR==1 && NF==0) next};1' < ${FILE} > ${FILE}.killfirstline
    mv ${FILE}.killfirstline ${FILE}

done

for module in `ls -d [0-9]*` ; do
  echo ${module}
  cp ${module}/assessment.txt ${module}/assessment.csv
done


for module in `ls -d [0-9]*` ; do
  echo ${module}
  cp ${module}/assessment.csv ${module}/assessment.txt
done
