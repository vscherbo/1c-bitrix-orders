#!/bin/sh

do_loop=1

LOG=run-get-orders.log
exec 1>>$LOG 2>&1

while [ "+1" == +$do_loop ]
do
   /usr/bin/pgrep -f 'python.*bx_orders_parse\.py'
   if [ $? -eq 0 ]
   then
      echo bx_order_parse is running `date "+%F_%H-%M-%S"`
   else
      bin/bx_orders_parse.py --log_level=INFO --conf bx_orders_parse.conf --run_sql=True --create_bill=True
   fi
   sleep 60
done
