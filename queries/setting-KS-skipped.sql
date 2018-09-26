select "КодСодержания", d.dev_name, m.mod_id from devmod.modifications m
join devmod.device d on m.dev_id = d.dev_id and d.version_num = 1
where 
m.version_num = 1
-- and "КодСодержания" is not NULL
and m.mod_id in 
(SELECT x.mod_id FROM arc_energo.aub_log x
WHERE x.dt_insert > '2018-01-01 09:47:41.000' AND x.descr LIKE '%позиция отсутствует в базе АРК%')
order by "КодСодержания", dev_name