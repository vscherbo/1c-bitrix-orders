-- Function: orderitem_processingtime(integer)

-- DROP FUNCTION orderitem_processingtime(integer);

CREATE OR REPLACE FUNCTION orderitem_processingtime(ks integer)
  RETURNS character varying AS
$BODY$  -- ignore KS for a while
SELECT "Значение" 
 FROM "ЭнциклопедияСтатья"
WHERE "КодЭнциклопедии" = 7 AND "КодСтатьи" = 11
 $BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION orderitem_processingtime(integer)
  OWNER TO arc_energo;
COMMENT ON FUNCTION orderitem_processingtime(integer) IS 'Возвращает срок обработки позиции заказа (содержание счёта)';
