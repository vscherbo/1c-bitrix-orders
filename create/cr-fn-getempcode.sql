-- Function: fn_getempcode(integer, character varying, character varying)

-- DROP FUNCTION fn_getempcode(integer, character varying, character varying);

CREATE OR REPLACE FUNCTION fn_getempcode(buyer_id integer, buyer_name character varying, buyer_email character varying)
  RETURNS integer AS
$BODY$
declare
    emp record;
    emp_id integer;
begin
  SELECT * into emp from "Работники" where bx_buyer_id = buyer_id;
  IF (emp is null) THEN -- Работник не найден, создаём
     WITH inserted AS (
       insert INTO "Работники" ("КодРаботника", "Код", bx_buyer_id, "Дата", "ФИО", "ЕАдрес") values ((SELECT MAX("КодРаботника")+1 FROM "Работники"), 223719, buyer_id, now(), buyer_name, buyer_email) RETURNING "КодРаботника"
     )
     SELECT inserted."КодРаботника" INTO emp_id FROM inserted;
  ELSE
    emp_id := emp."КодРаботника";
  end if;
  RETURN emp_id;
end
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_getempcode(integer, character varying, character varying)
  OWNER TO arc_energo;
