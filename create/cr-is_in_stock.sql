-- Function: is_in_stock(integer, numeric)

-- DROP FUNCTION is_in_stock(integer, numeric);

CREATE OR REPLACE FUNCTION is_in_stock(
    "KS" integer,
    "Quantity" numeric)
  RETURNS numeric AS
$BODY$
DECLARE loc_in_stock numeric;
BEGIN
 SELECT "НаСкладе" - COALESCE("Рез", 0) INTO loc_in_stock
   FROM "vwСкладВсеПодробно"
   WHERE "КодСодержания" = "KS"
   AND "КодСклада" = 2 -- Ясная
   AND "Примечание" = '';

   RETURN COALESCE(loc_in_stock, 0);
   
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION is_in_stock(integer, numeric)
  OWNER TO arc_energo;
