 select COUNT(*) AS Cnt, "ИНН", "КПП"
 FROM "Предприятия"
 GROUP BY "ИНН", "КПП"
 HAVING COUNT(*) > 1
 ORDER BY 1 DESC
