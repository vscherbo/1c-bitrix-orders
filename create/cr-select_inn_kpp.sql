--DROP FUNCTION arc_energo.select_inn_kpp(text, text);
CREATE OR REPLACE FUNCTION arc_energo.select_inn_kpp(arg_inn text, arg_kpp text)
 RETURNS SETOF record
 LANGUAGE plpgsql
AS $function$
declare
loc_select text := 'SELECT "Код" FROM "Предприятия"';
ret_firmcode record;
BEGIN
loc_select := concat_ws(' ', loc_select, 'WHERE', '"ИНН" = ' || quote_literal(arg_INN), 'and "КПП" = ' || quote_literal(arg_KPP), ';');
-- raise notice 'loc_select=%', loc_select;
begin
    FOR ret_firmcode IN EXECUTE loc_select
    loop
        RETURN NEXT ret_firmcode;
    END LOOP;
    return;
END;    
end;$function$

