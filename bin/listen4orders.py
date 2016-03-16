#!/usr/bin/env python
# -*- coding: utf-8 -*-

# import requests
from requests import Request, Session
import requests.exceptions
from sys import exit
import codecs
import time
import re
import argparse

import signal
import select
import psycopg2
import psycopg2.extensions
import logging
from xml.etree import ElementTree as ET
from xml.etree.ElementTree import tostring


parser = argparse.ArgumentParser(description='BX orders listener.')
#parser.add_argument('--host', type=str, help='PG host')
#parser.add_argument('--db', type=str, help='database name')
#parser.add_argument('--user', type=str, help='db user')

#parser.add_argument('--log', type=str, default="INFO", help='log level')
parser.add_argument('--log', type=str, default="DEBUG", help='log level')
args = parser.parse_args()

SIGNALS_TO_NAMES_DICT = dict((getattr(signal, n), n) for n in dir(signal)
                             if n.startswith('SIG') and '_' not in n)


def signal_handler(asignal, frame):
    # print('\nGot signal: ',
    #      SIGNALS_TO_NAMES_DICT.get(asignal, "Unnamed signal: %d" % asignal))
    logging.info('Got signal: %s',
          SIGNALS_TO_NAMES_DICT.get(asignal, "Unnamed signal: %d" % asignal))
    global do_listen, con, sess, req
    do_listen = False
    logging.debug('after do_listen = False')
    logging.debug('sess.headers=' + str(sess.headers))
    logging.debug('req.headers=' + str(req.headers))
    con.close()
    logging.debug('after con.close()')
    req = None
    logging.debug('after req = None')
    sess.close()
    logging.debug('after sess.close()')
    sess = None
    logging.debug('after sess = None')

signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGHUP, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

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



