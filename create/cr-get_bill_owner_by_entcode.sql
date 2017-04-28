-- Function: get_bill_owner_by_entcode(integer)

-- DROP FUNCTION get_bill_owner_by_entcode(integer);

CREATE OR REPLACE FUNCTION arc_energo.get_bill_owner_by_entcode(entcode integer)
 RETURNS integer
 LANGUAGE sql
AS $function$
SELECT mgr as RESULT FROM
COALESCE(
(SELECT d."Менеджер"  FROM
        (SELECT "Менеджер"
            FROM 
            "ДилерыМенеджеров" dm
            WHERE 
                "Код" = entcode
                AND "Код" IN (SELECT "Код" FROM "vwДилеры")
                AND "Менеджер" IN (SELECT "Менеджер" 
                                    FROM "Сотрудники"
                                    WHERE "Менеджер" IS NOT NULL
                                    AND "МенеджерСтат" = TRUE
                                    AND "Активность" = TRUE
                )
            ORDER BY "Приоритет" LIMIT 1) d
)
            ,41) AS mgr   
$function$  VOLATILE
  COST 100;
ALTER FUNCTION get_bill_owner_by_entcode(integer)
  OWNER TO arc_energo;

  
