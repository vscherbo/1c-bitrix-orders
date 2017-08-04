\set QUIET on
\t on
select 'Автосчёт не создан: ' || count(*) 
FROM arc_energo.bx_order bo 
where 
bo.billcreated not in (1,2,6,7) -- прочее, ошибки
and dt_insert > now()- '1 day'::INTERVAL;
\t off
SELECT bx_order_no AS "Заказ", descr AS "Описание"
            FROM aub_log
            where res_code NOT IN (1,2,6,7) AND mod_id = '-1' AND dt_insert > now()- '1 day'::INTERVAL
            ORDER BY id;



\echo
\t on
select 'Создан частичный автосчёт: ' || count(*) 
FROM arc_energo.bx_order bo 
where 
bo.billcreated in (2,6,7) -- частичный
and dt_insert > now()- '1 day'::INTERVAL;
\t off
SELECT bx_order_no AS "Заказ", descr AS "Описание"
FROM aub_log 
    WHERE bx_order_no IN
        (SELECT bx_order_no
            FROM aub_log
            where res_code IN (2,6,7) AND mod_id = '-1' AND dt_insert > now()- '1 day'::INTERVAL)
AND res_code IS NOT NULL            
ORDER BY id;



\echo
\t on
select 'Автосчёт создан: ' || count(*) 
FROM arc_energo.bx_order bo 
where 
bo.billcreated = 1 -- полный
and dt_insert > now()- '1 day'::INTERVAL;
\t off
\echo
SELECT bx_order_no AS "Заказ", descr AS "Описание"
FROM aub_log
    WHERE bx_order_no IN
        (SELECT bx_order_no
            FROM aub_log
            WHERE mod_id='-1'
            AND res_code=1
            AND dt_insert > now()- '1 day'::INTERVAL)
AND res_code=1
ORDER BY id;
