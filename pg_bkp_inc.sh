#!/bin/bash

# CONFIG
bkpdir=/mnt/backup/dbs            # backup root
db=(mpru_lod_db mo_lod_db)        # databases for backup list

# MAIN
date
PATH=/bin:/usr/bin
date=`date +%Y-%m-%d`
mkdir -p ${bkpdir}/${date}/last
dumpdir=${bkpdir}/${date}         # directory name for today dumps
datehour=`date +%Y-%m-%d__%H`     # file name for current dumps

for (( i=0; i<${#db[*]}; i++ ))
do
    dbname=${db[$i]}
    fname=${dbname}__${datehour}.incbkp

    # check prev dump
    fresh_full_dump=$(ls -t ${dumpdir}/last/*${dbname}*.*bkp | head -1)
    echo "FRESH DUMP NAME: ${fresh_full_dump}"
    if [ -z ${fresh_full_dump} ]; then
        echo "ERROR with dumping ${dbname}: not found last dump" > ${dumpdir}/${fname}.error
        continue
    fi

    # clean
    rm ${dumpdir}/last/${fname}.part    # 2> /dev/null
    rm ${dumpdir}/last/${fname}         # 2> /dev/null
    rm ${dumpdir}/${fname}.error        # 2> /dev/null

    # dumping
    PGPASSWORD=qbdhnLs4 nice pg_dump -U lod -Ox -T mamonsu_* -h 10.4.126.28 -d ${dbname} > ${dumpdir}/last/${fname}.part 2> ${dumpdir}/${fname}.error
    if [ -s ${dumpdir}/${fname}.error ]; then
        rm ${dumpdir}/last/${fname}.part
        echo "ERROR with dumping ${dbname}: "
        cat ${dumpdir}/${fname}.error
    else
        rm ${dumpdir}/${fname}.error
        mv ${dumpdir}/last/${fname}.part ${dumpdir}/last/${fname}
        nice xdelta3 -e -s ${fresh_full_dump} ${dumpdir}/last/${fname} ${dumpdir}/${fname}.delta 2> ${dumpdir}/${fname}.error
        if [ -s ${dumpdir}/${fname}.error ]; then
            rm ${dumpdir}/${fname}.delta
            echo "ERROR with delta encoding ${dbname}: "
            cat ${dumpdir}/${fname}.error
        else
            rm ${dumpdir}/${fname}.error
            rm ${fresh_full_dump}
            echo "SUCCESS with ${dbname}"
        fi
    fi
done
date
