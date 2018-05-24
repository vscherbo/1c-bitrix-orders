#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

import os
import argparse
import codecs
import time
import collections

import psycopg2.extensions
import logging
from xml.etree import ElementTree

from bx_orders_download import get_orders

# ---------------- parse_xml -----------------------------------
def parse_xml(xml_lines):
    sql_orders = {}
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

    el = ElementTree.fromstring(xml_lines.encode('utf-8'))
    for bx_order in el.findall(u'Документ'):
        sql_lines = []
        logging.debug(bx_order.tag.encode('utf-8'))  # 'Документ'
        bx_order_id = bx_order.find(u'Ид').text
        cur.execute('SELECT 1 FROM bx_order WHERE "Номер" = {0};'.format(bx_order_id))
        # if FOUND do not write sql into file, go to the next
        if cur.fetchone() is not None:
            logging.info("bx_order_id={0} is found in DB, skip".format(bx_order_id))
            continue

        bx_counterpart = bx_order.find(u'Контрагенты/Контрагент')
        bx_buyer = bx_counterpart.find(u'Ид').text  # .encode('utf-8')
        buyer = bx_buyer.split("#")  # 0-bx_buyer_id, 1-bx_buyer_login, 2-bx_buyer_name
        bx_buyer_id = buyer[0]
        bx_buyer_login = buyer[1].strip(' ')
        bx_buyer_name = buyer[2].strip(' ')
        flagFastOrder = 'OrderUser' in bx_buyer_login
        el_inn = bx_counterpart.find(u'ИНН')
        el_kpp = bx_counterpart.find(u'КПП')
        if el_inn is None:
            bx_buyer_inn = ''
        else:
            bx_buyer_inn = bx_counterpart.find(u'ИНН').text
        if el_kpp is None:
            bx_buyer_kpp = ''
        else:
            bx_buyer_kpp = bx_counterpart.find(u'КПП').text
        loc_legal_entity = bx_buyer_inn is not None
        logging.debug("bx_buyer_id={0}, юр.лицо={1}".format(bx_buyer_id, loc_legal_entity))
        # TODO search buyer_id in DB
        # insert OR update bx_buyer
        buyer_sql = u"""INSERT INTO bx_buyer(bx_buyer_id, bx_logname, bx_name, "ИНН", "КПП") 
                    VALUES ({0}, '{1}', '{2}', '{3}', '{4}')
                    ON CONFLICT (bx_buyer_id)
                    DO UPDATE SET 
                    bx_name = EXCLUDED.bx_name
                    , "ИНН" = EXCLUDED."ИНН"
                    , "КПП" = EXCLUDED."КПП"
                    ;\n""".format(bx_buyer_id, bx_buyer_login, bx_buyer_name, bx_buyer_inn, bx_buyer_kpp)
        cur.execute(buyer_sql)

        pg_order_vals = []

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
        # sqlf.write(sql_bx_order)
        sql_lines.append(sql_bx_order)

        do_sites = False
        for bx_order_feature in bx_order.findall(u'ЗначенияРеквизитов/ЗначениеРеквизита'):
            bof_name = bx_order_feature.find(u'Наименование').text.encode('utf-8')
            val = bx_order_feature.find(u'Значение')
            if val.text is None:
                bof_value = None
            else:
                bof_value = val.text.encode('utf-8').replace('\r\n', '/').replace('\n', '/').replace("'", "''")
            if ('Сайт' == bof_name and 'ar' == bof_value):
                do_sites = True
            insert_bx_order_feature = 'INSERT INTO bx_order_feature("bx_order_Номер", fname, fvalue)'
            values_bx_order_feature = "VALUES({0}, '{1}', '{2}');\n".format(bx_order_id, bof_name, bof_value)
            sql_bx_order_feature = "{0} {1}".format(insert_bx_order_feature, values_bx_order_feature)
            logging.debug(sql_bx_order_feature)
            # sqlf.write(sql_bx_order_feature)
            sql_lines.append(sql_bx_order_feature)

        if do_sites:
            for bx_item in bx_order.findall(u'Товары/Товар'):
                pg_order_item_vals = []
                bx_item_id = bx_item.find(u'Ид').text
                logging.debug('bx_item_id={0}'.format(bx_item_id))
                for f in pg_order_item_fields:
                    val = bx_item.find(f).text.encode('utf-8')
                    pg_order_item_vals.append(val)

                flds = ', '.join(map(u'"{0}"'.format, pg_order_item_fields))
                flds = u'bx_order_Номер, {0}'.format(flds)
                pg_order_item_vals.insert(0, bx_order_id)
                vals = ', '.join(map("'{0}'".format, pg_order_item_vals))
                flds = flds.replace(u'Единица/', '')
                # logging.debug(flds)
                # logging.debug(vals)
                sql_bx_order_item = 'INSERT INTO bx_order_item({0}) VALUES({1});\n'.format(flds.encode('utf-8'), vals)
                logging.debug(sql_bx_order_item)
                # sqlf.write(sql_bx_order_item)
                sql_lines.append(sql_bx_order_item)

                for bx_item_feature in bx_item.findall(u'ЗначенияРеквизитов/ЗначениеРеквизита'):
                    bif_name = bx_item_feature.find(u'Наименование').text.encode('utf-8')
                    val = bx_item_feature.find(u'Значение')
                    if val.text is None:
                        bif_value = None
                    else:
                        bif_value = val.text.encode('utf-8').replace('\r\n', '/').replace('\n', '/').replace("'", "''").replace("&nbsp;", " ")
                    insert_bx_order_item_feature = 'INSERT INTO bx_order_item_feature(bx_order_item_id, "bx_order_Номер", fname, fvalue)'
                    values_bx_order_item_feature = "VALUES({0}, {1}, '{2}', NULLIF('{3}', 'None'));\n".format(bx_item_id, bx_order_id,
                                                                                              bif_name, bif_value)
                    sql_bx_order_item_feature = "{0} {1}".format(insert_bx_order_item_feature, values_bx_order_item_feature)
                    logging.debug(sql_bx_order_item_feature)
                    # sqlf.write(sql_bx_order_item_feature)
                    sql_lines.append(sql_bx_order_item_feature)

        sql_orders[bx_order_id] = sql_lines

    ret_sql_orders = collections.OrderedDict(sorted(sql_orders.items(), key=lambda t: t[0]))
    return ret_sql_orders



