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
    Buyer RECORD;
    FirmCode INTEGER;
    FirmName VARCHAR;
    Consignee VARCHAR;
    DeliveryAddress VARCHAR;
    PersonLocation VARCHAR;
    Bank VARCHAR;
    BIK VARCHAR;
    R_account VARCHAR;
    R_account_complex VARCHAR;
    K_account VARCHAR;
    LegalAddress VARCHAR;
begin
  SELECT "КодРаботника", "Код" into emp from "Работники" where bx_buyer_id = buyer_id;
  IF not found THEN -- (emp is null) THEN -- Работник не найден, создаём
    -- 
    RAISE NOTICE 'Работник не найден, создаём. buyer_id=%', buyer_id;
    SELECT fvalue INTO INN FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'ИНН';
    SELECT fvalue INTO KPP FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'КПП';
    
    SELECT * INTO Buyer FROM devmod.crosstab('SELECT  "bx_order_Номер", fname, fvalue FROM bx_order_feature
                                            WHERE "bx_order_Номер" = ' || bx_order_id || 
   	' AND fname IN (
                    ''Контактное лицо'', 
                    ''Контактный Email'', 
                    ''Контактный телефон'')
                    ORDER BY fname') 
    AS bx_order_feature("bx_order_Номер" INTEGER, 
                    person VARCHAR, 
                    email VARCHAR, 
                    phone VARCHAR);
    SELECT fvalue INTO DeliveryAddress FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Адрес доставки';
    IF not found THEN DeliveryAddress := ''; END IF;
    
    IF (INN IS NOT NULL) AND (KPP IS NOT NULL) THEN -- юр. лицо
        --
        RAISE NOTICE 'Юр. лицо, ИНН=%, КПП=%', INN, KPP;
	    SELECT * INTO Firm FROM "Предприятия" WHERE "ИНН" = INN AND "КПП" = KPP;
	    IF NOT FOUND THEN -- TODO создание предприятия
	        SELECT fvalue INTO Consignee FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Грузополучатель';
	        SELECT fvalue INTO FirmName FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Название компании';
            SELECT fvalue INTO Bank FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Банк';
            SELECT fvalue INTO BIK FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'БИК';
            SELECT fvalue INTO R_account FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Расчетный счет';
            SELECT fvalue INTO K_account FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'КорСчет';
            SELECT fvalue INTO LegalAddress FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Юридический адрес';
	        RAISE NOTICE 'Создание предприятия Предприятие=%, ИНН=%, КПП=%', FirmName, INN, KPP;
	        R_account_complex := R_account || ' в БИК:' || BIK || ', ' || Bank ;
            WITH inserted AS (   
                INSERT INTO "Предприятия"("Предприятие", "ИНН", "КПП", "Грузополучатель", "Адрес", "Расчетный счет", "Корсчет", "ЮрАдрес") 
                VALUES (FirmName, INN, KPP, Consignee, DeliveryAddress, R_account_complex, K_account, LegalAddress) 
                RETURNING "Код"
            )
            SELECT inserted."Код" INTO FirmCode FROM inserted;
        ELSE
            FirmCode := Firm."Код";
	    END IF;
    ELSIF (INN IS NULL) AND (KPP IS NULL) THEN -- физ. лицо
        RAISE NOTICE 'Физ. лицо';
        FirmCode := 223719;
        SELECT fvalue INTO PersonLocation FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Местоположение';
        IF found THEN DeliveryAddress := PersonLocation || ', ' || DeliveryAddress; END IF;
    ELSIF (INN IS NULL) OR (KPP IS NULL) THEN -- юр. лицо, неполная информация
        RAISE NOTICE 'Юр. лицо, неполная информация ИНН=%, КПП=%', coalesce(INN, 'не определён'), coalesce(KPP, 'не определён');
    END IF;

    WITH inserted AS (
       insert INTO "Работники" ("КодРаботника", "Код", bx_buyer_id, 
                                "Дата", "ФИО", "Телефон", "ЕАдрес", "Примечание")  
                                values ((SELECT MAX("КодРаботника")+1 FROM "Работники"), FirmCode, buyer_id, 
                                now(), Buyer.person, Buyer.phone, Buyer.email, DeliveryAddress) 
                                RETURNING "КодРаботника", "Код"
    )
    SELECT inserted."КодРаботника", inserted."Код" INTO emp FROM inserted;
    --
    RAISE NOTICE 'Создан работник';
  END IF; -- Работник не найден
  RAISE NOTICE 'КодРаботника=%, Код=%', emp."КодРаботника", emp."Код";
  RETURN emp;
end
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_getempcode(integer, integer)
  OWNER TO arc_energo;
