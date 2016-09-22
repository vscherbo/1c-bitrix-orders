-- Function: fn_getempcode(integer, integer)

-- DROP FUNCTION fn_getempcode(integer, integer);

CREATE OR REPLACE FUNCTION fn_getempcode(
    buyer_id integer,
    bx_order_id integer)
  RETURNS record AS
$BODY$
declare
    emp RECORD;
    Firm RECORD;
    INN VARCHAR;
    KPP VARCHAR;
    FirmCode INTEGER;
    ZipCode VARCHAR;
    FirmName VARCHAR;
    FirmNameRE VARCHAR;
    Consignee VARCHAR;
    DeliveryAddress VARCHAR;
    PersonLocation VARCHAR;
    Bank VARCHAR;
    BIK VARCHAR;
    R_account VARCHAR;
    R_account_complex VARCHAR;
    K_account VARCHAR;
    LegalAddress VARCHAR;
    email VARCHAR;
    email1 VARCHAR;
    Fax VARCHAR;
    person VARCHAR;
    phone VARCHAR;
    EmpNotice VARCHAR;
    chk_KPP VARCHAR;
begin
  SELECT fvalue INTO email FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Контактный Email';
  SELECT "КодРаботника", "Код", "ЕАдрес" into emp from "Работники" where bx_buyer_id = buyer_id;
  IF not found THEN -- (emp is null) THEN -- Работник не найден, создаём
    -- 
    RAISE NOTICE 'Работник не найден, создаём. buyer_id=%', buyer_id;
    SELECT fvalue INTO INN FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'ИНН';
    INN := regexp_replace(INN, '[^0-9]*', '', 'g');
    SELECT fvalue INTO KPP FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'КПП';
    KPP := regexp_replace(KPP, '[^0-9]*', '', 'g');
    
    SELECT fvalue INTO person FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Контактное лицо';
    IF NOT FOUND THEN person := 'н/д'; END IF;
    SELECT fvalue INTO phone  FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Контактный телефон';
    IF NOT FOUND THEN phone := 'н/д'; END IF;

    SELECT fvalue INTO ZipCode FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Индекс';
    IF not found THEN ZipCode := ''; END IF;

    SELECT fvalue INTO DeliveryAddress FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Адрес доставки';
    
    IF (INN IS NOT NULL) -- AND (KPP IS NOT NULL) THEN -- юр. лицо
        KPP := COALESCE(KPP, '_не_задан_');
        RAISE NOTICE 'Юр. лицо, ИНН=%, КПП=%', INN, KPP;
        -- !!! found -> DeliveryAddress
        IF not found THEN DeliveryAddress := ''; 
        ELSE DeliveryAddress := substring(DeliveryAddress from 1 for 100);
        END IF;

        Firm := fn_find_enterprise(INN, KPP);
	    IF Firm IS NULL THEN -- создание предприятия
            SELECT fvalue INTO Consignee FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Грузополучатель';
            -- SELECT fvalue INTO FirmName FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Название компании';
            SELECT fvalue
                , TRIM(lname[1] || lname[3]) || ' ' || lname[2]
            INTO FirmName, FirmNameRE
            FROM (SELECT fvalue 
                , regexp_matches(
                      regexp_replace(fvalue, '["''«»“]*', '', 'g')
                      , '(.*)(ООО|ПАО|ОАО|ЗАО|\mАО|АООТ|АОЗТ|ТОО)(.*)') AS lname
                FROM bx_order_feature bof WHERE "bx_order_Номер" = bx_order_id AND bof.fname = 'Название компании') as leg_name;

            SELECT fvalue INTO Bank FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Банк';
            SELECT fvalue INTO BIK FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'БИК';
            BIK := regexp_replace(BIK, '[^0-9]*', '', 'g');
            SELECT fvalue INTO R_account FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Расчетный счет';
            SELECT fvalue INTO K_account FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'КорСчет';
            SELECT fvalue INTO LegalAddress FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Юридический адрес';
            -- SELECT fvalue INTO ZipCode FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Индекс';
            SELECT fvalue INTO Fax FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Факс';
            -- R_account_complex := R_account || ' в БИК:' || BIK || ', ' || Bank ;
            R_account_complex := R_account || ' ' || Bank ;
            R_account_complex := substring(R_account_complex from 1 for 100);
            LegalAddress := substring(LegalAddress from 1 for 250);
            -- DEBUG
            RAISE NOTICE 'FirmNameRE=(%)%, FirmName=(%)%, ZipCode=(%)%, INN=(%)%, KPP=(%)%, Consignee=(%)%, DeliveryAddress=(%)%, R_account_complex=(%)%, K_account=(%)%, LegalAddress=(%)%, Fax=(%)%',
