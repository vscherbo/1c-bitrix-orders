CREATE OR REPLACE FUNCTION arc_energo.no_autobill_item(arg_ks integer)
 RETURNS boolean
 LANGUAGE sql
AS $function$ 
-- True, если товар имеет флаг СТОП
SELECT COALESCE(
(SELECT True FROM "Содержание" WHERE stop IS NOT NULL AND "КодСодержания" = arg_ks), FALSE) AS RESULT;
 $function$;
