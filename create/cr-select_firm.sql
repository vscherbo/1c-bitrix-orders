--DROP FUNCTION arc_energo.select_firm(text, text);
CREATE OR REPLACE FUNCTION arc_energo.select_firm(arg_inn text, arg_kpp text)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
loc_Firm_code integer ;
BEGIN

BEGIN
--     SELECT "Код" INTO strict loc_Firm_code FROM "Предприятия" WHERE "ИНН" = arg_INN and ("КПП" IS NULL OR "КПП" = arg_KPP);
    SELECT "Код" INTO strict loc_Firm_code FROM select_inn_kpp(arg_inn, arg_kpp) as foo("Код" integer);
EXCEPTION
   WHEN NO_DATA_FOUND THEN
        RAISE NOTICE 'Предприятие с ИНН=% не найдено', arg_INN;
        loc_Firm_code := -1;
    WHEN TOO_MANY_ROWS THEN
        -- RAISE NOTICE 'Несколько Предприятий с ИНН=%', arg_INN;
        WITH firms AS (SELECT "Код" FROM select_inn_kpp(arg_inn, arg_kpp) as foo("Код" integer))
            , bills AS (SELECT "Код", "Дата счета" FROM "Счета" 
                                WHERE "Код" IN (SELECT * FROM firms) 
                                AND "№ Фактуры" IS NOT NULL 
                                AND "Дата счета" IS NOT NULL)
        SELECT "Код" INTO loc_Firm_code FROM
            (SELECT "Код"  FROM firms
                   JOIN "СоотношениеСтатуса" ON firms."Код" = "КодПредприятия"
                   WHERE "СтатусПредприятия" = 10
            union
            (SELECT "Код" FROM bills     
                ORDER BY bills."Дата счета" DESC
                LIMIT 1)
            ) firm_code ;
        loc_Firm_code := COALESCE(loc_Firm_code, -2);
END;

return loc_Firm_code;
end;$function$;
