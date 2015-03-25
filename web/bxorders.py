
# -*- coding: utf-8 -

import psycopg2
import argparse
# from bottle import route, run, template, debug, request, static_file, url
# from bottle import Bottle, run, debug, route, static_file, view, template, post, request, url
from bottle import Bottle, run, debug, route, static_file, view, template, post, request, url, SimpleTemplate

SimpleTemplate.defaults["get_url"] = url

parser = argparse.ArgumentParser(description='Pg listener for .')
parser.add_argument('--host', type=str, help='PG host')
parser.add_argument('--db', type=str, help='database name')
parser.add_argument('--user', type=str, help='db user')
args = parser.parse_args()

DSN = 'dbname=%s host=%s user=%s' % (args.db, args.host, args.user)
conn = psycopg2.connect(DSN)
conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
conn.set_client_encoding('UTF-8')

@route('/static/<filename>', name='static')
def server_static(filename):
  return static_file(filename, root='static')

@route('/bxorders')
def bxorders_list():
    curs = conn.cursor()
    # curs.execute("SELECT * FROM bx_order WHERE dt_insert > CURRENT_DATE ORDER BY id;")
    curs.execute('SELECT id, dt_insert, bx_buyer_id, "Номер", "Сумма", "Валюта", billcreated FROM bx_order WHERE dt_insert > CURRENT_DATE ORDER BY id;')
    result = curs.fetchall()
    curs.close()
    output = template('master_detail', masters=result, headers=(u"id", u"Импортирован", u"Ид покупателя", u"Ид заказа", u"Сумма", u"Валюта", u"Статус"))
    return output

@route('/bx_order_items', method='GET')
def bxorderitems():
    master_id = request.GET.get('master_id', '').strip()
    if '-1' == master_id:
        result = [u'Выберите счёт']
    else:
        curs = conn.cursor()
        curs.execute('SELECT "Номер" FROM bx_order WHERE id=' + master_id + ';')
        bx_order_num = str(curs.fetchone()[0])
        curs.execute('SELECT * FROM bx_order_item WHERE bx_order_Номер=' + bx_order_num + ' ORDER BY id;')
        result = curs.fetchall()

    output = template('make_table', rows=result)
    return(output)

@route('/bx_order_features', method='GET')
def bxorderfeatures():
    master_id = request.GET.get('master_id', '').strip()
    curs = conn.cursor()
    curs.execute('SELECT "Номер" FROM bx_order WHERE id=' + master_id + ';')
    bx_order_num = str(curs.fetchone()[0])
    curs.execute('SELECT * FROM bx_order_feature WHERE bx_order_Номер=' + bx_order_num + ' ORDER BY id;')
    result = curs.fetchall()
    output = template('make_table', rows=result)
    return(output)
    
debug(True)
# run()
run(reloader=True)
conn.close()

