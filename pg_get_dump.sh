#!/bin/bash

# TODO сделать опцию - не удалять промежуточные восстановления - например: для быстрого развёртывания пред. дельты

if [ -z $1 ]; then
    echo "usage: $(basename $0) [delta file name]"
    exit 1
fi

echo '---------------------------------------------'
date
echo "DECRUNCHING $1 ..."
if [ ! -e ${1} ]; then
    echo "ERROR: not found delta: \"${1}\" "
    exit 1
fi

dumpdir=$(dirname "${1}")
cd ${dumpdir}

source_line=$(xdelta3 printdelta ${1} | head -n10 | grep 'XDELTA filename (source):')
source=`expr "$source_line" : '.*(source):\s*\(.*\)'`
target_line=$(xdelta3 printdelta ${1} | head -n10 | grep 'XDELTA filename (output):')
target=`expr "$target_line" : '.*(output):\s*\(.*\)'`


if [ -z ${source} ]; then
    echo "ERROR: not found source name in: \"${source_line}\" "
    exit 1
fi
if [ -z ${target} ]; then
    echo "ERROR: not found target name in: \"${target_line}\" "
    exit 1
fi

cd ${dumpdir}
if [ -e ${source} ]; then
    echo "    SOURCE FOUND. MAKE TARGET FROM SOURCE"
    xdelta3 -f -d -s ${source} ${1} ${target} || exit 1
    rm ${source}
elif [ -e ${source}.gz ]; then
    echo "    EXTRACT SOURCE FROM GZ"
    zcat ${source}.gz > ${source}
    echo "    MAKE TARGET FROM SOURCE"
    xdelta3 -f -d -s ${source} ${1} ${target} || exit 1
    rm ${source}
else
    if [ -e ${source}.delta ]; then
        echo "    SOURCE DELTA FOUND. DIVE..."
        $0 ${source}.delta || exit 1
        exec $(readlink -f "$0") $1
    else
        echo "ERROR: not found ${target}.delta"
        exit 1
    fi
fi

date
exit 0
