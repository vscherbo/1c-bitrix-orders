#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

import os
import argparse
import codecs
import time
import re

import psycopg2
import psycopg2.extensions
import logging
from xml.etree import ElementTree as ET


################## Main ###################################

# TODO command line options: conf file, logging_level, order's status file
(prg_name, prg_ext) = os.path.splitext(os.path.basename(__file__))
conf_file = prg_name +".conf"
log_file = prg_name +".log"

parser = argparse.ArgumentParser(description='Pg listener for .')
parser.add_argument('--conf', type=str, default=conf_file, help='conf file')
parser.add_argument('--xml_file', type=str, required=True, help='conf file')
parser.add_argument('--log_level', type=str, default="DEBUG", help='log level')
log_dir = ''
args = parser.parse_args()

numeric_level = getattr(logging, args.log_level, None)
if not isinstance(numeric_level, int):
    raise ValueError('Invalid log level: %s' % numeric_level)

log_format = '[%(filename)-20s:%(lineno)4s - %(funcName)20s()] %(levelname)-7s | %(asctime)-15s | %(message)s'

logging.basicConfig(filename=log_file, filemode = 'a', format=log_format, level=numeric_level)


conf = {}
# execfile(prg_name+".conf", conf)
execfile(args.conf, conf)

re_ver_num = re.compile(r'<НомерВерсии>(\d+)</НомерВерсии>')

"""
con = psycopg2.connect("host='" + conf["pg_srv"] + "' dbname='arc_energo' user='arc_energo'") # password='XXXX' - .pgpass
#TODO check return code
"""

xmlf=codecs.open(args.xml_file, 'r', 'utf-8')
xml_lines = xmlf.read()
xmlf.close()
logging.info("read xml file: %s", args.xml_file)

bx_orders = []
pg_order_fields = (
    u"Ид",
    u"Номер",
    u"Дата",
    u"ХозОперация",
    u"Роль",
    u"Валюта",
    u"Курс",
    u"Сумма",
    u"Время",
    u"НомерВерсии"
)

pg_order_item_fields = (
    u"Ид",
    u"ИдКаталога",
    u"Наименование",
    u"Единица/Код",
    u"Единица/НаименованиеПолное",
    u"Коэффициент",
    u"ЦенаЗаЕдиницу",
    u"Количество",
    u"Сумма",
)

el = ET.fromstring(xml_lines.encode('utf-8'))
# logging.info("xml_lines were parsed")
for bx_order in el.findall(u'Документ'):
    logging.debug(bx_order.tag.encode('utf-8')) # 'Документ'
    bx_counterpart = bx_order.find(u'Контрагенты/Контрагент')
    bx_buyer = bx_counterpart.find(u'Ид').text #.encode('utf-8')
    buyer = bx_buyer.split("#") # 0-bx_buyer_id, 1-bx_buyer_login, 2-bx_buyer_name
    bx_buyer_id = buyer[0]
    bx_buyer_login = buyer[1].strip(' ')
    bx_buyer_name = buyer[2].strip(' ')
    flagFastOrder = 'OrderUser' in bx_buyer_login
    bx_buyer_inn = bx_counterpart.find(u'ИНН')
    bx_buyer_kpp = bx_counterpart.find(u'КПП')
    loc_legal_entity = bx_buyer_inn is not None
    logging.debug("bx_buyer_id={0}, юр.лицо={1}".format(bx_buyer_id, loc_legal_entity))
    # TODO search buyer_id in DB
    # insert OT update bx_buyer

    pg_order_vals = []
    doc_id = bx_order.find(u'Ид').text
    # TODO search order_id in DB
    # bx_orders.append(doc_id)
    # if FOUND do not write sql into file, just comment

    sql_outfile_name = "02-sql/order-{0}-{1}-{2}.sql".format(conf['site'], doc_id, time.strftime("%Y-%m-%d_%H-%M-%S"))
    sqlf=open(sql_outfile_name, 'w')  # , 'utf-8')

    for f in pg_order_fields:
        val = bx_order.find(f).text.encode('utf-8')
        pg_order_vals.append(val)

    flds = ', '.join(map(u'"{0}"'.format, pg_order_fields))
    flds = u'bx_buyer_id, {0}'.format(flds)
    pg_order_vals.insert(0, bx_buyer_id)
    vals = ', '.join(map("'{0}'".format, pg_order_vals))
    # logging.debug(flds)
    # logging.debug(vals)
    sql_bx_order = 'INSERT INTO bx_order({0}) VALUES({1});\n'.format(flds.encode('utf-8'), vals)
    logging.debug(sql_bx_order)
    sqlf.write(sql_bx_order)

    for bx_order_feature in bx_order.findall(u'ЗначенияРеквизитов/ЗначениеРеквизита'):
        bof_name = bx_order_feature.find(u'Наименование').text.encode('utf-8')
        bof_value = bx_order_feature.find(u'Значение').text.encode('utf-8').replace('\r\n','/').replace('\n','/').replace("'", "''")
        insert_bx_order_feature = 'INSERT INTO bx_order_feature("bx_order_Номер", fname, fvalue)'
        values_bx_order_feature = "VALUES({0}, '{1}', '{2}');\n".format(doc_id, bof_name, bof_value)
        sql_bx_order_feature = "{0} {1}".format(insert_bx_order_feature, values_bx_order_feature)
        logging.debug(sql_bx_order_feature)
        sqlf.write(sql_bx_order_feature)
    
    for bx_item in bx_order.findall(u'Товары/Товар'):
        pg_order_item_vals = []
        bx_item_id = bx_item.find(u'Ид').text
        logging.debug('bx_item_id={0}'.format(bx_item_id))
        for f in pg_order_item_fields:
            val = bx_item.find(f).text.encode('utf-8')
            pg_order_item_vals.append(val)

        flds = ', '.join(map(u'"{0}"'.format, pg_order_item_fields))
        flds = u'bx_order_Номер, {0}'.format(flds)
        pg_order_item_vals.insert(0, doc_id)
        vals = ', '.join(map("'{0}'".format, pg_order_item_vals))
        flds = flds.replace(u'Единица/', '')
        # logging.debug(flds)
        # logging.debug(vals)
        sql_bx_order_item = 'INSERT INTO bx_order_item({0}) VALUES({1});\n'.format(flds.encode('utf-8'), vals)
        logging.debug(sql_bx_order_item)
        sqlf.write(sql_bx_order_item)

        for bx_item_feature in bx_item.findall(u'ЗначенияРеквизитов/ЗначениеРеквизита'):
            bif_name = bx_item_feature.find(u'Наименование').text.encode('utf-8')
            bif_value = bx_item_feature.find(u'Значение').text.encode('utf-8').replace('\r\n','/').replace('\n','/').replace("'", "''")
            insert_bx_order_item_feature = 'INSERT INTO bx_order_item_feature(bx_order_item_id, "bx_order_Номер", fname, fvalue)'
            values_bx_order_item_feature = "VALUES({0}, {1}, '{2}', '{3}');\n".format(bx_item_id, doc_id, bif_name, bif_value)
            sql_bx_order_item_feature = "{0} {1}".format(insert_bx_order_item_feature, values_bx_order_item_feature)
            logging.debug(sql_bx_order_item_feature)
            sqlf.write(sql_bx_order_item_feature)

    sqlf.close()


# logging.debug('bx_orders={0}'.format(bx_orders))


# parse_xml_insert_into_db(conf['site'], el, con, sql_outfile_name)
#logging.info("sql-file created: %s", sql_outfile_name)

"""
cur = con.cursor()
con.commit()
cur.close()
"""


############## Bottom line #########################
