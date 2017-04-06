CREATE OR REPLACE FUNCTION arc_energo.init_billno_seqs()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
manager_id INTEGER;
sql_str TEXT;
bill_no INTEGER;
last_bill_no INTEGER;
BEGIN
	FOR manager_id IN SELECT "Менеджер" FROM "Сотрудники" WHERE "МенеджерСтат"
	LOOP
        SELECT "№ счета" into bill_no From Счета
                  WHERE "№ счета"
                    Between (manager_id * 100 + extract(Year from now()) - 1996) * 10000
                        and (manager_id + 1) * 1000000
                  ORDER BY "№ счета" DESC limit 1;
        last_bill_no := bill_no % 10000;
        -- RAISE NOTICE 'manager_id=%, bill_no=%, last_no=%', manager_id, bill_no, last_bill_no;

        sql_str := format('ALTER SEQUENCE billno_%s_%s_seq RESTART WITH %s;', manager_id, extract(Year from now()), last_bill_no +1);
        RAISE NOTICE 'sql_str=%', sql_str;
        EXECUTE sql_str;
    END LOOP; 
END;
$function$
