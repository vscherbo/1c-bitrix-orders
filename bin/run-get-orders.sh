#!/bin/sh

do_loop=1

LOG=run-get-orders.log
exec 1>>$LOG 2>&1

while [ "+1" == +$do_loop ]
do
   /usr/bin/pgrep -f 'python.*get-orders\.py'
   if [ $? -eq 0 ]
   then
      echo get-orders is running `date "+%F_%H-%M-%S"`
   else
      bin/get-orders.py --log=INFO &
   fi
   sleep 60
done
