-- Function: fn_inetbill4neworders()

-- DROP FUNCTION fn_inetbill4neworders();

CREATE OR REPLACE FUNCTION fn_inetbill4neworders()
  RETURNS void AS
$BODY$ DECLARE
  o RECORD;
BEGIN
   FOR o IN SELECT * FROM bx_order WHERE billcreated = 0 ORDER BY "Номер" LOOP
       EXECUTE fn_createinetbill(o."Номер");
   END LOOP;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_inetbill4neworders()
  OWNER TO arc_energo;
COMMENT ON FUNCTION fn_inetbill4neworders() IS 'Пытается создать счета для новых загруженных заказов';
