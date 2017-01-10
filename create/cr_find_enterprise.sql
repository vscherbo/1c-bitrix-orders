-- Function: fn_find_enterprise(character varying, character varying)

-- DROP FUNCTION fn_find_enterprise(character varying, character varying);

CREATE OR REPLACE FUNCTION fn_find_enterprise(
    inn character varying,
    kpp character varying)
  RETURNS record AS
$BODY$
declare
    Firm RECORD;
    chk_KPP VARCHAR;
    len_inn INTEGER;
begin
    IF INN IS NULL THEN RAISE 'fn_find_enterprise: INN is NULL'; END IF;
    IF KPP IS NULL THEN RAISE 'fn_find_enterprise: KPP is NULL'; END IF;
    len_inn := length(INN);
    IF 10 = len_inn THEN
        SELECT * INTO Firm FROM "Предприятия" WHERE "ИНН" = INN AND "КПП" = KPP;
    ELSIF 12 = len_inn THEN
        SELECT * INTO Firm FROM "Предприятия" WHERE "ИНН" = INN;
    ELSE
        RAISE 'Непредвиденная длина ИНН=%, ИНН=% ', len_inn, INN;
    END IF; -- length(INN)
    IF NOT FOUND THEN -- проверка КПП по ИНН
        RAISE NOTICE 'fn_find_enterprise: Предприятие не найдено INN=%, KPP=%', INN, KPP;
        chk_KPP := verify_KPP_by_INN(INN);
        IF chk_KPP <> 'N/A' THEN -- получен ответ с сайте ИТС 1С
            IF chk_KPP <> KPP THEN -- КПП с сайта ИТС 1С отличается от КПП из заказа
               RAISE NOTICE 'fn_find_enterprise: Предприятие найдено в Инете по INN=%, chk_KPP=%', INN, chk_KPP;
               SELECT * INTO Firm FROM "Предприятия" WHERE "ИНН" = INN AND "КПП" = chk_KPP;
               IF FOUND THEN -- TODO IF FOUND -> исправить КПП на сайте?
                   RAISE NOTICE 'fn_find_enterprise: Предприятие найдено в БД по INN=%, chk_KPP=%', INN, chk_KPP;
               END IF;
            ELSE
               RAISE NOTICE 'fn_find_enterprise: получен тот же КПП с сайта ИТС 1С по INN=%, KPP=%', INN, chk_KPP;
            END IF; -- КПП с сайта ИТС 1С отличается от КПП из заказа
        ELSE
           RAISE NOTICE 'fn_find_enterprise: Нет ответа с сайта ИТС 1С по INN=%, KPP=%', INN, chk_KPP;
        END IF; -- получен ответ с сайта ИТС 1С
    END IF; -- if found
    RETURN Firm;
end
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_find_enterprise(character varying, character varying)
  OWNER TO arc_energo;
