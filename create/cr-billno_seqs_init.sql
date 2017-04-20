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
	FOR manager_id IN SELECT bc_list."Менеджер" FROM (SELECT "Менеджер" FROM vwbillcreator UNION SELECT 66) bc_list
	LOOP
        SELECT "№ счета" into loc_bill_no From Счета
                  WHERE "№ счета"
                    Between (manager_id * 100 + extract(Year from now()) - 1996) * 10000
                        and (manager_id + 1) * 1000000
                  ORDER BY "№ счета" DESC limit 1;
        last_bill_no := COALESCE(loc_bill_no % 10000, 0);
        -- RAISE NOTICE 'manager_id=%, loc_bill_no=%, last_bill_no=%', manager_id, loc_bill_no, last_bill_no;

        UPDATE "Счета" SET bill_no_seq = NULL
        WHERE "Хозяин" = manager_id
          AND "Дата счета" IS NOT NULL
          AND bill_no_seq IS NOT NULL
          AND bill_no_seq <> "№ счета";

        sql_str := format('ALTER SEQUENCE IF EXISTS billno_%s_%s_seq RESTART WITH %s;', manager_id, extract(Year from now()), last_bill_no +1);
        RAISE NOTICE 'sql_str=%', sql_str;
        EXECUTE sql_str;
    END LOOP; 
END;
$function$
