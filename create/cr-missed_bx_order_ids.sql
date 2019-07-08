CREATE OR REPLACE FUNCTION arc_energo.missed_bx_order_ids()
 RETURNS SETOF integer
 LANGUAGE sql
AS $function$
SELECT  "Номер" + 1 as id
FROM    bx_order bo
WHERE   NOT EXISTS
        (
        SELECT  NULL
        FROM    bx_order bi
        WHERE   bi."Номер" = bo."Номер" + 1
        )
and "Номер" + 1 not in (SELECT bx_order_id FROM bx_order_missed WHERE status = 1)
-- например, заказ отсутствует на сайте. Требуется ручное разбирательство
and "Номер" + 1 not in (SELECT DISTINCT io_id FROM inet_orders_status_queue WHERE io_update_result = 1)
-- and bo."Дата" = current_date
-- с учётом выходных без заказов
and bo."Дата" >= current_date - '2 days'::interval
ORDER by "Номер" desc
offset 1;
$function$
