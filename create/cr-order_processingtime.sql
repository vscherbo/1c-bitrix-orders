-- Function: order_processingtime()

-- DROP FUNCTION order_processingtime();

CREATE OR REPLACE FUNCTION order_processingtime()
  RETURNS character varying AS
$BODY$  
SELECT "Значение" 
 FROM "ЭнциклопедияСтатья"
WHERE "КодЭнциклопедии" = 7 AND "КодСтатьи" = 11
 $BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION order_processingtime()
  OWNER TO arc_energo;
