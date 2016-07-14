#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

import sys
from odf.opendocument import load
from odf.table import Table, TableRow, TableCell
from odf import text
import psycopg2


def odf_dump_nodes(start_node, level=0):
    if start_node.nodeType==3:
        # text node
        if start_node.firstChild is None:
            str_text = 'None'
        else:
            str_text = start_node.firstChild.__unicode__().encode('utf-8', 'ignore')
        print "  "*level, "NODE:", start_node.nodeType, ":(text):", str_text
    else:
        # element node
        attrs= []
        for k in start_node.attributes.keys():
            attrs.append( k[1] + ':' + start_node.attributes[k]  )
        print "  "*level, "NODE:", start_node.nodeType, ":", start_node.qname[1], " ATTR:(", ",".join(attrs), ") ", start_node.firstChild.__unicode__().encode('utf-8', 'ignore')

        for n in start_node.childNodes:
            odf_dump_nodes(n, level+1)
    return



infile = u""
infile += sys.argv[1]
doc = load(infile)

# get 1st table
tab = doc.text.getElementsByType(Table)[0]
#header = tab.getElementsByType(TableRow)[0] # 0 row of data
#row1 = tab.getElementsByType(TableRow)[1] # 1st row of data
rows = tab.getElementsByType(TableRow)
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
c."ПозицияСчета" pg_position
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
    pars[0].addText(str(pg_position))
    pars = cells[1].getElementsByType(text.P)
    pars[0].addText(pg_pos_name.decode('UTF-8'))
    pars = cells[2].getElementsByType(text.P)
    pars[0].addText(pg_mes_unit.decode('UTF-8'))

    """    
    for i in range(len(cells)):
        pars = cells[i].getElementsByType(text.P)
        pars[0].addText(r["pg_mgr_name"].decode('UTF-8')
    """    


doc.save(u"order-55.odt")


