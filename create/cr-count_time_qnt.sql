CREATE OR REPLACE FUNCTION arc_energo.count_time_qnt(arg_time_qnt text)
 RETURNS numeric
 LANGUAGE plpgsql
AS $function$
DECLARE
loc_counted numeric := 0;
loc_when TEXT;
loc_part text;
loc_qnt NUMERIC;
BEGIN
FOR loc_part IN SELECT regexp_split_to_table(trim(both ' ;' from arg_time_qnt) , ';')
loop
    -- raise NOTICE 'loc_part=%', loc_part;
    loc_when := TRIM(split_part(loc_part, ':'::TEXT, 1));
    BEGIN
        loc_qnt := TRIM(split_part(loc_part, ':'::TEXT, 2))::NUMERIC;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Неверный формат числа в [%]', loc_part;
        loc_qnt := 0;
        exit;
    END; -- cast to numeric
    RAISE NOTICE 'Подсчёт общего количества when={%}, quantity={%}', loc_when, loc_qnt;
    loc_counted := loc_counted + loc_qnt;
END LOOP;

return loc_counted;
END;
$function$