# ---------------- Main -----------------------------------

(prg_name, prg_ext) = os.path.splitext(os.path.basename(__file__))
conf_file = prg_name + ".conf"
log_file = prg_name + ".log"

parser = argparse.ArgumentParser(description='Pg listener for .')
parser.add_argument('--conf', type=str, default=conf_file, help='conf file')
parser.add_argument('--xml_file', type=str, help='bx_orders xml file')
parser.add_argument('--log_level', type=str, default="DEBUG", help='log level')
parser.add_argument('--run_sql', type=bool, default=False, help='run prepared sql')
parser.add_argument('--create_bill', type=bool, default=False, help='run create_inet_bill')
log_dir = ''
args = parser.parse_args()

numeric_level = getattr(logging, args.log_level, None)
if not isinstance(numeric_level, int):
    raise ValueError('Invalid log level: %s' % numeric_level)

log_format = '[%(filename)-20s:%(lineno)4s - %(funcName)20s()] %(levelname)-7s | %(asctime)-15s | %(message)s'

logging.basicConfig(filename=log_file, filemode='a', format=log_format, level=numeric_level)


conf = {}
# execfile(prg_name+".conf", conf)
execfile(args.conf, conf)
site = conf['site']

# password='XXXX' in .pgpass
pg_con = psycopg2.connect("host='" + conf["pg_srv"] + "' dbname='arc_energo' user='arc_energo'")
# TODO check return code
cur = pg_con.cursor()

if args.xml_file is None:
    site_user = conf['site_user']
    site_pword = conf['site_pword']
    version = conf['version']
    timeout = conf['timeout']

    xml_lines = get_orders(site, site_user, site_pword, version, timeout)
else:
    xmlf = codecs.open(args.xml_file, 'r', 'utf-8')
    xml_lines = xmlf.read()
    xmlf.close()
    logging.info("read xml file: %s", args.xml_file)

if xml_lines is not None:
    for bx_order_id, sql_order in parse_xml(xml_lines).iteritems():
        logging.info('write to sql-file bx_order={0}'.format(bx_order_id))
        sql_outfile_name = "02-sql/order-{0}-{1}-{2}.sql".format(site, bx_order_id,
                                                                 time.strftime("%Y-%m-%d_%H-%M-%S"))
        sqlf = open(sql_outfile_name, 'w')
        for sql_line in sql_order:
            sqlf.write("%s\n" % sql_line)
        sqlf.close()

        if args.run_sql:
            sql_lines = "".join(sql_order)
            cur.execute(sql_lines)
            logging.info('INSERT completed')
            pg_con.commit()
            if args.create_bill:
                run_bxorder2bill = u'SELECT bxorder2bill({0});'.format(bx_order_id)
                cur.execute(run_bxorder2bill)
                logging.info('bxorder2bill completed')
                pg_con.commit()

pg_con.commit()
cur.close()

# ------------ Bottom line -------------------------
