-- Function: fntr_clean_inn_kpp()

-- DROP FUNCTION fntr_clean_inn_kpp();

CREATE OR REPLACE FUNCTION fntr_clean_inn_kpp()
  RETURNS trigger AS
$BODY$BEGIN
NEW."ИНН" = digits_only(NEW."ИНН");
NEW."КПП" = digits_only(NEW."КПП");

RETURN NEW;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fntr_clean_inn_kpp()
  OWNER TO arc_energo;
