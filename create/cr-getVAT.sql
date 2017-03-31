-- Function: getVAT(integer, boolean)

-- DROP FUNCTION getVAT(integer, boolean);

CREATE OR REPLACE FUNCTION getVAT(acode integer)
  RETURNS NUMERIC AS
$BODY$
DECLARE
  locVAT NUMERIC;
  locEntStatus INTEGER;
BEGIN

PERFORM 1
FROM "Предприятия"
     JOIN "СоотношениеСтатуса" ON "Предприятия"."Код" = "СоотношениеСтатуса"."КодПредприятия"
WHERE
    acode = "Предприятия"."Код"
    AND "СоотношениеСтатуса"."СтатусПредприятия" = 12;

IF FOUND THEN
    locVAT = 0.0;
END IF;

RETURN locVAT;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION getVAT(integer)
  OWNER TO arc_energo;
COMMENT ON FUNCTION getVAT(integer) IS 'Возвращает применяемую ставку НДС, NULL - по умолчанию';
