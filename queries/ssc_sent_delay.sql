SELECT dt_change, dt_sent-dt_change as delta 
FROM arc_energo.stock_status_changed
WHERE id > 693485
and change_status <> -2
and dt_sent is not null -- в процессе
order by delta desc
