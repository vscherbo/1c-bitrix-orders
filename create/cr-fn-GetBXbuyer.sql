-- Function: fn_getbxbuyer(integer, time without time zone)

-- DROP FUNCTION fn_getbxbuyer(integer, time without time zone);

CREATE OR REPLACE FUNCTION fn_getbxbuyer(buyer_id integer, order_timestamp time without time zone)
  RETURNS record AS
$BODY$DECLARE
  rec_buyer record;
begin
  SELECT * INTO rec_buyer FROM bx_buyer WHERE bx_buyer_id=buyer_id and dt_insert = order_timestamp;
  return rec_buyer;
end
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_getbxbuyer(integer, time without time zone)
  OWNER TO arc_energo;
