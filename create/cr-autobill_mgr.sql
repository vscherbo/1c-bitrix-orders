-- DROP FUNCTION autobill_mgr(integer);

CREATE OR REPLACE FUNCTION autobill_mgr(arg_code integer)
RETURNS integer
language plpgsql
AS
$BODY$
declare 
   loc_mgr_code INTEGER;
BEGIN
	IF arg_code = 41 THEN -- returns an autobill active manager
	   -- SELECT const_value INTO loc_mgr_code FROM arc_constants WHERE const_name = 'autobill_mgr';
	   SELECT "Менеджер" INTO loc_mgr_code
            FROM "ДилерыМенеджеров"
            WHERE "Код" = -1
                AND "Менеджер" IN (SELECT "Менеджер" 
                                    FROM "Сотрудники"
                                    WHERE "Менеджер" IS NOT NULL
                                    AND "МенеджерСтат" = TRUE
                                    AND "Активность" = TRUE)
            ORDER BY "Приоритет" LIMIT 1;   
       RAISE NOTICE 'выбран менеджер автосчетов=%', loc_mgr_code;
	ELSE
	   loc_mgr_code := arg_code;
       -- RAISE NOTICE 'не менеджер-41, не меняем менеджера=%', loc_mgr_code;
	END IF;
	RETURN loc_mgr_code;
end
$BODY$
