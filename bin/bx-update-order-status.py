#!/usr/local/bin/python2.7
# -*- coding: utf-8 -

import requests
import ConfigParser

Config = ConfigParser.ConfigParser()

# TODO command line options: conf file, order's status file
conf = {}
execfile("bin/bx-update-order-status.conf", conf)

if conf['site'].endswith('arc.world'):
   verify_flag=False
else:
   verify_flag=True

# authentication
auth_req = {'type': 'sale', 'mode': 'checkauth', 'version': conf['version']}
r = requests.get('https://'
                 +conf['site']
                 +'/bitrix/admin/1c_exchange.php',
                 params=auth_req,
                 auth=(conf['site_user'], conf['site_pword']),
                 verify=verify_flag)
(auth_result, cookie_file, cookie_value, sess_id)=r.text.split()
print r.text
print "="

print auth_result
print cookie_file
print cookie_value
print sess_id

# if authorized
if 'success' == auth_result:
    print "Success!"
    # initializing
    
    # sending file to site

    # wait for processing sent file 
