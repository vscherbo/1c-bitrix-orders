-- Function: "fn_InsertBillItem"(integer, integer, character varying, numeric, numeric)

-- DROP FUNCTION "fn_InsertBillItem"(integer, integer, character varying, numeric, numeric);

CREATE OR REPLACE FUNCTION "fn_InsertBillItem"(bill_no integer, ks integer, measure_unit character varying, qnt numeric, price numeric)
  RETURNS integer AS
$BODY$BEGIN
   INSERT INTO "Содержание счета"
          ("КодПозиции", "КодСодержания", "№ счета", "Ед Изм", "Кол-во", "ЦенаНДС")
   VALUES ((SELECT MAX("КодПозиции")+1 FROM "Содержание счета"), KS, bill_no, measure_unit, Qnt, Price) returning "КодПозиции";
   RAISE NOTICE 'КодПозиции=%', inserted."КодПозиции";
RETURN inserted."КодПозиции";
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION "fn_InsertBillItem"(integer, integer, character varying, numeric, numeric)
  OWNER TO arc_energo;
