-- Function: fn_bill_fax(integer)

-- DROP FUNCTION arc_energo.fn_bill_fax(integer);

CREATE OR REPLACE FUNCTION arc_energo.fn_bill_fax(bill_no integer)
  RETURNS character varying AS
$BODY$
#-*- coding:utf-8 -*-
from odf.opendocument import load
from odf.table import Table, TableRow, TableCell
from odf import text
from odf.userfield import UserFields
import plpy
import locale
import re
from os.path import expanduser

bill_fax_fields_query = """
SELECT 
r."Ф_НазваниеКратко" pg_firm
, s."ЗаДиректора" pg_signature
, s."ВидНомерДатаДокументаДир" pg_proxy_doc
, r."Ф_НазваниеПолное" pg_firm_full_name
, r."Ф_ПочтовыйАдрес" pg_post_address
, r."Ф_ФактическийАдрес" pg_fact_address
, r."Ф_Телефон" pg_citi_phone
, trim(f."ПрефиксВСчет") pg_prefix
, f."Ф_ИНН" pg_inn
, r."Ф_КПП" pg_kpp
, r."Ф_РассчетныйСчет" pg_account
, r."Ф_Банк" pg_bank
, "Ф_КоррСчет" pg_corresp
, "Ф_БИК" pg_bik
,to_char(b."Сумма", '999 999D99') pg_price
, to_char(b."№ счета", '9999-9999') AS pg_order
, to_char(b."Дата счета", 'DD.MM.YYYY') pg_order_date
, b."ставкаНДС"::VARCHAR pg_vat
, b."Дополнительно" pg_add
, COALESCE (quote_literal(b."ОтгрузкаКем") || '. Оплата доставки при получении', 'Самовывоз') pg_carrier
, e.email pg_email
, e.telephone pg_phone
, e."ФИО" pg_mgr_name
, c."ЮрНазвание" pg_firm_buyer
, c."Факс" pg_fax
, b."фирма" pg_firm_key 
FROM "Счета" b
JOIN "Фирма" f ON b."фирма" = f."КлючФирмы"
JOIN "ФирмаРеквизиты" r ON b."фирма" = r."КодФирмы" AND r."Ф_Активность" = TRUE
JOIN "Сотрудники" e ON autobill_mgr(b."Хозяин") = e."Менеджер"
JOIN "Предприятия" c ON c."Код" = b."Код"
JOIN (SELECT "ДатаСтартаПодписи", "КодОтчета", "НомерСотрудника", "КлючФирмы", "ЗаДиректора", "ВидНомерДатаДокументаДир" 
    FROM "Подписи" 
    WHERE "КодОтчета" = 'СчетФакс' 
          AND "НомерСотрудника" = 0 
          AND "КлючФирмы" = (SELECT "фирма" FROM "Счета" WHERE "№ счета" = """  + str(bill_no) + """)
    ORDER BY "ДатаСтартаПодписи" DESC LIMIT 1 ) AS s ON s."КлючФирмы" = b."фирма"
WHERE 
b."№ счета" = 
""" + str(bill_no) + ' ORDER BY r."Ф_ДатаВводаРеквизитов" desc limit 1;'

recs = plpy.execute(bill_fax_fields_query)
if 0 == recs.nrows():
    return 'Not found'

upd_dict = {}
for (k, v) in recs[0].items():
    if v is None:
        upd_dict[k] = ''
    else:
        # plpy.log('[' + v + ']')
        upd_dict[k] = v.decode('utf-8')

locale.setlocale(locale.LC_ALL, 'ru_RU.UTF-8')
re_director = re.compile(u'.*иректор', flags=re.IGNORECASE)
plpy.notice("Director=" + upd_dict["pg_proxy_doc"].encode('utf-8')  )
if re_director.search(upd_dict["pg_proxy_doc"].encode('utf-8')):
    upd_dict["pg_as_director"] = upd_dict["pg_proxy_doc"]
    upd_dict["pg_proxy_doc"] = ""
    plpy.notice("MATCH Director=" + upd_dict["pg_as_director"].encode('utf-8')  )

order_items_query = """
SELECT
c."ПозицияСчета"::VARCHAR pg_position
, "Наименование" pg_pos_name
,"Ед Изм" pg_mes_unit
,to_char("Кол-во", '999 999D') pg_qnt
,to_char("ЦенаНДС", '999 999D99') pg_price
,to_char(round("Кол-во"*"ЦенаНДС", 2), '999 999D99') pg_sum
,COALESCE("Срок2", E'') pg_period
,round("Кол-во"*"ЦенаНДС", 2) pg_sum_dec
,round("Кол-во"*"Цена", 2) pg_sum_novat_dec
FROM "Содержание счета" c
WHERE
c."№ счета" = 
""" + str(bill_no) + """ ORDER BY c."ПозицияСчета";"""

fld_items = {0: "pg_position", 1: "pg_pos_name", 2: "pg_mes_unit", 3: "pg_qnt", 4: "pg_price", 5: "pg_sum", 6: "pg_period"}

plpy.notice("pg_firm_key=" + upd_dict["pg_firm_key"].encode('utf-8'))
home = expanduser("~")

