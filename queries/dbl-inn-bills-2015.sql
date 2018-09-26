WITH buyers2015 AS (SELECT e.* FROM "Предприятия" e
WHERE 
    exists (SELECT 1 FROM "Счета" b
    WHERE b."Код" = e."Код" AND b."Дата счета" > '2015-01-01' AND b."Статус" >=7 -- b."Оплата1" > 0
    AND EXISTS (SELECT 1 FROM "Содержание счета" bc WHERE b."№ счета" = bc."№ счета")
    ) 
and e."ИНН" is not NULL and e."ИНН" <> '0'),
dbl_inn AS (SELECT "ИНН" FROM buyers2015
group by "ИНН" having count(*) > 1)
SELECT b2."ИНН", b2."КПП", b2."ОКПО",
"ОГРН", b2."Предприятие",
b2."ЮрНазвание", b2."Грузополучатель" 
FROM buyers2015 b2
WHERE b2."ИНН" IN (SELECT * FROM dbl_inn)
ORDER BY "ИНН"
