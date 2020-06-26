CREATE OR REPLACE FUNCTION arc_energo.bx_modificators_name(arg_order_no integer, arg_mod_id character varying)
 RETURNS character varying
 LANGUAGE sql
AS $function$
select
 (SELECT oif.fvalue FROM arc_energo.bx_order_item_feature oif 
      WHERE oif."bx_order_Номер" = arg_order_no
      AND oif.bx_order_item_id = boi."Ид" AND oif.fname = 'СвойствоКорзины#SKU_NAME')
from bx_order_item boi 
where 
    boi."bx_order_Номер" = arg_order_no
    and substring (boi."Наименование" from '[0-9]+$') = arg_mod_id;
$function$
;