firm_code = upd_dict["pg_firm_key"]
plpy.notice("firm_code=_{0}_".format(firm_code.encode('utf-8')) )

#doc_template = home + '/fill-forms/bill_fax_template-'+ upd_dict["pg_firm_key"]  +'.odt'
#doc_template = home + u'/fill-forms/bill_fax_template-'+ firm_code + u'.odt'
# plpy.notice("doc_template=_{0}_".format(doc_template.encode('utf-8')) )
# 
#doc = load(home + u'/fill-forms/bill_fax_template-'+ upd_dict["pg_firm_key"].decode('utf-8')  +u'.odt')
#
doc = load(home + '/fill-forms/bill_fax_template-'+ firm_code  +'.odt')

rv = plpy.execute("SELECT const_value FROM arc_energo.arc_constants WHERE const_name='autobill_out_dir'")
out_dir = rv[0]["const_value"]
outfile=out_dir + '/db/'+ str(bill_no)[:4] + '-' + str(bill_no)[4:] + '-Счет-факс.odt'.decode('utf-8')


# get 1st table
tab = doc.text.getElementsByType(Table)[4]
rows = tab.getElementsByType(TableRow)

locale.setlocale(locale.LC_ALL, '')
recs = plpy.execute(order_items_query)
#plpy.log("items nrows="+str(recs.nrows()))
#plpy.log("items recs[0]="+str(recs[0]))
sum_total = 0
sum_novat = 0
for r in range(recs.nrows()):
    sum_total += recs[r]["pg_sum_dec"]
    sum_novat += recs[r]["pg_sum_novat_dec"]
    cells = rows[r+1].getElementsByType(TableCell)
    cells_header = rows[0].getElementsByType(TableCell)
    #plpy.log("r=" + str(r) + ", len(cells)=" + str(len(cells)))
    for cind in range(len(cells)):
        pars = cells[cind].getElementsByType(text.P)
        pars_header = cells_header[cind].getElementsByType(text.P)
        #if 6 == cind:  # DEBUG period
        #    plpy.notice("cind=" + str(cind) + ", len(pars)=" + str(len(pars)))
        #    plpy.notice("cind=" + str(cind) + ", pars_header=" + pars_header[0].firstChild.__unicode__().encode('utf-8', 'ignore'))
        #    plpy.notice("cind=" + str(cind) + ", val=" + recs[r][fld_items[cind]] )
        cell_txt = recs[r][fld_items[cind]].decode('utf-8')
        cell_list = cell_txt.split(';')
        if len(cell_list) > 0:
            pars[0].addText(cell_list[-1])
            for c_i in range(len(cell_list)-1):
                p_i = text.P()
                p_i.setAttribute("stylename",pars[0].getAttribute("stylename"))
                p_i.addText(cell_list[c_i]+'\n')
                cells[cind].insertBefore(p_i, pars[0])
        else:
            pars[0].addText(cell_txt)
        # it works: pars[0].addText(recs[r][fld_items[cind]].decode('utf-8'))

rec_total_in_words = plpy.execute("SELECT propis(" + str(sum_total) +");"  )
sum_total_in_words = rec_total_in_words[0]["propis"].decode('utf-8')
sum_words = sum_total_in_words.split(' ')
sum_total_in_words = sum_words[0].capitalize() + ' ' + ' '.join(sum_words[1:])
 
for row in range(len(recs)+1, len(rows)):
    tab.removeChild(rows[row])

# total positions in words
rec_total_pos_in_words = plpy.execute("SELECT propis(" + str(recs.nrows()) +");"  )
re_rubl = re.compile(u'рубл.*$', flags=re.IGNORECASE)
total_pos_in_words = re_rubl.sub('', rec_total_pos_in_words[0]["propis"]).decode('utf-8')
total_words = total_pos_in_words.split(' ')
total_pos_in_words = total_words[0].capitalize() + ' ' + ' '.join(total_words[1:])

doc.save(outfile)

obj = UserFields(outfile, outfile)
obj.update(upd_dict)
locale.setlocale(locale.LC_ALL, 'ru_RU.UTF-8')
obj.update({"pg_total": locale.currency(sum_total, False, True).replace('.', ',').decode('utf-8')})
#obj.update({"pg_vat": locale.currency(sum_total - sum_novat, False, True).replace('.', ',').decode('utf-8')})
obj.update({"pg_vat": locale.currency(round(sum_total*18/118,2), False, True).replace('.', ',').decode('utf-8')})
locale.setlocale(locale.LC_ALL, '')
obj.update({"pg_sum_in_words": sum_total_in_words})
# obj.update({"pg_total_pos": recs.nrows()+1})
obj.update({"pg_total_pos": total_pos_in_words})

odt2pdf_query = "SELECT odt2pdf('" + outfile + "');"
odt2pdf_query = odt2pdf_query.encode('utf8')
res = plpy.execute(odt2pdf_query)
#return outfile
return res[0]["odt2pdf"]
$BODY$
  LANGUAGE plpython2u VOLATILE
  COST 100;
ALTER FUNCTION arc_energo.fn_bill_fax(integer)
  OWNER TO postgres;
