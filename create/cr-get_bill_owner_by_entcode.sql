-- Function: get_bill_owner_by_entcode(integer)

-- DROP FUNCTION get_bill_owner_by_entcode(integer);

CREATE OR REPLACE FUNCTION get_bill_owner_by_entcode(entcode integer)
  RETURNS integer AS
$BODY$BEGIN
  RETURN 44; -- 44-АГС, 77-ВВ
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION get_bill_owner_by_entcode(integer)
  OWNER TO arc_energo;
