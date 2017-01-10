-- Function: fntr_emp_company()

-- DROP FUNCTION fntr_emp_company();

CREATE OR REPLACE FUNCTION fntr_emp_company()
  RETURNS trigger AS
$BODY$BEGIN
IF 'INSERT' = TG_OP THEN
    INSERT INTO emp_company VALUES(NEW."Код", NEW."КодРаботника");
    RETURN NEW;
ELSIF 'DELETE' = TG_OP THEN
    DELETE FROM emp_company 
           WHERE 
            "Код" = OLD."Код"
            AND "КодРаботника" = OLD."КодРаботника";
    RETURN OLD;
END IF;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fntr_emp_company()
  OWNER TO arc_energo;
COMMENT ON FUNCTION fntr_emp_company() IS 'Добавляет/удаляет в emp_company нового/удалённого работника';
