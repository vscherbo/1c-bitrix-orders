-- Trigger: tr_Резерв_BIU on "Резерв"

-- DROP TRIGGER "tr_Резерв_BIU" ON "Резерв";

CREATE TRIGGER "tr_Резерв_BIU"
  BEFORE INSERT OR UPDATE
  ON "Резерв"
  FOR EACH ROW
  EXECUTE PROCEDURE "fntr_Резерв_текст"();
COMMENT ON TRIGGER "tr_Резерв_BIU" ON "Резерв" IS 'Заполняет, если не заполнены поля Подкого, Кем и КтоСнял по соответсвующим ID Подкого_Код, Кем_Номер и КтоСнял_Номер.';
