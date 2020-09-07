CREATE OR REPLACE FUNCTION arc_energo.no_vat(arg_inn varchar)
 RETURNS boolean
 LANGUAGE sql
AS $function$ 
/**
-- True, если ИНН найден в таблице tax_modes
SELECT COALESCE(
    (SELECT True FROM ext.tax_modes tm where tm.inn = arg_inn  )
    , FALSE) AS RESULT;
**/

-- True, если ИНН НЕ найден в arc_energo.tax_modes_excl И найден в таблице tax_modes
SELECT COALESCE(    
    (SELECT TRUE FROM ext.tax_modes tm
        LEFT OUTER JOIN arc_energo.tax_modes_excl ex ON tm.inn = ex.inn
        WHERE 
        ex.inn IS null and 
        tm.inn = arg_inn)
    , FALSE) AS RESULT;
$function$;
