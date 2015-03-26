#!/usr/local/bin/python2.7
# -*- coding: utf-8 -

# import requests
from requests import Request, Session

# TODO command line options: conf file, order's status file
conf = {}
execfile("bin/bx-update-order-status.conf", conf)

if conf['site'].endswith('arc.world'):
   verify_flag=False
else:
   verify_flag=True

url='https://' + conf['site'] + '/bitrix/admin/1c_exchange.php'
sess = Session()
sess.verify=verify_flag
# sess.auth=(conf['site_user'], conf['site_pword'])
req = Request('GET', 
            url,
            auth=(conf['site_user'], conf['site_pword']),
)

# authentication
req.params={'type': 'sale', 'mode': 'checkauth', 'version': conf['version']}
prepped = sess.prepare_request(req)
resp = sess.send(prepped)
(auth_result, cookie_file, cookie_value, sessid) = resp.text.split()
"""
print resp.text
print "="
print auth_result
print cookie_file
print cookie_value
print sessid
"""

# if authorized
if 'success' == auth_result:
    print "Success!"
    # initializing
    sess_id = sessid.split('=')
    req.params={'type': 'sale', 'mode': 'init', 'version': conf['version'], 'sessid': sess_id[1]}
    prepped = sess.prepare_request(req)
    resp = sess.send(prepped)
    print resp.text
    (zip_enabled, file_limit, sessid, version) = resp.text.split()

    # TODO check file_limit

    # sending file to site
    sess_id = sessid.split('=')
    req.params={'type': 'sale', 'mode': 'file', 'filename': 'order-update.zip', 'sessid': sess_id[1]}
    req.method='POST'
    prepped = sess.prepare_request(req)
    resp = sess.send(prepped)
    print resp.text

    # wait for processing sent file 
    proc_status = 'progress'
    while 'progress' == proc_status:
        req.params={'type': 'sale', 'mode': 'import', 'filename': 'order-update.zip', 'sessid': sess_id[1]}
        req.method='GET'
        prepped = sess.prepare_request(req)
        resp = sess.send(prepped)
        print resp.text
        (proc_status, proc_msg) = resp.text.split('\n')
        #answ = resp.text.split()
        #print answ
        #proc_status = ''



