-- SELECT "№ счета", "Дата счета", "ИнтернетЗаказ" FROM "Счета"
UPDATE "Счета" SET "Дилерский" = 't'
WHERE "Код" IN (SELECT "Код" FROM "vwДилеры")
AND NOT "Дилерский"
AND "ИнтернетЗаказ" IN (SELECT "Ид" FROM bx_order WHERE billcreated=1)
AND "Дата счета" > '2016-06-01'
-- ORDER BY "Дата счета"