-- Trigger: tr_clean_inn_kpp on bx_buyer

-- DROP TRIGGER tr_clean_inn_kpp ON bx_buyer;

CREATE TRIGGER tr_clean_inn_kpp
  BEFORE INSERT OR UPDATE OF "ИНН", "КПП"
  ON bx_buyer
  FOR EACH ROW
  WHEN (((new."ИНН" IS NOT NULL) OR (new."КПП" IS NOT NULL)))
  EXECUTE PROCEDURE fntr_clean_inn_kpp();
