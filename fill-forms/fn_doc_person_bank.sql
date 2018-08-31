-- DROP FUNCTION arc_energo.fn_doc_person_bank(integer, boolean);

CREATE OR REPLACE FUNCTION arc_energo.fn_doc_person_bank(bill_no integer, no_vat boolean DEFAULT 't')
  RETURNS character varying AS
$BODY$
#-*- coding:utf-8 -*-
import svglue
import os
import textwrap
import cairosvg
import plpy
from os.path import expanduser

person_bank_query = """
SELECT 
r."Ф_НазваниеКратко" AS pg_firm
, f."Ф_ИНН" AS pg_inn
, r."Ф_КПП" AS pg_kpp
-- , r."Ф_РассчетныйСчет" AS pg_account
-- , r."Ф_Банк" AS pg_bank
, r."Ф_РассчетныйСчет" || E' в ' || r."Ф_Банк" AS pg_account_bank
, "Ф_КоррСчет" AS pg_corresp
, "Ф_БИК" AS pg_bik
, to_char(b."Сумма", '999999999D99') AS pg_amount
, to_char(b."№ счета", '9999-9999') AS pg_order
, e.email AS pg_email
, e.telephone AS pg_phone
, e.mob_phone AS pg_mob_phone
, e."Имя" AS pg_mgr_name
FROM arc_energo."Счета" b
JOIN arc_energo."Фирма" f ON b."фирма" = f."КлючФирмы"
JOIN arc_energo."ФирмаРеквизиты" r ON b."фирма" = r."КодФирмы" AND r."Ф_Активность" = TRUE
JOIN arc_energo."Сотрудники" e ON autobill_mgr(b."Хозяин") = e."Менеджер"
WHERE 
b."№ счета" = 
""" + str(bill_no) + ' ORDER BY r."Ф_ДатаВводаРеквизитов" desc limit 1;'

home = expanduser("~")
if no_vat:
    fname = home + '/fill-forms/person-bank-NO-VAT.svg'
else:
    fname = home + '/fill-forms/person-bank.svg'
# tpl = svglue.load(file=home+'/fill-forms/person-bank-NO-VAT.svg')
tpl = svglue.load(file=fname)

res = plpy.execute(person_bank_query)

pg_firm = res[0]["pg_firm"].decode('UTF-8')
pg_mgr_name = res[0]["pg_mgr_name"].decode('UTF-8')

#pg_account_bank = u''
#pg_account_bank = res[0]["pg_account"] + u' в ' + res[0]["pg_bank"].decode('UTF-8')
#wr = textwrap.TextWrapper(width=50, break_long_words=False)
#a_b_list = wr.wrap(pg_account_bank)

wr = textwrap.TextWrapper(width=50, break_long_words=False)
a_b_list = wr.wrap(res[0]["pg_account_bank"].decode('UTF-8'))

#plpy.log(res[0]["pg_account_bank"])

tpl.set_text('firm1', pg_firm)
tpl.set_text('firm2', pg_firm)
tpl.set_text('inn1', res[0]["pg_inn"])
tpl.set_text('inn2', res[0]["pg_inn"])
tpl.set_text('kpp1', res[0]["pg_kpp"])
tpl.set_text('kpp2', res[0]["pg_kpp"])
tpl.set_text('account_bank1', a_b_list[0])
tpl.set_text('account_bank2', a_b_list[0])
try:
    loc_tail = a_b_list[1]
except IndexError:
    loc_tail = ''

tpl.set_text('bank_tail1', loc_tail)
tpl.set_text('bank_tail2', loc_tail)
# tpl.set_text('bank_tail1', a_b_list[1])
# tpl.set_text('bank_tail2', a_b_list[1])

tpl.set_text('corresp1', res[0]["pg_corresp"])
tpl.set_text('corresp2', res[0]["pg_corresp"])
tpl.set_text('bik1', res[0]["pg_bik"])
tpl.set_text('bik2', res[0]["pg_bik"])
tpl.set_text('order1', res[0]["pg_order"])
tpl.set_text('order2', res[0]["pg_order"])
tpl.set_text('amount1', res[0]["pg_amount"])
tpl.set_text('amount2', res[0]["pg_amount"])

tpl.set_text('phone', res[0]["pg_phone"])
tpl.set_text('email', res[0]["pg_email"])
tpl.set_text('mgr_name', pg_mgr_name)
# tpl.set_text('mob_phone', 'моб.т./WhatsApp/Viber: '.decode('utf-8') + res[0]["pg_mob_phone"])
tpl.set_text('mob_phone', res[0]["pg_mob_phone"])

src = str(tpl)

rv = plpy.execute("SELECT const_value FROM arc_energo.arc_constants WHERE const_name='autobill_out_dir'")
out_dir = rv[0]["const_value"]
#out_dir = '/mnt/nfs/autobill'
fn=out_dir + '/output/' + str(res[0]["pg_order"]).strip() + '-Квитанция.pdf'.decode('utf-8')
with open(fn, 'w') as out:
    cairosvg.svg2pdf(bytestring=src, write_to=out)

return fn
$BODY$
  LANGUAGE plpython2u VOLATILE
  COST 100;
