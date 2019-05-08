CREATE OR REPLACE FUNCTION arc_energo.get_missed_bx_order_ids()
 RETURNS text
 LANGUAGE sql
AS $function$
select array_to_string(array_agg(id), ',') as result from missed_bx_order_ids() AS id; 
$function$
