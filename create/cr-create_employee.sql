-- DROP FUNCTION arc_energo.create_employee(integer, integer, text);

CREATE OR REPLACE FUNCTION arc_energo.create_employee(
    arg_bx_order_id integer,
    arg_firmcode integer,
    arg_email text
)
    RETURNS integer
    LANGUAGE 'plpgsql'
    COST 100.0
    VOLATILE NOT LEAKPROOF 
AS $function$

declare
    ZipCode VARCHAR;
    DeliveryAddress VARCHAR;
    PersonLocation VARCHAR;
    person VARCHAR;
    phone VARCHAR;
    EmpNotice VARCHAR;
    ret_emp_code integer;
loc_email TEXT;
begin
loc_email := coalesce(arg_email, 'н/д');
RAISE NOTICE 'create_employee: Создаём Работника bx_order_id=%, firmcode=%, email=%', arg_bx_order_id, arg_firmcode, loc_email;

SELECT fvalue INTO person FROM bx_order_feature WHERE "bx_order_Номер" = arg_bx_order_id AND fname = 'Контактное лицо';
IF NOT FOUND THEN person := loc_email; END IF;

SELECT fvalue INTO PersonLocation FROM bx_order_feature WHERE "bx_order_Номер" = arg_bx_order_id AND fname = 'Местоположение';
IF NOT found THEN PersonLocation := ''; END IF;
-- trim(both FROM fvalue)
SELECT digits_only(fvalue) INTO ZipCode FROM bx_order_feature WHERE "bx_order_Номер" = arg_bx_order_id AND fname = 'Индекс';
IF not found THEN ZipCode := ''; END IF;
SELECT fvalue INTO DeliveryAddress FROM bx_order_feature WHERE "bx_order_Номер" = arg_bx_order_id AND fname = 'Адрес доставки';
EmpNotice := SUBSTRING(concat_ws(', ', ZipCode, PersonLocation, DeliveryAddress) from 1 for 255);

SELECT fvalue INTO phone  FROM bx_order_feature WHERE "bx_order_Номер" = arg_bx_order_id AND fname = 'Контактный телефон';
IF NOT FOUND THEN phone := 'н/д'; END IF;

WITH inserted AS (
   INSERT INTO "Работники" ("КодРаботника", "Код", -- bx_buyer_id, 
                            "Дата", "ФИО", "Телефон", "ЕАдрес", "Примечание")  
                            values ((SELECT MAX("КодРаботника")+1 FROM "Работники"), arg_firmcode,
                            now(), person, phone, loc_email, EmpNotice)
                            RETURNING "КодРаботника", "Код", "ЕАдрес" 
)
SELECT inserted."КодРаботника" INTO ret_emp_code FROM inserted;
--
RAISE NOTICE 'Создан работник КодРаботника=%', ret_emp_code;
RETURN ret_emp_code;
end

$function$;

ALTER FUNCTION arc_energo.create_employee(integer, integer, text)
    OWNER TO arc_energo;

