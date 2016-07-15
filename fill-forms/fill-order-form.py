#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

import sys
from odf.opendocument import load
from odf.table import Table, TableRow, TableCell
from odf import text
import psycopg2
from odf.userfield import UserFields
from odf_dump import odf_dump_nodes


infile = u""
infile += sys.argv[1]
doc = load(infile)
outfile = u"output/order-55.odt"

# get 1st table
tab = doc.text.getElementsByType(Table)[1]
#header = tab.getElementsByType(TableRow)[0] # 0 row of data
#row1 = tab.getElementsByType(TableRow)[1] # 1st row of data
rows = tab.getElementsByType(TableRow)
empty_row = rows[-1]
"""
pars = header.getElementsByType(text.P)
for p in pars:
    print p.__unicode__().encode('UTF-8')
"""
#odf_dump_nodes(pars[0])


con = psycopg2.connect("host='vm-pg.arc.world' dbname='arc_energo' user='arc_energo'") # password='XXXX' - .pgpass
cur = con.cursor()
order_items_query = """
SELECT
c."ПозицияСчета"::VARCHAR pg_position
, "Наименование" pg_pos_name
,"Ед Изм" pg_mes_unit
,"Кол-во" pg_qnt
, "ЦенаНДС" pg_price
, round("Кол-во"*"ЦенаНДС", 2) pg_sum
, "Срок2" pg_period
FROM "Содержание счета" c
WHERE
c."№ счета" = 55202951
ORDER BY pg_position
"""


cur.execute(order_items_query)
recs = cur.fetchall()
#pg_pos_name = u''
#pg_mes_unit = u''
pg_period = u''

# dirty patch: assume that len(rows) = len(recs)
for r in range(len(recs)):
    (pg_position, pg_pos_name, pg_mes_unit, pg_qnt, pg_price, pg_sum, pg_period) = recs[r]

    cells = rows[r+1].getElementsByType(TableCell)

    pars = cells[0].getElementsByType(text.P)
    pars[0].addText(pg_position)
    pars = cells[1].getElementsByType(text.P)
    pars[0].addText(pg_pos_name.decode('UTF-8'))
    pars = cells[2].getElementsByType(text.P)
    pars[0].addText(pg_mes_unit.decode('UTF-8'))

for row in range(len(recs)+1, len(rows)):
    tab.removeChild(rows[row])

doc.save(outfile)

""" Search and Replace example
textdoc = load("myfile.odt")
texts = textdoc.getElementsByType(text.P)
s = len(texts)
for i in range(s):
    old_text = teletype.extractText(texts[i])
    new_text = old_text.replace('something','something else')
    new_S = text.P()
    new_S.setAttribute("stylename",texts[i].getAttribute("stylename"))
    new_S.addText(new_text)
    texts[i].parentNode.insertBefore(new_S,texts[i])
    texts[i].parentNode.removeChild(texts[i])
textdoc.save('myfile.odt')
"""

order_fields_query = """
SELECT
r."Ф_НазваниеКратко" pg_firm
, f."Ф_ИНН" pg_inn
, r."Ф_КПП" pg_kpp
, r."Ф_РассчетныйСчет" || E' в ' || r."Ф_Банк" AS pg_account_bank
, "Ф_КоррСчет" pg_corresp
, "Ф_БИК" pg_bik
, to_char(b."Сумма", '999999999D99') AS pg_amount
, to_char(b."№ счета", '9999-9999') AS pg_order
, to_char(b."Дата счета", 'DD.MM.YYYY') pg_order_date
, e.email pg_email
, e.telephone pg_phone
, e."Имя" pg_mgr_name
FROM "Счета" b
JOIN "Фирма" f ON b."фирма" = f."КлючФирмы"
JOIN "ФирмаРеквизиты" r ON b."фирма" = r."КодФирмы" AND r."Ф_Активность" = TRUE
JOIN "Сотрудники" e ON b."Хозяин" = e."Менеджер"
WHERE
b."№ счета" = 55202951
"""

cur.execute(order_fields_query)
recs = cur.fetchall()
colnames = [desc[0] for desc in cur.description]
vals = []
print "colnames=", colnames
for t in recs[0]:
    #print t.decode('utf-8')
    vals.append(t.decode('utf-8'))



obj = UserFields(outfile, outfile)

print "obj.list_fields=", obj.list_fields()
"""
upd_dict1 = {}
upd_dict1['inn'] = recs[0]["pg_inn"]
upd_dict1['kpp'] = recs[0]["pg_kpp"]

print "upd_dict1=", upd_dict1
"""

upd_dict = {}
upd_dict = dict(zip(colnames, vals))
print "upd_dict=", upd_dict
print "type(upd_dict)=", type(upd_dict)


inst = {'inn': '7802731174', 'kpp': '780201001'}
print "inst=", inst
print "type(inst)=", type(inst)

#obj.update({'inn': '7802731174', 'kpp': '780201001'})
obj.update(upd_dict)