def parse_xml_insert_into_db(site, root, pg_conn, db_buyers, db_orders, sqlf_name):
    global logging
    existing_order = re.compile(u'Статуса заказа ИД=(.*)')
    # db_buyers = []  -  fetchall from DB
    sqlf=codecs.open(sqlf_name, 'w', 'utf-8')
    for child in root:
        bx_order_id = child.find(u'Номер').text
        outf_name = '02-sql/order-'+ site + '-' + bx_order_id +'.tmp'
        outf = codecs.open(outf_name, 'w', 'utf-8')

        sql_flds = []
        sql_vals = []
        for clients in child.findall(u'Контрагенты'):
            for cli in clients.findall(u'Контрагент'):
                # DEBUG outf.write(u'    -- next client\n')
                for elem in cli.iter():
                    if u'Ид'== elem.tag:
                        outf.write(u'\n\n-- ###################################################\n')
                        outf.write(elem2str(u'-- bx_order:', elem.tag, elem.text, sql_flds, sql_vals))
                        buyer = elem.text.split("#") #0-id, 1-bx_logname, 2-bx_name
                        sb_id = buyer[0]
                        buyer[1] = buyer[1].strip(u' ')
                        buyer[2] = buyer[2].strip(u' ')
                        #outf.write(u"-- typeof sb_id=" + str(type(sb_id)) + u"'\n")
                        #print 'sb_id=', sb_id
                        #print 'sb_id_key=', (int(sb_id), )
                        #print db_buyers
                        if (int(sb_id), ) in db_buyers:
                            outf.write(u"-- UPDATE bx_buyer SET bx_logname='" + buyer[1] + u"', bx_name='" + buyer[2] + u"'\n")
                            outf.write(u"-- WHERE bx_buyer_id=" + buyer[0] +";\n")
                        else:
                            db_buyers.append( (int(sb_id), ) )
                            #print "after append db_buyers=", db_buyers
                            outf.write(u'INSERT INTO bx_buyer(bx_buyer_id,bx_logname,bx_name)\n')
                            outf.write(u"VALUES (\'" + u'\', \''.join(buyer) + "\');\n")


        outf.write(u"\nINSERT INTO bx_order(\n")

        sql_flds = ['bx_buyer_id']
        sql_vals = [sb_id]
        for elem in child.findall(u'*'):
            outf.write(elem2str(u'-- bx_order:', elem.tag, elem.text, sql_flds, sql_vals))
        #### bx_order_id = child.find(u'Номер').text
        if (int(bx_order_id), ) in db_orders:
            flagNew = False
        else:
            flagNew = True
            db_orders.append( (int(bx_order_id), ) )

        for reqs in child.findall(u'ЗначенияРеквизитов'):
            sale_order_features_insert_dict = []
            for req in reqs.findall(u'ЗначениеРеквизита'):
                sale_order_features_insert = u'INSERT INTO bx_order_feature (bx_order_Номер, fname, fvalue) VALUES(' + bx_order_id +',\n'
                str1 = u''

                for elem in req.iterfind(u'Наименование'):
                    str1 = elem.text
                    sale_order_features_insert += '\'' + elem.text + '\', '
                for elem in req.iterfind(u'Значение'):
                    if elem.text:
                        elem_text = elem.text.replace('\r\n','/').replace('\n','/')
                        #'/'.join(elem_text.splitlines())
                    else:
                        elem_text = u""
                    str1 = str1 + u'=' + elem_text+'\n'
                    sale_order_features_insert += '\'' + elem_text + '\');'
                #order_status = existing_order.search(str1)
                #if order_status:
                #    tmp_status = u''
                #    tmp_status = tmp_status + order_status.group(1)
                    #outf.write(u" >>> order_status=_" + tmp_status + u"_\n")
                #    if 'N' == tmp_status:
                #        flagNew = True
                        #outf.write(u" >>> flagNew=True\n")
                #    else:
                #        flagNew = False
                        #outf.write(u" >>> flagNew=False\n")
                outf.write(u"-- Реквизит::"+str1)
                req.clear()
                sale_order_features_insert_dict.append(sale_order_features_insert)

        outf.write(u','.join(sql_flds) + ")\n")
        outf.write(u"VALUES (" + u','.join(sql_vals) + ");\n\n")

        for insert_clause in sale_order_features_insert_dict:
            outf.write(insert_clause + '\n')


        sql_flds = ['bx_order_Номер']
        sql_vals = []
        sql_vals.append(bx_order_id)
    # OLD place    outf.write(u"INSERT INTO bx_order_item(\n")
        for basket in child.findall(u'Товары'):
            # IT WORKS! for sale_item in basket.findall(u'*'):
            for sale_item in basket.iter(u'Товар'):
                outf.write(u"\nINSERT INTO bx_order_item(\n")
                if sale_item.find(u'Ид').text:
                   bx_order_item_id = sale_item.find(u'Ид').text
                else:
                   bx_order_item_id = u"NO_ID"
                #bx_order_item_id = sale_item.find(u'Ид').text
                for discounts in sale_item.findall(u'Скидки'):
                    for discount in discounts.findall(u'Скидка'):
                        outf.write(u"-- Пропускаем скидку:" + discount.text + "\n")
                        for disc_req in discount.iter():
                            outf.write(u"-- disc_req:" + disc_req.tag + "/" + disc_req.text + "\n")
                        discounts.remove(discount)
                for reqs in sale_item.findall(u'ЗначенияРеквизитов'):
                    sale_item_features_insert_dict = []
                    for req in reqs.findall(u'ЗначениеРеквизита'):
                        sale_item_features_insert = u"INSERT INTO bx_order_item_feature (bx_order_Номер, bx_order_item_id, fname, fvalue) VALUES(" + bx_order_id +", '" + bx_order_item_id +"',\n"
                        str1 = u''
                        for elem in req.iterfind(u'Наименование'):
                            str1 = elem.text
                            sale_item_features_insert += '\'' + elem.text + '\', '
                        for elem in req.iterfind(u'Значение'):
                            if elem.text:
                                elem_text = elem.text
                            else:
                                elem_text = u""
                            str1 = str1 + u'=' + elem_text+'\n'
                            sale_item_features_insert += '\'' + elem_text + '\');'
                        outf.write(u"-- Реквизит::"+str1)
                        req.clear()
                        # After INSERT  bx_order_item  outf.write(sale_item_features_insert + '\n')
                        sale_item_features_insert_dict.append(sale_item_features_insert)


                outf.write(u'    -- next item\n')
                sql_flds = [u'bx_order_Номер']
                sql_vals = []
                sql_vals.append(bx_order_id)


                for elem in sale_item.iter():
                    outf.write(elem2str(u'-- bx_order_item:', elem.tag, elem.text, sql_flds, sql_vals))
                outf.write(u','.join(sql_flds) + ")\n")
                outf.write(u"VALUES (" + u','.join(sql_vals) + ");\n\n")

                for insert_clause in sale_item_features_insert_dict:
                    outf.write(insert_clause + '\n')

        # outf.write(u'SELECT fn_createinetbill('+ bx_order_id +u');')
        outf.close()
        if flagNew:
            outf = codecs.open(outf_name, 'r', 'utf-8')
            sqlf.write(outf.read())
            outf.seek(0)
            sql_lines = u"".join(outf.readlines())
            outf.close()
            logging.debug("len(sql_lines)=%s", len(sql_lines))
            cur = pg_conn.cursor()
            if len(sql_lines) > 0:
                cur.execute(sql_lines)
                cur.close()
                logging.debug("sql_lines executed")
                pg_conn.commit()
                logging.debug("sql_lines commited")
        else:
            # TODO update Canceled orders
            sqlf.write("-- Skip existing order " + bx_order_id + "\n")

    sqlf.close()



################## Main ###################################

# TODO command line options: conf file, order's status file
conf = {}
execfile("bx-exchange.conf", conf)

