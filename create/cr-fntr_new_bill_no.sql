CREATE OR REPLACE FUNCTION fntr_new_bill_no()
  RETURNS trigger AS
$BODY$
DECLARE loc_bill_owner INTEGER;
BEGIN
loc_bill_owner := NEW."№ счета" / 1000000;
NEW.bill_no_seq := get_new_bill_no(loc_bill_owner);

RETURN NEW;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fntr_clean_inn_kpp()
  OWNER TO arc_energo;
