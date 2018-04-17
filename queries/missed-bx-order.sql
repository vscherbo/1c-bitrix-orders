SELECT  "Номер" + 1
FROM    bx_order bo
WHERE   NOT EXISTS
        (
        SELECT  NULL
        FROM    bx_order bi
        WHERE   bi."Номер" = bo."Номер" + 1
        )
and "Номер" + 1 not in (select bx_order_id from bx_order_missed  where status = 1)        
ORDER by "Номер" desc 
offset 1
