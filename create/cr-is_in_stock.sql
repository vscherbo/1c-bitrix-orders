-- Function: is_in_stock(integer, numeric)

DROP FUNCTION is_in_stock(integer);

CREATE OR REPLACE FUNCTION is_in_stock(
    "KS" integer)
  RETURNS TABLE(wh_id INTEGER, wh_qnt NUMERIC(18,3)) AS
$BODY$
DECLARE loc_in_stock numeric;
BEGIN
 RETURN QUERY SELECT "КодСклада", SUM(("НаСкладе" - COALESCE("Рез", 0))::NUMERIC) -- INTO loc_in_stock
   FROM "vwСкладВсеПодробно"
   WHERE "КодСодержания" = "KS"
   AND "КодСклада" IN (2) -- Ясная
   -- AND "КодСклада" IN (2, 5) -- Ясная, Выставка
   GROUP BY "КодСклада"
   ;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
