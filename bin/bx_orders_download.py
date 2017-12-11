#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

import os
from requests import Request, Session
# from sys import exit
from codecs import open
import time
import re
import logging


def get_xml_list_fixed(inp_text):
    escaped = re.compile(u'&(?!quot;|lt;|amp;|gt;|apos;)')
    loc_xml_orders = []
    for inp_line in inp_text:
        utf8_line = re.sub(u'windows-1251', u'UTF-8', inp_line).lstrip()
        esc_found = escaped.search(utf8_line)
        if esc_found:
            broken_fixed = re.sub(r'&(\w+)', '', utf8_line)
            if broken_fixed:
                loc_xml_orders.append(broken_fixed)
        else:
            loc_xml_orders.append(utf8_line)
    return loc_xml_orders

def get_orders(site, site_user, site_pword, version):
    url = proto + site + '/bitrix/admin/1c_exchange.php'

    sess = Session()
    sess.headers['Connection'] = 'close'
    sess.verify = verify_flag
    sess.keep_alive = True

    # authentication
    req = Request('GET',
                  url,
                  auth=(site_user, site_pword),
                  )
    req.params = {'type': 'sale', 'mode': 'checkauth', 'version': version}
    prepped = sess.prepare_request(req)
    resp = None
    try:
        resp = sess.send(prepped)
        logging.debug("checkauth prepped sent")
        logging.debug("checkauth resp.status_code=%s", resp.status_code)
        logging.debug("checkauth resp.text=%s", resp.text)

        resp.raise_for_status()
        """
        if 200 != resp.status_code:
            logging.debug("checkauth code NEQ 200, sess.headers=%s, sess.params=%s", str(sess.headers), str(sess.params))
            exit(resp.status_code)
        """

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
            req.params = {'type': 'sale', 'mode': 'init', 'version': version, 'sessid': sess_id[1]}
            prepped = sess.prepare_request(req)
            sess.cookies = saved_cookies
            resp = sess.send(prepped)
            logging.debug("init resp.text=%s", resp.text)
            (zip_enabled, file_limit, sessid, version) = resp.text.split()

            # query orders from site
            sess_id = sessid.split('=')
            req.params = {'type': 'sale', 'mode': 'query', 'version': version, 'sessid': sess_id[1]}
            req.method = 'GET'
            prepped = sess.prepare_request(req)
            sess.cookies = saved_cookies
            resp = sess.send(prepped)
            xml_from_site = resp.text

            if 200 == resp.status_code:
                # send 'success'
                req.params = {'type': 'sale', 'mode': 'success', 'version': version, 'sessid': sess_id[1]}
                prepped = sess.prepare_request(req)
                sess.cookies = saved_cookies
                resp = sess.send(prepped)
                logging.debug("success resp.text=%s", resp.text)

                xml_orders = get_xml_list_fixed(xml_from_site.splitlines())
                logging.debug("len(xml_orders)=%s", len(xml_orders))

                if 4 == len(xml_orders):
                    logging.debug('empty xml, just header. Skip.')
                else:
                    xml_lines = u"\n".join(xml_orders)
                    fname_templ = site + "-%Y-%m-%d_%H-%M-%S"
                    xml_fname = time.strftime("01-xml/orders-" + fname_templ + ".xml")
                    xmlf = open(xml_fname, 'w', 'utf-8')
                    xmlf.write(xml_lines)
                    xmlf.close()
                    logging.info("wrote xml file: %s", xml_fname)

    except Exception:
        logging.critical("exception=%s", exc_info=True)
        xml_lines = None
    return xml_lines

# ------------------- Main -------------------

if __name__ == '__main__':
    # TODO command line options: conf file, logging_level, order's status file
    log_dir = ''
    log_format = '[%(filename)-20s:%(lineno)4s - %(funcName)20s()] %(levelname)-7s | %(asctime)-15s | %(message)s'

    (prg_name, prg_ext) = os.path.splitext(os.path.basename(__file__))
    logging.basicConfig(filename=prg_name + '.log', filemode='a', format=log_format, level=logging.DEBUG)

    conf = {}
    execfile(prg_name + ".conf", conf)

    site = conf['site']
    site_user = conf['site_user']
    site_pword = conf['site_pword']
    version = conf['version']

    if site.endswith('arc.world'):
        verify_flag = False
        proto = 'http://'
    else:
        verify_flag = True
        proto = 'https://'

    get_orders(site, site_user, site_pword, version)




# ------------ Bottom line -------------------------
