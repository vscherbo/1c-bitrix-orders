#!/bin/sh

DT=`date +%F_%H%M`
INST_LIST='listen4orders.sh bitrix-orders-to-pg.py'

for f in $INST_LIST
do
  # compare md5sum
  md5sum --quiet --status --check $f.md5
  RC=$?
  if [ $RC -ne 0 ]
  then
    # if not equal
    echo INSTALL $f
    mv ../$f ../$f-$DT && cp $f ../$f && { md5sum $f > $f.md5; }
  #else
  #  echo EQUAL
  fi
done

