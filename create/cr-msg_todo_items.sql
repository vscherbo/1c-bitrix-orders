CREATE OR REPLACE FUNCTION arc_energo.msg_todo_items(order_id integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
declare 
loc_str varchar := E'';
begin

with todo_mod_id as (
    SELECT al.mod_id, max (al.res_code)
           FROM arc_energo.aub_log al                                                
               -- JOIN bx_order_item boi on boi."bx_order_Номер" = al.bx_order_no and substring (boi."Наименование" from '[0-9]+$') = al.mod_id
       WHERE al.bx_order_no=order_id and al.mod_id <> '-1' and al.res_code is not null 
           and res_code IN (SELECT ab_code FROM arc_energo.vw_autobill_partly)
               group by al.mod_id
                   -- ORDER BY al.id
    )
SELECT regexp_replace(string_agg(name1 , E'\n'), '\?', 'Ø', 'g') INTO loc_str from
    (select regexp_replace(fiscal_name(mod_id), '[0-9]{12} ', '') || ', ' || bx_modificators_name(order_id, mod_id) 
    as name1 from todo_mod_id) item_name;

--raise notice '%', loc_str;
return loc_str;
end
$function$
;