char_length(FirmNameRE),
FirmNameRE,
char_length(FirmName),
FirmName,
char_length(ZipCode),
ZipCode,
char_length(INN),
INN,
char_length(KPP),
KPP,
char_length(Consignee),
Consignee,
char_length(DeliveryAddress),
DeliveryAddress,
char_length(R_account_complex),
R_account_complex,
char_length(K_account),
K_account,
char_length(LegalAddress),
LegalAddress,
char_length(Fax),
Fax
;
-- END of DEBUG

            WITH inserted AS (   
                INSERT INTO "Предприятия"("Предприятие", "ЮрНазвание", "Индекс", "ИНН", "КПП", "Грузополучатель", "Адрес", "Расчетный счет", "Корсчет", "ЮрАдрес", "Факс") 
                VALUES (FirmNameRE, FirmName, ZipCode, INN, KPP, Consignee, DeliveryAddress, R_account_complex, K_account, LegalAddress, Fax) 
                RETURNING "Код"
            )
            SELECT inserted."Код" INTO FirmCode FROM inserted;
            RAISE NOTICE 'Создано предприятие Код=%, Предприятие=%, ИНН=%, КПП=%', FirmCode, FirmName, INN, KPP;
        ELSE
            FirmCode := Firm."Код";
	    END IF; -- if found
    ELSIF (INN IS NULL) AND (KPP IS NULL) THEN -- физ. лицо
        RAISE NOTICE 'Физ. лицо';
        FirmCode := 223719;
        SELECT fvalue INTO email1 FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'EMail';
        IF 'siteorders@kipspb.ru' <> email1 AND email <> email1 THEN
            email := email1;
            RAISE NOTICE 'заменяем _контактный email_ на EMail';
        END IF;
        if 'н/д' = person THEN person := email; END IF;

        SELECT fvalue INTO PersonLocation FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Местоположение';
        IF NOT found THEN PersonLocation := ''; END IF;
        EmpNotice := SUBSTRING(concat_ws(', ', ZipCode, PersonLocation, DeliveryAddress) from 1 for 255);
    ELSIF (INN IS NULL) AND (KPP IS not NULL) THEN -- юр. лицо, неполная информация
        RAISE NOTICE 'Юр. лицо, неполная информация ИНН=_не_задан_, КПП=%', KPP;
    END IF;

    WITH inserted AS (
       insert INTO "Работники" ("КодРаботника", "Код", bx_buyer_id, 
                                "Дата", "ФИО", "Телефон", "ЕАдрес", "Примечание")  
                                values ((SELECT MAX("КодРаботника")+1 FROM "Работники"), FirmCode, buyer_id, 
                                now(), person, phone, email, EmpNotice) 
                                RETURNING "КодРаботника", "Код"
    )
    SELECT inserted."КодРаботника", inserted."Код" INTO emp FROM inserted;
    --
    RAISE NOTICE 'Создан работник Код=%', emp;
  ELSE -- Работник найден. Если у Работника не заполнен EАдрес, заносим email из заказа
    IF emp."ЕАдрес" IS NULL THEN
       UPDATE "Работники" SET "ЕАдрес" = email WHERE bx_buyer_id = buyer_id;
    END IF;
  END IF; -- Работник не найден
  RAISE NOTICE 'КодРаботника=%, Код=%', emp."КодРаботника", emp."Код";
  RETURN emp;
end
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_getempcode(integer, integer)
  OWNER TO arc_energo;
