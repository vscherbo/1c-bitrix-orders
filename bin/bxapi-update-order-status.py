#!/usr/local/bin/python2.7
# -*- coding: utf-8 -

import paramiko

# TODO command line options: conf file, order's status file
conf = {}
execfile("bin/bxapi-update-order-status.conf", conf)

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(hostname=conf['host'], username=conf['user'], port=conf['port'])

cmd='php -f ./order-status-update.php 7332 O'
stdin, stdout, stderr = client.exec_command(cmd)
data = stdout.read() + stderr.read()
print "data=", data
client.close()
