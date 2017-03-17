-- Function: fn_find_enterprise(character varying, character varying)

-- DROP FUNCTION fn_find_enterprise(character varying, character varying);

CREATE OR REPLACE FUNCTION fn_find_enterprise(
    arg_order_id INTEGER, 
    INN character varying,
    KPP character varying)
  RETURNS record AS
$BODY$
declare
    Firm RECORD;
    chk_KPP VARCHAR;
    len_inn INTEGER;
    FirmCode INTEGER;
    do_verify BOOLEAN := FALSE;
begin
len_inn := length(INN);
IF 10 = len_inn THEN
    IF KPP IS NULL THEN RAISE NOTICE 'fn_find_enterprise: KPP is NULL';
        do_verify := TRUE;
    ELSE
        SELECT * INTO Firm FROM "Предприятия" WHERE "ИНН" = INN AND "КПП" = KPP;
        IF NOT FOUND THEN -- проверка КПП по ИНН
            RAISE NOTICE 'fn_find_enterprise: Предприятие не найдено INN=%, KPP=%', INN, KPP;
            do_verify := TRUE;
        END IF;
    END IF;

    IF do_verify THEN
        chk_KPP := verify_KPP_by_INN(INN);
        IF KPP = chk_KPP OR chk_KPP = 'N/A' THEN -- КПП с сайта 1С равен КПП из заказа ИЛИ нет ответа 1С
            RAISE NOTICE 'fn_find_enterprise: получен КПП с сайта ИТС 1С по INN=%, KPP=%', INN, chk_KPP;
            SELECT * INTO Firm FROM "Предприятия" WHERE "ИНН" = INN;
            /** IF FOUND THEN -- TODO IF FOUND -> исправить КПП в базе?
            
            END IF; **/
        ELSE
            RAISE NOTICE 'fn_find_enterprise: Предприятие найдено в Инете по INN=%, с другим chk_KPP=%', INN, chk_KPP;
            SELECT * INTO Firm FROM "Предприятия" WHERE "ИНН" = INN AND "КПП" = chk_KPP;
            /** IF FOUND THEN -- TODO IF FOUND -> исправить КПП на сайте?
               RAISE NOTICE 'fn_find_enterprise: Предприятие найдено в БД по INN=%, chk_KPP=%', INN, chk_KPP;
            END IF; **/
        END IF; -- KPP = chk_KPP
        
        IF Firm IS NULL THEN
            FirmCode := create_firm(arg_order_id, INN, KPP);
            SELECT * INTO Firm FROM "Предприятия" WHERE "Код" = FirmCode ;
        END IF; -- Firm IS NULL
    END IF; -- do_verify

ELSIF 12 = len_inn THEN
    SELECT * INTO Firm FROM "Предприятия" WHERE "ИНН" = INN;
    IF NOT FOUND THEN
        FirmCode := create_firm(arg_order_id, INN, KPP);
        SELECT * INTO Firm FROM "Предприятия" WHERE "Код" = FirmCode ;
    END IF; -- создали ненайденного ИП
ELSE
    RAISE NOTICE 'Непредвиденная длина ИНН=%, ИНН=% ', len_inn, INN;
END IF; -- length(INN)

RETURN Firm;
end
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_find_enterprise(character varying, character varying)
  OWNER TO arc_energo;
