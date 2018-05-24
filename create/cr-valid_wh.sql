CREATE OR REPLACE FUNCTION arc_energo.valid_wh(arg_user_id integer)
 RETURNS integer[]
 LANGUAGE plpgsql
AS $function$ 
declare
arr integer[] := '{2,5,14}'; -- Ясная, Выставка, Дизайнеры
arr_manual_extra integer[] := '{49}'; -- РДС
BEGIN
-- user_id=1 auto_bill
if arg_user_id <> 1 then
    arr := arr || arr_manual_extra; 
end if;
RETURN arr;
END;
/** RETURNS text
SELECT(
SELECT concat_ws(',', 2,5,14) WHERE arg_user_id=1
UNION 
SELECT concat_ws(',', 2,5,14,49) WHERE arg_user_id<>1
) AS RESULT;
**/
 $function$;
