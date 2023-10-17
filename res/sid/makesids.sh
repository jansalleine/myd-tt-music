#!/bin/sh
for i in *.c64
do
    name=$(echo "$i" | cut -f 1 -d '.')
    ../../tools/makesid/makesid.sh $i $name
done
