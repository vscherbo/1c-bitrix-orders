-- Function: get_owner_by_firm_code(integer)

-- DROP FUNCTION get_owner_by_firm_code(integer);

CREATE OR REPLACE FUNCTION get_owner_by_firm_code("aFirmCode" integer)
  RETURNS integer AS
$BODY$BEGIN
  RETURN 77;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION get_owner_by_firm_code(integer)
  OWNER TO arc_energo;
