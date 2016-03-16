CREATE OR REPLACE FUNCTION fntr_Резерв_текст()
  RETURNS trigger AS
$BODY$
DECLARE loc_str VARCHAR;
BEGIN
   IF (NEW."Подкого_Код" IS NOT NULL) AND (NEW."Подкого" IS NULL)
   THEN
      SELECT "Предприятие" INTO loc_str FROM "Предприятия" WHERE "Код" = NEW."Подкого_Код" ;
      NEW."Подкого" := loc_str;
   END IF;

   IF (NEW."Кем_Номер" IS NOT NULL) AND (NEW."Кем" IS NULL)
   THEN
      SELECT substring("ФИО" from 1 for 50) INTO NEW."Кем" FROM "Сотрудники" WHERE "Номер" = NEW."Кем_Номер" ;
   END IF;

   IF (NEW."КтоСнял_Номер" IS NOT NULL) AND (NEW."КтоСнял" IS NULL)
   THEN
      SELECT substring("ФИО" from 1 for 50) INTO NEW."КтоСнял" FROM "Сотрудники" WHERE "Номер" = NEW."КтоСнял_Номер" ;
   END IF;
   
   RETURN NEW;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
