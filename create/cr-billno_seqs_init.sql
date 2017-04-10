-- DROP FUNCTION arc_energo.billno_seqs_init();

CREATE OR REPLACE FUNCTION arc_energo.billno_seqs_init()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
manager_id INTEGER;
sql_str TEXT;
loc_bill_no INTEGER;
last_bill_no INTEGER;
BEGIN
	FOR manager_id IN SELECT "Менеджер" FROM vwbillcreator
	LOOP
        SELECT "№ счета" into loc_bill_no From Счета
                  WHERE "№ счета"
                    Between (manager_id * 100 + extract(Year from now()) - 1996) * 10000
                        and (manager_id + 1) * 1000000
                  ORDER BY "№ счета" DESC limit 1;
        last_bill_no := COALESCE(bloc_ill_no % 10000, 0);
        -- RAISE NOTICE 'manager_id=%, loc_bill_no=%, last_bill_no=%', manager_id, loc_bill_no, last_bill_no;

        sql_str := format('ALTER SEQUENCE IF EXISTS billno_%s_%s_seq RESTART WITH %s;', manager_id, extract(Year from now()), last_bill_no +1);
        RAISE NOTICE 'sql_str=%', sql_str;
        EXECUTE sql_str;
    END LOOP; 
END;
$function$
