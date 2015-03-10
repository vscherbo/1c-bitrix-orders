CREATE VIEW vwbxOrderSyncItems AS
SELECT Номер
, COUNT(Номер) cnt
  --,i.id
  --Счет, Комментарий
--  ,i.Наименование
--, s."КодСодержания" 
FROM bx_order o,
     bx_order_item i
     --, vwSyncDev s
  --AND i.Наименование = s.ie_name
LEFT OUTER join vwSyncDev s ON s.ie_name = i.Наименование
WHERE
  o.Номер = i.bx_order_Номер
  AND position (':' in i.Наименование) = 0
  AND s."КодСодержания" is not null
GROUP by Номер
--ORDER by Номер