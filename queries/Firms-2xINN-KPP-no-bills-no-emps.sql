SELECT "ИНН", "КПП", "Код", "Предприятие", "ФИО", "ДатаСоздания"
FROM "Предприятия"
JOIN "Сотрудники" e ON ("Создатель" = e."Номер")
WHERE 
  "ИНН" IN (
(SELECT -- COUNT(*), 
     "ИНН"
FROM "Предприятия" f
WHERE 
    "ИНН" IS NOT NULL
    AND "КПП" IS NOT NULL
    AND "ИНН" <> '0'
    AND
    -- NOT EXISTS (SELECT 1 FROM "Работники" e
    --             WHERE e."Код" = f."Код")
    -- AND                
    NOT EXISTS (SELECT 1 FROM "Счета" b
                WHERE b."Код" = f."Код")
GROUP BY "ИНН", "КПП"
HAVING COUNT(*) > 1)
)
ORDER BY "ИНН", "КПП"
