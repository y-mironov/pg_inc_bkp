#!/bin/bash

# CONFIG
bkpdir=/mnt/backup/dbs            # backup root
db=(mpru_lod_db mo_lod_db)        # databases for backup list
exclude="-T mamonsu_*"            # exclude tables "-T table1 -T table2 ... -T tableN"
dbhost=127.0.0.1
dbpass="something_here"

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
    fname=${dbname}__${datehour}.fullbkp
    PGPASSWORD=${dbpass} nice pg_dump -U lod -Ox " ${exclude} " -h ${dbhost} -d ${dbname} > ${dumpdir}/last/${fname}.part 2> ${dumpdir}/${fname}.error
    if [ -s ${dumpdir}/${fname}.error ]; then
        rm ${dumpdir}/last/${fname}.part
        echo "ERROR with dumping ${dbname}:"
        cat ${dumpdir}/${fname}.error
    else
        rm ${dumpdir}/${fname}.error
        mv ${dumpdir}/last/${fname}.part ${dumpdir}/last/${fname}
        cat ${dumpdir}/last/${fname} | nice gzip > ${dumpdir}/${fname}.gz
        echo "SUCCESS with ${dbname}"
    fi
done
date
