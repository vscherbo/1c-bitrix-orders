select count(id) 
-- dt_change, date_trunc('day', dt_change), current_date  
FROM arc_energo.stock_status_changed
where
date_trunc('day', dt_change) >= current_date 
and change_status = 0 
and dt_sent is null -- в очереди
and now()-dt_change > '5 minute'::interval
-- order by id 

