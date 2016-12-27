-- FUNCTION: arc_energo.get_emp(integer, integer)

-- DROP FUNCTION arc_energo.get_emp(integer, integer);

CREATE OR REPLACE FUNCTION arc_energo.get_emp(
    buyer_id integer,
    bx_order_id integer)
    RETURNS record
    LANGUAGE 'plpgsql'
    COST 100.0
    VOLATILE NOT LEAKPROOF 
AS $function$

declare
    emp RECORD;
    Firm RECORD;
    INN VARCHAR;
    KPP VARCHAR;
    FirmCode INTEGER;
    email VARCHAR;
begin
SELECT "КодРаботника", "Код", "ЕАдрес" into emp from "Работники" where bx_buyer_id = buyer_id;
IF not found THEN -- (emp is null) THEN -- Работник не найден, создаём
    RAISE NOTICE 'Покупатель не найден, создаём. buyer_id=%', buyer_id;
    SELECT trim(both FROM fvalue) INTO INN FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'ИНН';
    INN := regexp_replace(INN, '[^0-9]*', '', 'g');
    SELECT fvalue INTO KPP FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'КПП';
    KPP := regexp_replace(KPP, '[^0-9]*', '', 'g');

    IF (INN IS NOT NULL) -- AND (KPP IS NOT NULL) -- юр. лицо, у ИП нет КПП
    THEN
        KPP := COALESCE(KPP, '_не_задан_');
        RAISE NOTICE 'Юр. лицо, ИНН=%, КПП=%', INN, KPP;

        Firm := fn_find_enterprise(INN, KPP);
        FirmCode := COALESCE(Firm."Код", create_firm(bx_order_id, INN, KPP));
        emp := create_emp(bx_order_id, FirmCode);
    ELSIF (INN IS NULL) AND (KPP IS NULL) THEN -- физ. лицо
        RAISE NOTICE 'Физ. лицо';
        FirmCode := 223719;
        emp := create_emp(bx_order_id, FirmCode);
    ELSIF (INN IS NULL) AND (KPP IS not NULL) THEN -- юр. лицо, неполная информация
        RAISE NOTICE 'Юр. лицо, неполная информация ИНН=_не_задан_, КПП=%', KPP;
    END IF; -- IF INN, KPP
ELSE -- Работник найден. Если у Работника не заполнен EАдрес, заносим email из заказа
    IF emp."ЕАдрес" IS NULL THEN
        SELECT fvalue INTO email FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Контактный Email';
        UPDATE "Работники" SET "ЕАдрес" = email WHERE bx_buyer_id = buyer_id;
    END IF;
END IF; -- Работник не найден

RAISE NOTICE 'КодРаботника=%, Код=%', emp."КодРаботника", emp."Код";
RETURN emp;
end

$function$;

ALTER FUNCTION arc_energo.get_emp(integer, integer)
    OWNER TO arc_energo;

