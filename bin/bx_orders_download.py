#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

import os
from requests import Request, Session
from sys import exit
import codecs
import time
import re
import logging


escaped = re.compile(u'&(?!quot;|lt;|amp;|gt;|apos;)')

def get_xml_list_fixed(inp_text):
    global escaped
    xml_orders = []
    for l1 in inp_text:
        l = re.sub(u'windows\-1251', u'UTF-8', l1).lstrip()
        esc_found = escaped.search(l)
        if esc_found:
            broken_fixed = re.sub(r'&(\w+)', '', l )
            if broken_fixed:
                xml_orders.append(broken_fixed)
        else:
           xml_orders.append(l)
    return xml_orders

def elem2str(aLabel, aTag, aText, sql_flds, sql_vals):
    if None != aText and u'\n' != aText:
       rstr = aLabel + aTag + u'=' + aText +u'\n'
       sql_flds.append(' "' + aTag.replace(' ', '_') + u'"')
       sql_vals.append(' \'' + aText.replace('\'', '\'\'') + u'\'')
    else:
       rstr = u''
    return rstr

################## Main ###################################

# TODO command line options: conf file, logging_level, order's status file
log_dir = ''
log_format = '[%(filename)-20s:%(lineno)4s - %(funcName)20s()] %(levelname)-7s | %(asctime)-15s | %(message)s'

(prg_name, prg_ext) = os.path.splitext(os.path.basename(__file__))
logging.basicConfig(filename=prg_name+'.log', filemode = 'a', format=log_format, level=logging.INFO)


conf = {}
execfile(prg_name+".conf", conf)

if conf['site'].endswith('arc.world'):
   verify_flag = False
   proto = 'http://'
else:
   verify_flag = True
   proto = 'https://'

re_ver_num = re.compile(r'<НомерВерсии>(\d+)</НомерВерсии>')

url = proto + conf['site'] + '/bitrix/admin/1c_exchange.php'

sess = Session()
sess.headers['Connection'] = 'close'
sess.verify=verify_flag
sess.keep_alive = True

# authentication
req = Request('GET', 
            url,
            auth=(conf['site_user'], conf['site_pword']),
)
req.params={'type': 'sale', 'mode': 'checkauth', 'version': conf['version']}
prepped = sess.prepare_request(req)
resp = None
try:
    resp = sess.send(prepped)
    logging.debug("checkauth prepped sent")
    logging.debug("checkauth resp.status_code=%s", resp.status_code)
    logging.debug("checkauth resp.text=%s", resp.text)

    if 200 != resp.status_code:
        logging.debug("checkauth code NEQ 200, sess.headers=%s, sess.params=%s", str(sess.headers),  str(sess.params))
        exit(resp.status_code)

    saved_cookies = resp.cookies
    logging.debug("resp.cookies=%s", str(resp.cookies))

    (auth_result, cookie_file, cookie_value, sessid) = resp.text.split()
    logging.debug("Parsed by =")
    logging.debug("auth_result=%s", auth_result)
    logging.debug("cookie_file=%s", cookie_file)
    logging.debug("cookie_value=%s", cookie_value)
    logging.debug("sessid=%s", sessid)

    # if authorized
    if 'success' == auth_result:
        logging.info("Authentication succeed!")
        sess_id = sessid.split('=')
        # initializing
        req.params={'type': 'sale', 'mode': 'init', 'version': conf['version'], 'sessid': sess_id[1]}
        prepped = sess.prepare_request(req)
        sess.cookies = saved_cookies
        resp = sess.send(prepped)
        logging.debug("init resp.text=%s", resp.text)
        (zip_enabled, file_limit, sessid, version) = resp.text.split()

        # query orders from site
        sess_id = sessid.split('=')
        req.params={'type': 'sale', 'mode': 'query', 'version': conf['version'], 'sessid': sess_id[1]}
        req.method='GET'
        prepped = sess.prepare_request(req)
        sess.cookies = saved_cookies
        resp = sess.send(prepped)
        xml_from_site = resp.text


        if 200 == resp.status_code:
            # send 'success'
            req.params={'type': 'sale', 'mode': 'success', 'version': conf['version'], 'sessid': sess_id[1]}
            prepped = sess.prepare_request(req)
            sess.cookies = saved_cookies
            resp = sess.send(prepped)
            logging.debug("success resp.text=%s", resp.text)

            xml_orders = get_xml_list_fixed(xml_from_site.splitlines())
            logging.debug("len(xml_orders)=%s", len(xml_orders))

            if 4 == len(xml_orders):
                logging.debug('empty xml, just header. Skip DB operation.')
            else:
                ver_num = '0'
                for x in xml_orders:
                    m_ver = re_ver_num.match(x.encode('utf-8'))
                    if m_ver:
                        ver_num = m_ver.group(1)

                xml_lines = u"\n".join(xml_orders)
                fname_templ = conf['site'] + "-%Y-%m-%d_%H-%M-%S"
                sql_outfile_name = time.strftime("02-sql/orders-" + fname_templ + ".sql")
                xmlf_name = time.strftime("01-xml/orders-" + fname_templ + ".xml")
                # xmlf_name = time.strftime("01-xml/orders-" +conf['site'] + "-%Y-%m-%d_%H-%M-%S.xml")
                xmlf=codecs.open(xmlf_name, 'w', 'utf-8')
                xmlf.write(xml_lines)
                xmlf.close()
                logging.info("wrote xml file: %s", xmlf_name)

except Exception as e:
    logging.critical("exception=%s", str(e))


############## Bottom line #########################
