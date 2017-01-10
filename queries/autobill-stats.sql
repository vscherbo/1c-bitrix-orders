\echo 'Несинхронизованные приборы, автосчёт не создан'
\echo
SELECT bx_order_no AS "Заказ", descr AS "Описание"
FROM aub_log where res_code=2 AND mod_id <> '-1' AND dt_insert > now()- '1 day'::INTERVAL;

\echo 'Недостаток на складе, автосчёт не создан'
\echo
SELECT bx_order_no AS "Заказ", descr AS "Описание"
FROM aub_log where res_code=6 AND mod_id <> '-1' AND dt_insert > now()- '1 day'::INTERVAL;

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
/*
SELECT bx_order_no, descr  FROM aub_log where res_code=1 AND dt_insert > now()- '1 day'::INTERVAL
AND bx_order_no NOT IN (SELECT bx_order_no FROM aub_log WHERE dt_insert > now()- '1 day'::INTERVAL AND res_code >1);
*/

