#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

import svglue
import os
import psycopg2
import psycopg2.extensions


prog_name = os.path.basename(__file__)[:-3]


conf = {}
execfile(prog_name + ".conf", conf)

con = psycopg2.connect("host='" + conf["pg_srv"] + "' dbname='arc_energo' user='arc_energo'") # password='XXXX' - .pgpass
cur = con.cursor()
person_bank_query = """
SELECT 
r."Ф_НазваниеКратко"
, f."Ф_ИНН"
, r."Ф_КПП"
, r."Ф_РассчетныйСчет"
, r."Ф_Банк"
, "Ф_КоррСчет"
, "Ф_БИК"
, to_char(b."Сумма", '999999999D99')
, to_char(b."№ счета", '9999-9999')
FROM "Счета" b
JOIN "Фирма" f ON b."фирма" = f."КлючФирмы"
JOIN "ФирмаРеквизиты" r ON b."фирма" = r."КодФирмы" AND r."Ф_Активность" = TRUE
WHERE 
b."№ счета" = 12201229;
"""

cur.execute(person_bank_query)
rec = cur.fetchall()
#print rec[0]
pg_firm = u''
pg_account = u''
pg_bank = u''
(pg_firm, pg_inn, pg_kpp, pg_account, pg_bank, pg_corresp, pg_bik, pg_amount, pg_order) = rec[0]

"""
pg_inn = '7802731174'
pg_kpp = '780201001'
pg_firm = u'ООО "АРКОМ"'
pg_bank = u'СТ-ПЕТЕРБУРГСКИЙ ФИЛИАЛ ПАО "ПРОМСВЯЗЬБАНК"'
pg_account = '40702810506000011363'
pg_corresp = '30101810000000000920'
pg_bik = '044030920'
pg_order = '1220-1229' 
pg_amount = '2870,00'
"""

pg_account_bank = u''
pg_account_bank = pg_account + u' в ' + pg_bank.decode('UTF-8')
pg_firm = pg_firm.decode('UTF-8')

# load the template from a file
tpl = svglue.load(file='person-bank.svg')

# replace some text
#tpl.set_text('bill_amount1', u'2870,00')
#tpl.set_text('bill_amount2', u'2870,00')
#tpl.set_text('inn_kpp1', u'ИНН: 7802731174 КПП: 780201001')
#tpl.set_text('inn_kpp2', u'ИНН: 7802731174 КПП: 780201001')

import textwrap

wr = textwrap.TextWrapper(width=50, break_long_words=False)
a_b_list = wr.wrap(pg_account_bank)


tpl.set_text('firm1', pg_firm)
tpl.set_text('firm2', pg_firm)
tpl.set_text('inn1', pg_inn)
tpl.set_text('inn2', pg_inn)
tpl.set_text('kpp1', pg_kpp) 
tpl.set_text('kpp2', pg_kpp)
tpl.set_text('account_bank1', a_b_list[0])
tpl.set_text('account_bank2', a_b_list[0])
tpl.set_text('bank_tail1', a_b_list[1])
tpl.set_text('bank_tail2', a_b_list[1])
tpl.set_text('corresp1', pg_corresp)
tpl.set_text('corresp2', pg_corresp)
tpl.set_text('bik1', pg_bik) 
tpl.set_text('bik2', pg_bik) 
tpl.set_text('order1', pg_order) 
tpl.set_text('order2', pg_order) 
tpl.set_text('amount1', pg_amount) 
tpl.set_text('amount2', pg_amount) 

# replace the pink box with 'hello.png'. if you do not specify the mimetype,
# the image will get linked instead of embedded
#tpl.set_image('pink-box', file='hello.png', mimetype='image/png')

# svgs are merged into the svg document (i.e. always embedded)
#tpl.set_svg('yellow-box', file='Ghostscript_Tiger.svg')

# to render the template, cast it to a string. this also allows passing it
# as a parameter to set_svg() of another template
src = str(tpl)

# write out the result as an SVG image and render it to pdf using cairosvg
import cairosvg
with open('output.pdf', 'w') as out, open('output.svg', 'w') as svgout:
    svgout.write(src)
    cairosvg.svg2pdf(bytestring=src, write_to=out)
