CREATE VIEW vwbxOrderItems AS
SELECT Номер, COUNT(Номер) cnt
FROM bx_order o,
     bx_order_item i
WHERE
  o.Номер = i.bx_order_Номер
  AND position (':' in i.Наименование) = 0
GROUP by Номер