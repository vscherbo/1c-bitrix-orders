-- Function: setup_reserve(integer, integer, double precision)

-- DROP FUNCTION setup_reserve(integer, integer, double precision);

CREATE OR REPLACE FUNCTION setup_reserve(
    bill_no integer,
    ks integer,
    qnt double precision)
  RETURNS double precision AS
$BODY$DECLARE
   loc_qnt double precision;
   loc_okei INTEGER;
BEGIN

SELECT Coalesce(ОКЕИ,796) INTO loc_okei FROM arc_energo."Содержание" WHERE "КодСодержания"=ks;
	
IF 796 == loc_okei THEN  -- штучный
    RAISE NOTICE 'ШТУЧНЫЙ %', loc_okei;
    loc_qnt := setup_reserve_item(bill_no, ks, qnt);
    RAISE NOTICE 'отработала setup_reserve_item, не удалось поставить в резерв %', loc_qnt;
ELSE 
    RAISE NOTICE 'МЕРНЫЙ %', loc_okei;
    loc_qnt := setup_reserve_measured(bill_no, ks, qnt);
    RAISE NOTICE 'отработала setup_reserve_measured, не удалось поставить в резерв %', loc_qnt;
END IF;

RAISE NOTICE 'Возвращаем loc_qnt=%', loc_qnt;
RETURN loc_qnt;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION setup_reserve(integer, integer, double precision)
  OWNER TO arc_energo;
