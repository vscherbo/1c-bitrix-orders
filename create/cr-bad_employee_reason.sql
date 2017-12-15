CREATE OR REPLACE FUNCTION arc_energo.bad_employee_reason(arg_code integer)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
declare 
loc_reason text;
begin 
case arg_code 
    when -2 then 
       loc_reason := 'не удалось выбрать из дублей';
    when -3 then 
       loc_reason := 'иная ошибка';
    when -4 then
      loc_reason := 'причина не описана';
    else 
       loc_reason := 'причина не определена';
end case;   

return format('%s(%s)', loc_reason, quote_nullable(arg_code));
end
$function$;
