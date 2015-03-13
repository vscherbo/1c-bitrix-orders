SELECT  p.email as "email с сайта"
      , p.name as "Имя с сайта"
      , e."ЕАдрес" AS "email в базе"
      , e."ФИО" AS "Имя в базе"
      , CASE e."Код" WHEN 223719 THEN 'Person'
              ELSE 'Firm'
       END AS "ТипРаботника"
FROM "Работники" e, vwPersonalBuyer p
WHERE p.email = e."ЕАдрес"
AND UPPER(p.name) != UPPER(e."ФИО")
ORDER BY e."Код"