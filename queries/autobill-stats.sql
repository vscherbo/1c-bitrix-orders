\echo 'Автосчёт не создан'
\echo
SELECT bx_order_no AS "Заказ", descr AS "Описание"
            FROM aub_log
            where res_code NOT IN (1,2,6,7) AND mod_id = '-1' AND dt_insert > now()- '1 day'::INTERVAL
            ORDER BY id;

\echo 'Создан частичный автосчёт'
\echo
SELECT bx_order_no AS "Заказ", descr AS "Описание"
FROM aub_log 
    WHERE bx_order_no IN
        (SELECT bx_order_no
            FROM aub_log
            where res_code IN (2,6,7) AND mod_id = '-1' AND dt_insert > now()- '1 day'::INTERVAL)
AND res_code IS NOT NULL            
ORDER BY id;

\echo 'Автосчёт создан'
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
