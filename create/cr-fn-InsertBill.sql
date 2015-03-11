-- Function: fn_insertbill(numeric, integer, integer, integer)

-- DROP FUNCTION fn_insertbill(numeric, integer, integer, integer);

CREATE OR REPLACE FUNCTION fn_insertbill(
    sum numeric,
    bx_order integer,
    afirmcode integer,
    aempcode integer)
  RETURNS record AS
$BODY$ DECLARE
  ret_bill RECORD;
-- Хозяин=38 - Гараханян
-- Хозяин=77 - Бондаренко
  inet_bill_owner integer = 77;
BEGIN
-- Код=223719 - физ. лицо
WITH inserted AS (
   INSERT INTO "Счета"
          ("Код", "фирма", "Хозяин", "№ счета", "Дата счета", "Сумма", "Интернет", "ИнтернетЗаказ", "КодРаботника", "Статус") 
   VALUES (aFirmCode, 'АРКОМ', inet_bill_owner, fn_GetNewBillNo(inet_bill_owner), CURRENT_DATE, sum, 't', bx_order, aEmpCode, 0 ) 
   RETURNING * 
)
SELECT * INTO ret_bill FROM inserted;

RETURN ret_bill;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_insertbill(numeric, integer, integer, integer)
  OWNER TO arc_energo;
