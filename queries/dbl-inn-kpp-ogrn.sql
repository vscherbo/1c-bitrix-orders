SELECT MAX(b."Дата счета"), e."Код", "Предприятие", "ИНН", "КПП", "ОГРН"
FROM "Предприятия" e
-- WHERE e."ИНН" = '4716016979' -- '6315376946','7825121288','7841312071'
-- WHERE e."ИНН" = '6315376946'
-- WHERE e."ИНН" = '7825121288'
-- 
JOIN "Счета" b ON b."Код" = e."Код" 
WHERE e."ИНН" = '7841312071' -- ТГК-1
GROUP BY e."Код" 