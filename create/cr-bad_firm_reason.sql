CREATE OR REPLACE FUNCTION arc_energo.bad_firm_reason(arg_code integer)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
declare 
loc_reason text;
begin 
case arg_code 
    when -1 then 
       loc_reason := 'не удалось ни найти, ни создать предприятие';
    when -2 then 
       loc_reason := 'не удалось выбрать из дублей';
    when -3 then 
       loc_reason := 'непредвиденная длина ИНН';
    when -4 then 
       loc_reason := 'не задан ИНН, задан КПП';
    else 
       loc_reason := 'причина не описана';
end case;

return format('%s(%s)', loc_reason, quote_nullable(arg_code));
end
$function$;
