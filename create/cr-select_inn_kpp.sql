--DROP FUNCTION arc_energo.select_inn_kpp(text, text);
CREATE OR REPLACE FUNCTION arc_energo.select_inn_kpp(arg_inn text, arg_kpp text)
 RETURNS setof record
 LANGUAGE plpgsql
AS $function$
declare
loc_select text := 'SELECT "Код" FROM "Предприятия"';
BEGIN
loc_select := concat_ws(' ', loc_select, 'WHERE', '"ИНН" = ' || quote_literal(arg_INN), 'and "КПП" = ' || quote_literal(arg_KPP), ';');
BEGIN
    EXECUTE loc_select; 
END;    
end;$function$;
