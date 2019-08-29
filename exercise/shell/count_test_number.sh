#!/usr/bin/env bash
#if [ -f $1 != 0]; then
#    rm -rf $1
#    print 'delete file'
#    exit 2
#else
#    cat $1 |grep happy |wc -l
#fi


find /tmp/ -size +200k -print > file.log
countfile=$(wc -l file.log)
echo $countfile
for i in $countfile; do
   filename=$(head -$i file.log)
    cp $filename /tmp/a
done

find ./ -name "*.c" | xargs -i cp {} ./dog/
find ./ -name "*.c" -exec cp '{}' ./dog/ \;

find /tmp/ -size +200k -exec cp '{}' /tmp/a \;
