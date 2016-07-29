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

IF aCode = 223719 THEN
    ourFirm = 'АРКОМ';
ELSE 
    select INTO flgDealer exists(select 1 from vwДилеры WHERE "Код"= aCode);
    IF flgDealer THEN
        ourFirm = 'КИПСПБ';
    ELSIF flgOwen THEN
        ourFirm = 'ОСЗ';
    ELSE
        SELECT "фирма" INTO lastFirm FROM "Счета" WHERE "Код" = aCode AND "Дата счета" IS NOT NULL ORDER BY "Дата счета" DESC LIMIT 1;
        IF FOUND THEN
            ourFirm := lastFirm; -- see Patch below
        ELSE
            ourFirm = 'ЭТК';
        END IF; -- FOUND
    END IF;

END IF;

IF 'ТД2' = ourFirm THEN -- Patch
    ourFirm := 'ЭТК';
END IF;

RETURN ourFirm;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION getFirm(integer, boolean)
  OWNER TO arc_energo;
COMMENT ON FUNCTION getFirm(integer, boolean) IS 'Возвращает аббревиатуру нашей компании, от которой будет сформирован счёт';
