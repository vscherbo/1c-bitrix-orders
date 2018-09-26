\set QUIET on
\t on
select 'Автосчёт не создан: ' || count(*)
FROM arc_energo.bx_order bo
where
bo.billcreated not in (select * from vw_autobill_created) -- (1,2,6,7,10) -- прочее, ошибки
and dt_insert > now()- '121 day'::INTERVAL;

\t off
SELECT bx_order_no AS "Заказ", format('%s: %s', descr, abr.ab_reason) AS "Описание"
            FROM aub_log
            left join autobill_reason abr on abr.ab_code = res_code
            where 
            res_code NOT IN (select * from vw_autobill_created)  -- (1,2,6,7,10) 
            AND mod_id = '-1' AND dt_insert > now()- '121 day'::interval
            and not exists (SELECT 1 FROM aub_log al1
                                     where aub_log.bx_order_no = al1.bx_order_no 
                                           and al1.res_code IN (select * from vw_autobill_created) -- (1,2,6,7,10)
                                           and mod_id = '-1')
            ORDER BY id;

