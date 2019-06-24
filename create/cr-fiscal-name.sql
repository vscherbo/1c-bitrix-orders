CREATE OR REPLACE FUNCTION arc_energo.fiscal_name(arg_mod_id text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
 res text;
BEGIN
    select format('%s %s %s', loc_mod_id, trim(loc_dev_name_short), trim(loc_dev_name) ) into res
    from (
        SELECT 10 as priority, m.mod_id  as loc_mod_id, d.dev_name_short as loc_dev_name_short, d.dev_name as loc_dev_name
        FROM modifications m
        JOIN device d ON m.dev_id = d.dev_id AND d.version_num=1
        WHERE m.version_num=1 AND mod_id = arg_mod_id
        union
        select 20 as priority, arg_mod_id as loc_mod_id, ip_prop475 as loc_dev_name_short, ie_name as loc_dev_name
        from bx_dev
        where ip_prop674 = (select ic_xml_id0::text from bx_price
               where ip_prop109::text like '%' || arg_mod_id || '%')
    ) fisc
    order by priority limit 1;
    RETURN res;
    EXCEPTION WHEN OTHERS THEN
        RETURN NULL;
END
--'009400000001'
-- '011420000006'
$function$;
