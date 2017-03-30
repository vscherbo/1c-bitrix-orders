-- Function: getVAT(integer, boolean)

-- DROP FUNCTION getVAT(integer, boolean);

CREATE OR REPLACE FUNCTION getVAT(acode integer)
  RETURNS NUMERIC AS
$BODY$
DECLARE
  locVAT NUMERIC;
  locCountry VARCHAR;
  locEntStatus INTEGER;
BEGIN

SELECT "Республика", "СоотношениеСтатуса"."СтатусПредприятия" INTO locCountry, locEntStatus
FROM "Предприятия"
     JOIN "СоотношениеСтатуса" ON "Предприятия"."Код" = "СоотношениеСтатуса"."КодПредприятия"
WHERE 
    acode = "Предприятия"."Код";

IF 12 = locEntStatus THEN
    locVAT = 0.0;
/**
ELSIF 'Россия' <> locCountry THEN
    locVAT = 0.0;
**/
END IF;

RETURN locVAT;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION getVAT(integer)
  OWNER TO arc_energo;
COMMENT ON FUNCTION getVAT(integer) IS 'Возвращает применяемую ставку НДС, NULL - по умолчанию';
