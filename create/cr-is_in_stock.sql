-- Function: is_in_stock(integer)

-- DROP FUNCTION is_in_stock(integer);

CREATE OR REPLACE FUNCTION is_in_stock(IN "KS" integer)
  RETURNS TABLE(wh_id integer, wh_qnt numeric) AS
$BODY$
DECLARE loc_in_stock numeric;
BEGIN
 RETURN QUERY SELECT "КодСклада", SUM(("НаСкладе" - COALESCE("Рез", 0))::NUMERIC) -- INTO loc_in_stock
   FROM "vwСкладВсеПодробно"
   WHERE "КодСодержания" = "KS"
   AND quality = 0
   AND "КодСклада" IN (2, 5) -- Ясная, Выставка
   GROUP BY "КодСклада"
   ;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 2;
ALTER FUNCTION is_in_stock(integer)
  OWNER TO arc_energo;

