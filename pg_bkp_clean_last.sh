#!/bin/bash

# CONFIG
bkpdir=/mnt/backup/dbs           # backup root

# MAIN
date=`date +%Y-%m-%d`
rm -fv ${bkpdir}/${date}/last/*bkp > ${bkpdir}/${date}/last/clean.out
