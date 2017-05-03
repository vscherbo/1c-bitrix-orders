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
, b."Сумма" 
, b."№ счета"::VARCHAR pg_order
, b."Дата счета" pg_order_date
, b."ставкаНДС":: VARCHAR pg_vat
, b."Дополнительно" pg_add
, COALESCE (quote_literal(b."ОтгрузкаКем") || '. Оплата доставки при получении', 'Самовывоз') pg_carrier
, e.email pg_email
, e.telephone pg_phone
, e."ФИО" pg_mgr_name
, c."ЮрНазвание" pg_firm_buyer
, c."Факс" pg_fax
FROM "Счета" b
JOIN "Фирма" f ON b."фирма" = f."КлючФирмы"
JOIN "ФирмаРеквизиты" r ON b."фирма" = r."КодФирмы" AND r."Ф_Активность" = TRUE
JOIN "Сотрудники" e ON autobill_mgr(b."Хозяин") = e."Менеджер"
JOIN "Предприятия" c ON c."Код" = b."Код"
JOIN (SELECT "ДатаСтартаПодписи", "КодОтчета", "НомерСотрудника", "КлючФирмы", "ЗаДиректора", "ВидНомерДатаДокументаДир" 
FROM "Подписи" 
WHERE "КодОтчета" = 'СчетФакс' AND "НомерСотрудника" = 0 AND "КлючФирмы" = (SELECT "фирма" FROM "Счета" WHERE "№ счета" = 38203072)
ORDER BY "ДатаСтартаПодписи" DESC LIMIT 1 ) AS s ON s."КлючФирмы" = b."фирма"
WHERE 
b."№ счета" = 38203072
-- 38203296
-- 38203072
-- 55201723
--12201233
