SELECT dbls.cnt, f1."ИНН", f1."КПП", "Код", "Предприятие", "ДатаСоздания"
   ,"ФИО", "Создатель"
FROM "Предприятия" f1
LEFT JOIN "Сотрудники" e ON ("Создатель" = e."Номер")
JOIN (SELECT COUNT(f.*) AS cnt, 
     f."ИНН", f."КПП"
FROM "Предприятия" f
WHERE 
    "ИНН" IS NOT NULL
    AND "КПП" IS NOT NULL
    AND "ИНН" <> '0'
    AND
    -- NOT EXISTS (SELECT 1 FROM "Работники" e
    --              WHERE e."Код" = f."Код")
    -- AND                
    NOT EXISTS (SELECT 1 FROM "Счета" b
                 WHERE b."Код" = f."Код")
GROUP BY "ИНН", "КПП"
HAVING COUNT(*) > 1) as dbls
ON (f1."ИНН"=dbls."ИНН" AND f1."КПП"=dbls."КПП")
ORDER BY "ИНН", "КПП"
