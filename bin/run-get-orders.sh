#!/bin/sh

do_loop=1

while [ "+1" == +$do_loop ]
do
   bin/get-orders.py
   sleep 60
done
