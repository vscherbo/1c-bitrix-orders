-- Trigger: tr_Работники_AID on "Работники"

-- DROP TRIGGER "tr_Работники_AID" ON "Работники";

CREATE TRIGGER "tr_Работники_AID"
  AFTER INSERT OR DELETE
  ON "Работники"
  FOR EACH ROW
  EXECUTE PROCEDURE fntr_emp_company();
