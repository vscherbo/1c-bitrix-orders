CREATE OR REPLACE FUNCTION arc_energo.reget_missed_bx_order()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
bx_id varchar;
BEGIN
FOR bx_id IN select missed_bx_order_ids()
LOOP
    INSERT INTO inet_orders_status_queue(io_id, io_status, safe_mode) VALUES(bx_id::INTEGER, 'O', 'f');
    INSERT INTO inet_orders_status_queue(io_id, io_status, safe_mode) VALUES(bx_id::INTEGER, 'N', 'f');
END LOOP;
/**    
FOR bx_id IN
    SELECT  "Номер" + 1 as id
    FROM    bx_order bo
    WHERE   NOT EXISTS
            (
            SELECT  NULL
            FROM    bx_order bi
            WHERE   bi."Номер" = bo."Номер" + 1
            )
    and "Номер" + 1 not in (select bx_order_id from bx_order_missed  where status = 1)        
    ORDER by "Номер" desc 
    offset 1
LOOP
    INSERT INTO inet_orders_status_queue(io_id, io_status, safe_mode) VALUES(bx_id::INTEGER, 'O', 'f');
    INSERT INTO inet_orders_status_queue(io_id, io_status, safe_mode) VALUES(bx_id::INTEGER, 'N', 'f');
END LOOP;
**/
END;
 $function$