if conf['site'].endswith('arc.world'):
   verify_flag = False
   proto = 'http://'
else:
   verify_flag = True
   proto = 'https://'

numeric_level = getattr(logging, args.log, None)
if not isinstance(numeric_level, int):
    raise ValueError('Invalid log level: %s' % loglevel)
logging.basicConfig(filename='bx-listener.log', format='%(asctime)s %(levelname)s: %(message)s', level=numeric_level) # INFO)


con = psycopg2.connect("host='" + conf["pg_srv"] + "' dbname='arc_energo' user='arc_energo'") # password='XXXX' - .pgpass
#TODO check return code
cur = con.cursor()
cur.execute('SELECT bx_buyer_id FROM bx_buyer')
db_buyers = cur.fetchall()
cur.execute('SELECT "Номер" FROM bx_order')
db_orders = cur.fetchall()

url = proto + conf['site'] + '/bitrix/admin/1c_exchange.php'
sess = Session()
sess.headers['Connection'] = 'close'
sess.verify=verify_flag
sess.keep_alive = True

# TODO trap signals/interrupts
do_listen = True
while do_listen:
    # listen, real-time mode
    req = Request('GET', url)
    req.params={'type': 'listen'}
    prepped = sess.prepare_request(req)
    logging.debug("start listen")
    try:
        #resp = sess.send(prepped, timeout=30)
        resp = sess.send(prepped)
        logging.debug("listen prepped sent")
    except Exception as e:
        logging.debug("listen exception=%s", str(e))
        resp = None
        continue
    finally:
        if resp is None:
            logging.debug("listen NO resp")
        else:
            logging.debug("listen resp.status_code=%s", resp.status_code)
            logging.debug("listen resp.text=%s", resp.text)

    if 200 != resp.status_code:
        continue

    saved_cookies = resp.cookies
    logging.debug("resp.cookies=%s", str(resp.cookies))
    # TODO
    # if resp.text contains 'success'

    # authentication
    req = Request('GET', 
                url,
                cookies = saved_cookies,
                auth=(conf['site_user'], conf['site_pword']),
    )
    req.params={'type': 'sale', 'mode': 'checkauth', 'version': conf['version']}
    prepped = sess.prepare_request(req)
    try:
        resp = sess.send(prepped)
        logging.debug("checkauth prepped sent")
    except Exception as e:
        logging.debug("checkauth exception=%s", str(e))
        resp = None
        continue
    finally:    
        if resp is None:
            logging.debug("checkauth NO resp")
        else:
            logging.debug("checkauth resp.status_code=%s", resp.status_code)
            logging.debug("checkauth resp.text=%s", resp.text)
    if 200 != resp.status_code:
        continue

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
        resp = sess.send(prepped)
        logging.debug("init resp.text=%s", resp.text)
        (zip_enabled, file_limit, sessid, version) = resp.text.split()

        # query orders from site
        sess_id = sessid.split('=')
        req.params={'type': 'sale', 'mode': 'query', 'version': conf['version'], 'sessid': sess_id[1]}
        req.method='GET'
        prepped = sess.prepare_request(req)
        resp = sess.send(prepped)
        xml_from_site = resp.text


        if 200 == resp.status_code:
            # send 'success'
            req.params={'type': 'sale', 'mode': 'success', 'version': conf['version'], 'sessid': sess_id[1]}
            prepped = sess.prepare_request(req)
            resp = sess.send(prepped)
            logging.debug("success resp.text=%s", resp.text)

            xml_orders = get_xml_list_fixed(xml_from_site.splitlines())
            logging.debug("len(xml_orders)=%s", len(xml_orders))
            if 4 == len(xml_orders):
                logging.debug('empty xml, just header. Skip')
                continue
            else:
                xml_lines = u"\n".join(xml_orders)



            fname_templ = conf['site'] + "-%Y-%m-%d_%H-%M-%S"
            sql_outfile_name = time.strftime("02-sql/orders-" + fname_templ + ".sql")
            xmlf_name = time.strftime("01-xml/orders-" + fname_templ + ".xml")
            # xmlf_name = time.strftime("01-xml/orders-" +conf['site'] + "-%Y-%m-%d_%H-%M-%S.xml")
            xmlf=codecs.open(xmlf_name, 'w', 'utf-8')
            xmlf.write(xml_lines)
            xmlf.close()
            logging.debug("wrote xml file: %s", xmlf_name)

            el = ET.fromstring(xml_lines.encode('utf-8'))
            logging.debug("xml_lines was parsed")
            parse_xml_insert_into_db(conf['site'], el, con, db_buyers, db_orders, sql_outfile_name)
            logging.debug("sql-files created: %s", sql_outfile_name)
            # cur.callproc('fn_inetbill4neworders')

            # debug
            # do_listen = False

cur.close()

############## Bottom line #########################
