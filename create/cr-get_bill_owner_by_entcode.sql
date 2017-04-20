-- Function: get_bill_owner_by_entcode(integer)

-- DROP FUNCTION get_bill_owner_by_entcode(integer);

CREATE OR REPLACE FUNCTION get_bill_owner_by_entcode(entcode integer)
  RETURNS integer AS
$BODY$
    SELECT d."Менеджер" as result FROM
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
    UNION
        -- SELECT 41 as result -- спец. менеджер для ввода автосчетов до 2017-09
        SELECT 38 as result -- Арутюн
            FROM "Предприятия" 
            WHERE entcode NOT IN (SELECT "Код" FROM "vwДилеры");
--  RETURN 44; -- 44-АГС, 77-ВВ
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION get_bill_owner_by_entcode(integer)
  OWNER TO arc_energo;
