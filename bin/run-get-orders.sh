#!/bin/sh

do_loop=1

while [ "+1" == +$do_loop ]
do
   /usr/bin/pkill -f 'python.*get-orders\.py'
   if [ $? -eq 0 ]
   then
      echo `date "+%F_%H-%M-%S"`
   fi
   bin/get-orders.py --log DEBUG &
   sleep 60
done
