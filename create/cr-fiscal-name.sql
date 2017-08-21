CREATE OR REPLACE FUNCTION arc_energo.fiscal_name(arg_mod_id text)
 RETURNS text
 LANGUAGE sql
AS $function$
SELECT format('%s %s %s', m.mod_id, trim(from d.dev_name_long), trim(from d.dev_name)) AS result
FROM modifications m
JOIN device d ON m.dev_id = d.dev_id AND d.version_num=1
WHERE m.version_num=1 AND mod_id = arg_mod_id;
--'009400000001'
-- '011420000006'
$function$
