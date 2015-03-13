SELECT s.Номер
FROM 
  vwbxOrderSyncItems s, vwbxOrderItems i
WHERE s.cnt = i.cnt
AND s.Номер = i.Номер
