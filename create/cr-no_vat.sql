CREATE OR REPLACE FUNCTION arc_energo.no_vat(arg_inn varchar)
 RETURNS boolean
 LANGUAGE sql
AS $function$ 
-- True, если ИНН найден в таблице tax_modes
SELECT COALESCE(
    (SELECT True FROM ext.tax_modes tm where tm.inn = arg_inn  )
    , FALSE) AS RESULT;
$function$;
