-- Function: fn_getnewbillno(integer)

-- DROP FUNCTION fn_getnewbillno(integer);

CREATE OR REPLACE FUNCTION fn_getnewbillno(manager_id integer)
  RETURNS integer AS
$BODY$
DECLARE
  loc_bill_no integer;
begin
SELECT "№ счета" into loc_bill_no
  From Счета 
  WHERE "№ счета" 
    Between (manager_id * 100 + extract(Year from now()) - 1996) * 10000
        and (manager_id + 1) * 1000000 
  ORDER BY "№ счета" DESC limit 1;
  
  IF (loc_bill_no IS NULL) THEN
     loc_bill_no := (manager_id * 100 + extract(Year from now()) - 1996) * 10000 + 1;
  ELSE
     loc_bill_no := loc_bill_no + 1;
  END IF; --loc_bill_no IS NULL

  RETURN loc_bill_no;
end
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_getnewbillno(integer)
  OWNER TO arc_energo;
