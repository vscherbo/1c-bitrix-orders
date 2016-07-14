SELECT 
c."ПозицияСчета" pg_position
, "Наименование" pg_pos_name
,"Ед Изм" pg_mes_unit
,"Кол-во" pg_qnt
, "ЦенаНДС" pg_price
, round("Кол-во"*"ЦенаНДС", 2) pg_sum
, "Срок2"
FROM "Содержание счета" c
-- JOIN "Фирма" f ON b."фирма" = f."КлючФирмы"
WHERE 
c."№ счета" = 55202951
ORDER BY pg_position
