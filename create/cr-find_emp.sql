-- drop function find_emp(integer, integer);

create or replace function find_emp(IN arg_bx_order_id integer, IN arg_firm_code integer)
returns integer 
language plpgsql
as
$body$
DECLARE
loc_buyer_id integer;
ret_emp_code integer;
BEGIN
SELECT bx_buyer_id INTO loc_buyer_id FROM bx_order WHERE "Ид" = arg_bx_order_id;
-- Ищем Работника с loc_buyer_id. TODO STRICT?
SELECT ec."КодРаботника" INTO ret_emp_code FROM emp_company ec
WHERE ec.bx_buyer_id=loc_buyer_id AND ec."Код" = arg_firm_code;

IF NOT FOUND THEN -- регистрируем
    ret_emp_code := select_emp(arg_bx_order_id, arg_firm_code);
    IF ret_emp_code > 0 AND arg_firm_code <> 223719 THEN -- не физ.лицо
        RAISE NOTICE 'find_emp: Регистрируем работника с кодом=% для предприятия=% в emp_company', ret_emp_code, arg_firm_code;
        INSERT INTO emp_company VALUES(arg_firm_code, ret_emp_code, loc_buyer_id)
            ON CONFLICT ("Код", "КодРаботника")
            DO UPDATE SET bx_buyer_id = EXCLUDED.bx_buyer_id;
    END IF; 
END IF; -- not found in emp_company

return COALESCE(ret_emp_code, -4);
END;
$body$;
