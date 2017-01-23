-- FUNCTION: arc_energo.get_emp(integer)

-- DROP FUNCTION arc_energo.get_emp(integer);

CREATE OR REPLACE FUNCTION arc_energo.get_emp(
    bx_order_id integer,
    email VARCHAR)
    RETURNS record
    LANGUAGE 'plpgsql'
    COST 100.0
    VOLATILE NOT LEAKPROOF 
AS $function$

DECLARE
    emp RECORD;
    Firm RECORD;
    INN VARCHAR;
    KPP VARCHAR;
    FirmCode INTEGER;
    loc_buyer_id INTEGER;
    new_emp BOOLEAN;
BEGIN
    SELECT bx_buyer_id INTO loc_buyer_id FROM bx_order WHERE "Номер" = bx_order_id;

	SELECT digits_only(trim(both FROM fvalue)) INTO INN FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'ИНН';
    SELECT digits_only(trim(both FROM fvalue)) INTO KPP FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'КПП';

    IF (INN IS NOT NULL) -- AND (KPP IS NOT NULL) -- юр. лицо, у ИП нет КПП
    THEN
        RAISE NOTICE 'Юр. лицо, ИНН=%, КПП=%. Ищем Работника с loc_buyer_id=%', INN, COALESCE(KPP, '_не_задан_'), loc_buyer_id;
        Firm := fn_find_enterprise(INN, KPP);
        FirmCode := COALESCE(Firm."Код", create_firm(bx_order_id, INN, KPP));
        new_emp := True;
        -- Ищем Работника с loc_buyer_id
        SELECT ec."КодРаботника", ec."Код", '-1' AS "ЕАдрес" INTO emp 
        FROM emp_company ec
            JOIN "Предприятия" f ON f."Код"=ec."Код"
            WHERE ec.bx_buyer_id=loc_buyer_id
            AND f."ИНН"=INN;
        IF FOUND THEN
            new_emp := False;
            RAISE NOTICE 'такой покупатель с сайта для предприятия найден.';
           	SELECT "ЕАдрес" INTO emp."ЕАдрес" FROM "Работники" WHERE "Работники"."КодРаботника" = emp."КодРаботника";
        ELSIF email IS NOT NULL THEN -- ищем Работника по email
            RAISE NOTICE 'покупатель для предприятия=% по loc_buyer_id=% не найден. Ищем по email=%', FirmCode, loc_buyer_id, email;
           	SELECT "КодРаботника", "Код", "ЕАдрес" INTO emp FROM "Работники" WHERE "Работники"."ЕАдрес" = email;
           	IF FOUND THEN
                new_emp := False;
                RAISE NOTICE 'Найден Работник по email=%. Регистрируем для предприятия=% в emp_company', FirmCode, email;
           	   	INSERT INTO emp_company VALUES(FirmCode, emp."КодРаботника", loc_buyer_id)
					ON CONFLICT ("Код", "КодРаботника") -- ON CONSTRAINT  "emp_company_PK" 
					DO UPDATE SET bx_buyer_id = EXCLUDED.bx_buyer_id;
           	END IF; -- найден Работник по email
        END IF;

        IF new_emp THEN
           	emp := create_emp(bx_order_id, FirmCode);
        END IF;
    ELSIF (INN IS NULL) AND (KPP IS NULL) THEN -- физ. лицо
        RAISE NOTICE 'Физ. лицо. Ищем Работника с loc_buyer_id=%', loc_buyer_id;
        FirmCode := 223719;
        new_emp := True;
        SELECT ec."КодРаботника", ec."Код", '-1' AS "ЕАдрес" INTO emp 
        FROM emp_company ec
            WHERE ec.bx_buyer_id=loc_buyer_id
            AND ec."Код" = FirmCode;
        IF FOUND THEN -- такой покупатель с сайта уже зарегистрирован
            new_emp := False;
            RAISE NOTICE 'такой покупатель с сайта уже зарегистрирован';
            SELECT "ЕАдрес" INTO emp."ЕАдрес" FROM "Работники" WHERE "Работники"."КодРаботника" = emp."КодРаботника";
        ELSIF email IS NOT NULL THEN -- ищем Работника по email
            RAISE NOTICE 'покупатель по loc_buyer_id=% не найден. Ищем по email=%', loc_buyer_id, email;
           	SELECT "КодРаботника", "Код", "ЕАдрес" INTO emp FROM "Работники" WHERE "Работники"."ЕАдрес" = email;
           	IF FOUND THEN
                new_emp := False;
                RAISE NOTICE 'Найден Работник по email=%. Регистрируем в emp_company', email;
           	   	INSERT INTO emp_company VALUES(FirmCode, emp."КодРаботника", loc_buyer_id)
					ON CONFLICT ("Код", "КодРаботника") -- ON CONSTRAINT  "emp_company_PK" 
					DO UPDATE SET bx_buyer_id = EXCLUDED.bx_buyer_id;
           	END IF; -- найден Работник по email
        END IF;

        IF new_emp THEN
        	emp := create_emp(bx_order_id, FirmCode);
        END IF;
    ELSIF (INN IS NULL) AND (KPP IS not NULL) THEN -- юр. лицо, неполная информация
        RAISE NOTICE 'Юр. лицо, неполная информация ИНН=_не_задан_, КПП=%', KPP;
    END IF; -- IF INN, KPP

    IF emp."ЕАдрес" IS NULL THEN
        SELECT fvalue INTO email FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Контактный Email';
        UPDATE "Работники" SET "ЕАдрес" = email WHERE bx_buyer_id = loc_buyer_id;
    END IF;

RAISE NOTICE 'КодРаботника=%, Код=%, ЕАдрес=%', emp."КодРаботника", emp."Код", emp."ЕАдрес";
RETURN emp;
END

$function$;

ALTER FUNCTION arc_energo.get_emp(integer, varchar)
    OWNER TO arc_energo;



