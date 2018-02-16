-- Function: get_delivery_quantity(integer, text)

-- DROP FUNCTION get_delivery_quantity(integer, text);

CREATE OR REPLACE FUNCTION get_delivery_quantity(
arg_order_id integer,
arg_order_item_id text)
  RETURNS text AS
$BODY$
    SELECT fvalue AS RESULT 
           FROM bx_order_item_feature 
           WHERE "bx_order_Номер" = arg_order_id
                 AND bx_order_item_id = arg_order_item_id 
                 AND (fname = 'Срок-Количество' OR fname = 'СвойствоКорзины#TIME_QNT') ;
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION get_delivery_quantity(integer, text)
  OWNER TO arc_energo;

