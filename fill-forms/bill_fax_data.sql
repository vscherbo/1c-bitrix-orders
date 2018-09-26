-- DROP FUNCTION arc_energo.bill_fax_data(integer);

CREATE OR REPLACE FUNCTION arc_energo.bill_fax_data(bill_no integer)
  RETURNS record AS
$BODY$
SELECT 
r."Ф_НазваниеКратко" pg_firm
, s."ЗаДиректора" pg_signature
, s."ВидНомерДатаДокументаДир" pg_proxy_doc
, r."Ф_НазваниеКратко" pg_firm_full_name
, coalesce(r."Ф_ПочтовыйАдрес", '') pg_post_address
, r."Ф_ФактическийАдрес" pg_fact_address
, r."Ф_Телефон" pg_city_phone
, trim(f."ПрефиксВСчет") pg_prefix
, f."Ф_ИНН" pg_inn
, r."Ф_КПП" pg_kpp
, r."Ф_РассчетныйСчет" pg_account
, format('%s %s', r."Ф_Банк",  COALESCE(r."Ф_ГородБанка", ''))  pg_bank
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
, CASE WHEN e.mob_phone IS NULL THEN '' ELSE 'моб.т./WhatsApp/Viber: ' END pg_mob_label 
, COALESCE(e.mob_phone, '') pg_mob_phone
, '(812) 327-32-40'::text pg_firm_phone
, e."ФИО" pg_mgr_name
, c."ЮрНазвание" pg_firm_buyer
, c."Факс" pg_fax
, b."фирма" pg_firm_key
, r."Ф_ЮрАдрес" pg_legal_address
, c."ЮрАдрес" pg_buyer_address
, c."ИНН" pg_buyer_inn
, c."КПП" pg_buyer_kpp
FROM "Счета" b
JOIN "Фирма" f ON b."фирма" = f."КлючФирмы"
JOIN "ФирмаРеквизиты" r ON b."фирма" = r."КодФирмы" AND r."Ф_Активность" = TRUE
JOIN "Сотрудники" e ON autobill_mgr(b."Хозяин") = e."Менеджер"
JOIN "Предприятия" c ON c."Код" = b."Код"
JOIN (SELECT "ДатаСтартаПодписи", "КодОтчета", "НомерСотрудника", "КлючФирмы", "ЗаДиректора", "ВидНомерДатаДокументаДир" 
    FROM "Подписи" 
    WHERE "КодОтчета" = 'СчетФакс' 
          AND "НомерСотрудника" = 0 
          AND "КлючФирмы" = (SELECT "фирма" FROM "Счета" WHERE "№ счета" = bill_no )
    ORDER BY "ДатаСтартаПодписи" DESC LIMIT 1 ) AS s ON s."КлючФирмы" = b."фирма"
WHERE 
b."№ счета" = bill_no ORDER BY r."Ф_ДатаВводаРеквизитов" desc limit 1;

/**
recs = plpy.execute(bill_fax_fields_query)
if 0 == recs.nrows():
    return 'Not found'

loc_vat = int(recs[0]["pg_vat"])
if 0 == loc_vat:
    loc_vat_str = 'НДС не облагается'
else:
    loc_vat_str = 'В том числе НДС -{0}%'.format(loc_vat)
**/
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION arc_energo.fn_bill_fax(integer)
  OWNER TO postgres;
