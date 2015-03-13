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
    Buyer RECORD;
    FirmCode INTEGER;
begin
  SELECT "КодРаботника", "Код" into emp from "Работники" where bx_buyer_id = buyer_id;
  IF not found THEN -- (emp is null) THEN -- Работник не найден, создаём
    --
    RAISE NOTICE 'Работник не найден, создаём. buyer_id=%', buyer_id;
    SELECT * INTO Buyer FROM devmod.crosstab('SELECT  "bx_order_Номер", fname, fvalue FROM bx_order_feature
                                            WHERE "bx_order_Номер" = ' || bx_order_id || 
   	' AND fname IN ( ''Адрес доставки'', ''Грузополучатель'', ''Индекс'', ''ИНН'', ''Контактное лицо'', ''Контактный Email'', ''КПП'' ) ORDER BY fname') 
    AS bx_order_feature("bx_order_Номер" INTEGER, delivery_address varchar, firm_name varchar, zip_code VARCHAR, INN varchar, person VARCHAR, email VARCHAR, KPP varchar);
    IF (Buyer.inn IS NOT NULL) AND (Buyer.kpp IS NOT NULL) THEN -- юр. лицо
        --
        RAISE NOTICE 'Юр. лицо, ИНН=%, КПП=%', Buyer.inn, Buyer.kpp;
	    SELECT * INTO Firm FROM "Предприятия" WHERE "ИНН" = Buyer.inn AND "КПП" = Buyer.kpp;
	    IF NOT FOUND THEN -- TODO создание предприятия
	       RAISE NOTICE 'Создание предприятия Предприятие=%, ИНН=%, КПП=%', Buyer.firm_name, Buyer.inn, Buyer.kpp;
	       INSERT INTO "Предприятия"("Предприятие", "ИНН", "КПП") VALUES (Buyer.firm_name, Buyer.inn, Buyer.kpp);
	    END IF;
    ELSIF (Buyer.inn IS NULL) AND (Buyer.kpp IS NULL) THEN -- физ. лицо
        RAISE NOTICE 'Физ. лицо';
        FirmCode := 223719;
    ELSIF (Buyer.inn IS NULL) OR (Buyer.kpp IS NULL) THEN -- юр. лицо, неполная информация
        RAISE NOTICE 'Юр. лицо, неполная информация ИНН=%, КПП=%', coalesce(Buyer.inn, 'не определён'), coalesce(Buyer.kpp, 'не определён');
    END IF;

    WITH inserted AS (
       insert INTO "Работники" ("КодРаботника", "Код", bx_buyer_id, "Дата", "ФИО", "ЕАдрес") values ((SELECT MAX("КодРаботника")+1 FROM "Работники"), FirmCode, buyer_id, now(), Buyer.person, Buyer.email) RETURNING "КодРаботника", "Код"
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
