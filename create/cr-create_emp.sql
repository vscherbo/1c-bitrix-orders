-- FUNCTION: arc_energo.create_emp(integer, integer)

-- DROP FUNCTION arc_energo.create_emp(integer, integer);

CREATE OR REPLACE FUNCTION arc_energo.create_emp(
    bx_order_id integer,
    firmcode integer)
    RETURNS record
    LANGUAGE 'plpgsql'
    COST 100.0
    VOLATILE NOT LEAKPROOF 
AS $function$

declare
    emp RECORD;
    ZipCode VARCHAR;
    DeliveryAddress VARCHAR;
    PersonLocation VARCHAR;
    email VARCHAR;
    email1 VARCHAR;
    person VARCHAR;
    phone VARCHAR;
    EmpNotice VARCHAR;
begin
RAISE NOTICE 'Создаём работника';

SELECT fvalue INTO email FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Контактный Email';
SELECT fvalue INTO email1 FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'EMail';
IF 'siteorders@kipspb.ru' <> email1 AND email <> email1 THEN
    email := email1;
    RAISE NOTICE 'заменяем _контактный email_ на EMail';
END IF;

SELECT fvalue INTO person FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Контактное лицо';
IF NOT FOUND THEN person := email; END IF;

SELECT fvalue INTO PersonLocation FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Местоположение';
IF NOT found THEN PersonLocation := ''; END IF;
SELECT trim(both FROM fvalue) INTO ZipCode FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Индекс';
IF not found THEN ZipCode := ''; END IF;
SELECT fvalue INTO DeliveryAddress FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Адрес доставки';
EmpNotice := SUBSTRING(concat_ws(', ', ZipCode, PersonLocation, DeliveryAddress) from 1 for 255);

SELECT fvalue INTO phone  FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Контактный телефон';
IF NOT FOUND THEN phone := 'н/д'; END IF;

WITH inserted AS (
   INSERT INTO "Работники" ("КодРаботника", "Код", -- bx_buyer_id, 
                            "Дата", "ФИО", "Телефон", "ЕАдрес", "Примечание")  
                            values ((SELECT MAX("КодРаботника")+1 FROM "Работники"), firmcode, -- buyer_id, 
                            now(), person, phone, email, EmpNotice) 
                            RETURNING "КодРаботника", "Код", "ЕАдрес" 
)
SELECT inserted."КодРаботника", inserted."Код", inserted."ЕАдрес" INTO emp FROM inserted;
--
RAISE NOTICE 'Создан работник КодРаботника=%', emp."КодРаботника";

RETURN emp;
end

$function$;

ALTER FUNCTION arc_energo.create_emp(integer, integer)
    OWNER TO arc_energo;

