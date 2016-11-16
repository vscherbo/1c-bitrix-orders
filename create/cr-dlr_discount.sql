-- Function: dlr_discount(integer, integer)

-- DROP FUNCTION dlr_discount(integer, integer);

CREATE OR REPLACE FUNCTION dlr_discount(
    dlr_code integer,
    ks integer)
  RETURNS integer AS
$BODY$DECLARE
loc_firm_discount INTEGER;
loc_item_discount INTEGER;
BEGIN
SELECT c."СкидкаДилеру" INTO loc_firm_discount FROM "Предприятия" c
             JOIN "СоотношениеСтатуса" ON c."Код" = "СоотношениеСтатуса"."КодПредприятия"
              WHERE "СоотношениеСтатуса"."СтатусПредприятия" = 3
              AND c."Код" = dlr_code;

SELECT "СкидкаДилеру" INTO loc_item_discount FROM "Содержание" 
WHERE "КодСодержания" = ks;

RETURN LEAST(
    COALESCE(loc_firm_discount, 0),
    COALESCE(loc_item_discount, 0));
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION dlr_discount(integer, integer)
  OWNER TO arc_energo;
