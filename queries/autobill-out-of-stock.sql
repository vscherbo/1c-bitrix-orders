SELECT
goods."Наименование"
FROM
(SELECT 
  items1."Номер"
, items1."Наименование"
-- , items1."Модель"
-- , COALESCE(f.fvalue, items1."Сайт_mod_id") AS gen_mod_id
, m."КодСодержания"
FROM (
SELECT 
  o."Номер"
, i."Наименование"
, split_part("Наименование", ':', 1) AS "Модель"
, substring("Наименование" from ': *?([0-9]+)$') AS "Сайт_mod_id"

, i."Ид"
FROM bx_order_item i
,bx_order o
WHERE i."bx_order_Номер" = o."Номер"
AND o.billcreated=2
AND o."Дата" >= '2016-08-01' -- now() - '1day'::INTERVAL
) items1
LEFT JOIN bx_order_item_feature f ON f.bx_order_item_id = items1."Ид" AND f.fname = 'КодМодификации'
LEFT JOIN devmod.modifications m ON m.mod_id = lpad(COALESCE(f.fvalue, items1."Сайт_mod_id"), 12, '0') ) as goods
WHERE "КодСодержания" IS NULL