CREATE OR REPLACE FUNCTION arc_energo.gen_billno_seqs()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
sql_str TEXT;
BEGIN
	FOR sql_str IN 
	    SELECT
	       format('CREATE SEQUENCE billno_%s_%s_seq;', "Менеджер", extract(Year from now())) 
	       FROM "Сотрудники" WHERE "МенеджерСтат"
	LOOP
	   -- RAISE NOTICE 'sql_str=%', sql_str;
	   EXECUTE sql_str;
    END LOOP; 
END;
$function$
