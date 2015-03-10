-- Function: fn_getnewbillno(integer)

-- DROP FUNCTION fn_getnewbillno(integer);

CREATE OR REPLACE FUNCTION fn_getnewbillno(manager_id integer)
  RETURNS integer AS
$BODY$
DECLARE
  bill_no integer;
begin
SELECT "№ счета" into bill_no
  From Счета 
  WHERE "№ счета" 
    Between (manager_id * 100 + extract(Year from now()) - 1996) * 10000
        and (manager_id + 1) * 1000000 
  ORDER BY "№ счета" DESC limit 1;
  
  IF (bill_no IS NULL) THEN
     bill_no := (manager_id * 100 + extract(Year from now()) - 1996) * 10000 + 1;
  ELSE
     bill_no := bill_no + 1;
  END IF; --bill_no IS NULL

  RETURN bill_no;
end
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_getnewbillno(integer)
  OWNER TO arc_energo;
