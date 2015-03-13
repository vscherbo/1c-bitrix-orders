#!/bin/sh

. /usr/local/bin/bashlib

##################################################
#PG_SRV=vm-pg-devel
#SITE="kipspb2.arc.world"
#SITE="kipspb.ru"
##################################################

intrflag=0

trapINT(){
  logmsg INFO "Interrupt signal trapped. Finishing..."
  intrflag=1
}

CFG_FILE=${1:-`namename $0`.cfg}
saveIFS=$IFS
IFS=$'\n'
for str in `cat $CFG_FILE | sed 's/^ *//' | egrep -v '^$|^#'`; do
	eval $(echo $str|sed 's/ *=/=/;s/= */=/')
done
IFS=$saveIFS

VER=2.09
WRK_DIR=${WRK_DIR:-`dirname $0`}
BIN_DIR=$WRK_DIR/bin

cd $WRK_DIR

LOGON_RESULT=checkauth-answer.txt
LOGON_RESULT_TMP=checkauth-answer.tmp
LISTEN_RESULT=listen-answer.log
INIT_RESULT=init-listen.log
SUCCESS_RESULT=success-listen.log
XML_DIR=$WRK_DIR/01-xml
SQL_DIR=$WRK_DIR/02-sql
FAIL_DIR=$WRK_DIR/99-failed
LOG_DIR=$WRK_DIR/logs
PSQL=psql
PG_CONNECT="-h $PG_SRV -U arc_energo --echo-all"
PG_STRONG_OPTS=" --variable=ON_ERROR_STOP=1 --single-transaction"

[ -d $XML_DIR ] || mkdir -p $XML_DIR 
[ -d $SQL_DIR ] || mkdir -p $SQL_DIR 
[ -d $FAIL_DIR ] || mkdir -p $FAIL_DIR 
[ -d $LOG_DIR ] || mkdir -p $LOG_DIR 

WGET_AUTH_OPTS='--no-verbose --no-proxy --no-check-certificate --auth-no-challenge --keep-session-cookies --save-cookies cookies.txt'
WGET_QRY_OPTS='--no-verbose --no-proxy --load-cookies cookies.txt'

LOG=$LOG_DIR/`namename $0`-$SITE-`date +%F_%H_%M`.log
exec 1>$LOG 2>&1

while [ $intrflag -eq 0 ] ; do

    wget --no-proxy --read-timeout=3601 'http://'$SITE'/bitrix/admin/1c_exchange.php?type=listen' -O $LISTEN_RESULT
    date '+%F_%H_%M_%S ===========================' >> $LOGON_RESULT_TMP
    # logon to $SITE
    wget $WGET_AUTH_OPTS --read-timeout=3601 --http-user=$SITE_USER --http-password=$SITE_PWORD 'http://'$SITE'/bitrix/admin/1c_exchange.php?type=sale&mode=checkauth&version='$VER -O - >> $LOGON_RESULT_TMP

    cat $LOGON_RESULT_TMP >> $LOGON_RESULT

    # check success
    if `grep --silent "success" $LOGON_RESULT_TMP`
    then
       logmsg INFO "We are logged in"
       SESS_ID=`tail -1 $LOGON_RESULT_TMP | grep "sessid"`

       DT=`date +%F_%H_%M_%S`
       ORDERS_FILE=$XML_DIR/orders-listen-header1251-$DT.xml
       ORDERS_FIXED_NAME=orders-listen-$DT
       ORDERS_FIXED_XML=$XML_DIR/$ORDERS_FIXED_NAME.xml
       ORDERS_FIXED_SQL=$SQL_DIR/$ORDERS_FIXED_NAME.sql
       date '+%F_%H_%M_%S ===========================' >> $INIT_RESULT

       wget $WGET_QRY_OPTS 'http://'$SITE'/bitrix/admin/1c_exchange.php?type=sale&mode=init&version='$VER'&'$SESS_ID -O - |iconv -f cp1251 -t utf8 >> $INIT_RESULT
       echo "" >> $INIT_RESULT

       logmsg INFO "Query start"
       # trap 
       wget $WGET_QRY_OPTS 'http://'$SITE'/bitrix/admin/1c_exchange.php?type=sale&mode=query&version='$VER'&'$SESS_ID -O - |iconv -f cp1251 -t utf8 > $ORDERS_FILE
       rc=$?
       trap trapINT INT HUP SIGTERM # ERR
       logmsg $rc "Query completed"
       [ -s $ORDERS_FILE ] || rm -f $ORDERS_FILE              # zero-length file 
       [ 3 -eq `wc -l < $ORDERS_FILE` ] && rm -f $ORDERS_FILE # just header, no orders

       sleep 1
       date '+%F_%H_%M_%S ===========================' >> $SUCCESS_RESULT
       wget $WGET_QRY_OPTS 'http://'$SITE'/bitrix/admin/1c_exchange.php?type=sale&mode=success&version='$VER'&'$SESS_ID -O - |iconv -f cp1251 -t utf8 >> $SUCCESS_RESULT
       if `tail -1 $SUCCESS_RESULT | grep --silent "success"`
       then
          if [ -f $ORDERS_FILE ]; then
              sed -r -e 's/^[[:space:]]+//g' -e 's/>[[:space:]]*</>\n</g' -e 's/windows-1251/UTF-8/' $ORDERS_FILE > $ORDERS_FIXED_XML 
              logmsg INFO "Create $ORDERS_FIXED_SQL from $ORDERS_FIXED_XML"
              $BIN_DIR/bitrix-orders-to-pg.py $ORDERS_FIXED_XML $ORDERS_FIXED_SQL $PG_SRV
              logmsg $? "Finish create SQL-file $ORDERS_FIXED_SQL"
              logmsg INFO "Load $ORDERS_FIXED_SQL into PG server $PG_SRV"
              $PSQL $PG_CONNECT $PG_STRONG_OPTS -f $ORDERS_FIXED_SQL
              logmsg $? "Finish run SQL-file $ORDERS_FIXED_SQL"
              $PSQL $PG_CONNECT -c "SELECT fn_inetbill4neworders()"
          fi
       else
          logmsg ERROR "### Move $ORDERS_FILE to $FAIL_DIR"
          mv $ORDERS_FILE $FAIL_DIR
          mv $ORDERS_FIXED_XML $FAIL_DIR
          mv $ORDERS_FIXED_SQL $FAIL_DIR
       fi

       # clear trap
       trap - INT HUP SIGTERM ERR
       
    else
      logmsg ERROR "LOGON not successfull"
    fi
 
done

