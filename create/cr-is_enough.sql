-- Function: is_enough(integer, numeric)

-- DROP FUNCTION is_enough(integer, numeric);

CREATE OR REPLACE FUNCTION is_enough(
    "KS" integer,
    "Quantity" numeric)
  RETURNS boolean AS
$BODY$
DECLARE in_stock numeric;
BEGIN
 SELECT "НаСкладе" - COALESCE("Рез", 0) INTO in_stock
   FROM "vwСкладВсеПодробно"
   WHERE "КодСодержания" = "KS"
   AND "КодСклада" = 2 -- Ясная
   AND "Примечание" = '';

   RAISE NOTICE 'На складе Ясная и без примечаний количество=%', in_stock;
   
   IF in_stock >= "Quantity"
   THEN
      return true;
   ELSE
      return false;
   END IF;
   
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION is_enough(integer, numeric)
  OWNER TO arc_energo;
