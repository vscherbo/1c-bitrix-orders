-- Function: setup_reserve(integer, integer, double precision, integer, integer)

-- DROP FUNCTION setup_reserve(integer, integer, double precision, integer, integer);

CREATE OR REPLACE FUNCTION setup_reserve(
    a_bill_no integer,
    ks integer,
    qnt double precision,
    usr integer DEFAULT '-1'::integer,
    code_position integer DEFAULT NULL::integer)
  RETURNS double precision AS
$BODY$DECLARE
   loc_qnt double precision;
   loc_okei INTEGER;
--   usr_name character varying;
   loc_usr integer;	
BEGIN

--SELECT Имя INTO usr_name FROM Сотрудники WHERE Номер = usr;
loc_usr = usr;

SELECT Coalesce(ОКЕИ,796) INTO loc_okei FROM arc_energo."Содержание" WHERE "КодСодержания"=ks;
	
IF loc_okei <>6 THEN  -- не мерный товар
    RAISE NOTICE 'ШТУЧНЫЙ %', loc_okei;
    loc_qnt := setup_reserve_item(a_bill_no, ks, qnt, loc_usr,code_position);
ELSE 
    RAISE NOTICE 'МЕРНЫЙ %', loc_okei;
    loc_qnt := setup_reserve_measured(a_bill_no, ks, qnt, loc_usr,code_position);
END IF;

RETURN loc_qnt;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION setup_reserve(integer, integer, double precision, integer, integer)
  OWNER TO arc_energo;
