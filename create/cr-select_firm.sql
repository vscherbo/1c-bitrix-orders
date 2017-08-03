--DROP FUNCTION arc_energo.select_firm(text, text);
CREATE OR REPLACE FUNCTION arc_energo.select_firm(arg_inn text, arg_kpp text)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
declare
loc_Firm_code integer ;
loc_select text := 'SELECT "Код" FROM "Предприятия"';
loc_where text;
BEGIN
loc_select := concat_ws(' ', loc_select, 'WHERE', '"ИНН" = ' || quote_literal(arg_INN), 'and "КПП" = ' || quote_literal(arg_KPP), ';');
RAISE NOTICE '%', loc_select;
BEGIN
    EXECUTE loc_select INTO strict loc_Firm_code; 
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
            RAISE NOTICE 'Предприятие с ИНН=% не найдено', arg_INN;
            loc_Firm_code := -1;
        WHEN TOO_MANY_ROWS THEN
            RAISE NOTICE 'Несколько Предприятий с ИНН=%', arg_INN;
            loc_Firm_code := -2;
END;    
return loc_Firm_code;
end;$function$;
