-- Function: getFirm(integer, boolean)

-- DROP FUNCTION getFirm(integer, boolean);

CREATE OR REPLACE FUNCTION getFirm(
    acode integer,
    flgowen boolean)
  RETURNS character varying AS
$BODY$
DECLARE
  ourFirm VARCHAR;
  flgDealer BOOLEAN;
  lastFirm VARCHAR;
BEGIN

PERFORM 1
FROM "Предприятия"
     JOIN "СоотношениеСтатуса" ON "Предприятия"."Код" = "СоотношениеСтатуса"."КодПредприятия"
WHERE 
    acode = "Предприятия"."Код"
    AND "СоотношениеСтатуса"."СтатусПредприятия" = 12;
IF FOUND THEN
    ourFirm = 'АРКОМ';
ELSIF aCode = 223719 THEN
    ourFirm = 'АРКОМ';
ELSE 
    SELECT INTO flgDealer exists(select 1 from vwДилеры WHERE "Код"= aCode);
    IF flgDealer THEN
--        ourFirm = 'КИПСПБ';
       ourFirm = 'ТД3';
    ELSIF flgOwen THEN
        ourFirm = 'ОСЗ';
    ELSE
        SELECT "фирма" INTO lastFirm FROM "Счета" 
        WHERE "Код" = aCode 
              AND "фирма"<>'ОСЗ' 
              AND "Дата счета" IS NOT NULL 
        ORDER BY "Дата счета" DESC LIMIT 1;

        IF FOUND THEN
            ourFirm := lastFirm; -- see Patch below
        ELSE
            ourFirm = 'ЭТК';
        END IF; -- FOUND
    END IF;

END IF;

-- IF 'ТД2' = ourFirm THEN -- Patch
-- IF ourFirm NOT IN ('АРКОМ', 'КИПСПБ', 'ОСЗ', 'ЭТК') THEN -- Patch
IF ourFirm NOT IN ('АРКОМ', 'ОСЗ', 'ЭТК', 'ТД3') THEN -- Patch
    ourFirm := 'ЭТК';
END IF;

RETURN ourFirm;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION getFirm(integer, boolean)
  OWNER TO arc_energo;
COMMENT ON FUNCTION getFirm(integer, boolean) IS 'Возвращает аббревиатуру нашей компании, от которой будет сформирован счёт';
