-- FUNCTION: arc_energo.create_firm(integer, character varying, character varying)

-- DROP FUNCTION arc_energo.create_firm(integer, character varying, character varying);

CREATE OR REPLACE FUNCTION arc_energo.create_firm(
    bx_order_id integer,
    arg_INN character varying,
    KPP character varying)
    RETURNS integer
    LANGUAGE 'plpgsql'
    COST 100.0
    VOLATILE NOT LEAKPROOF 
AS $function$

declare
    FirmCode INTEGER;
    ZipCode VARCHAR;
    bxFirmName VARCHAR;
    FirmName VARCHAR; -- Upper, no quotes
    FirmNameRE VARCHAR;
    Consignee VARCHAR;
    DeliveryAddress VARCHAR;
    Bank VARCHAR;
    BIK VARCHAR;
    R_account VARCHAR;
    R_account_complex VARCHAR;
    K_account VARCHAR;
    LegalAddress VARCHAR;
    Fax VARCHAR;
    loc_legal_name VARCHAR[];
BEGIN
SELECT fvalue INTO Consignee FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Грузополучатель';

SELECT fvalue INTO bxFirmName FROM bx_order_feature bof WHERE "bx_order_Номер" = bx_order_id AND bof.fname = 'Название компании';

FirmName := COALESCE(bxFirmName, 'не задано Название_компании');
FirmNameRE := upper(regexp_replace(FirmName, '["''«»“]*', '', 'g'));
loc_legal_name := regexp_matches(FirmNameRE,
                        '(.*)(ГУП|МУП|ООО|ПАО|ОАО|ЗАО|\mАО|АООТ|АОЗТ|ТОО|Общество с ограниченной ответственностью)(.*)', 'i');
FirmNameRE := COALESCE(TRIM(loc_legal_name[1] || loc_legal_name[3]) || ' ' || loc_legal_name[2]
, FirmNameRE); -- если разобрать не удалось, то просто UPPERCASE без кавычек

FirmName := regexp_replace(FirmName, 'Общество с ограниченной ответственностью', 'ООО', 'i');
FirmName := regexp_replace(FirmName, 'Индивидуальный Предприниматель', 'ИП', 'i');

SELECT fvalue INTO Bank FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Банк';
SELECT fvalue INTO BIK FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'БИК';
BIK := regexp_replace(BIK, '[^0-9]*', '', 'g');
SELECT fvalue INTO R_account FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Расчетный счет';
SELECT fvalue INTO K_account FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'КорСчет';
SELECT fvalue INTO LegalAddress FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Юридический адрес';
SELECT fvalue INTO DeliveryAddress FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Адрес доставки';
IF not found THEN DeliveryAddress := '';
ELSE DeliveryAddress := substring(DeliveryAddress from 1 for 255);
END IF;
-- удаляем не-цифры из индекса
SELECT digits_only(fvalue) INTO ZipCode FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Индекс';
IF not found THEN ZipCode := ''; END IF;
SELECT fvalue INTO Fax FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_id AND fname = 'Факс';
R_account_complex := R_account || ' ' || Bank ;
R_account_complex := substring(R_account_complex from 1 for 100);
LegalAddress := substring(LegalAddress from 1 for 250);
-- DEBUG
/** Прерывается исполнение, если есть NULL. TODO quote_nullable
RAISE NOTICE 'FirmNameRE=(%)%, FirmName=(%)%, ZipCode=(%)%, arg_INN=(%)%, KPP=(%)%, Consignee=(%)%, DeliveryAddress=(%)%, R_account_complex=(%)%, K_account=(%)%, LegalAddress=(%)%, Fax=(%)%',
char_length(FirmNameRE),
FirmNameRE,
char_length(FirmName),
FirmName,
char_length(ZipCode),
ZipCode,
char_length(arg_INN),
arg_INN,
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
**/
WITH inserted AS (   
    INSERT INTO "Предприятия"("Предприятие", "ЮрНазвание", "Индекс", "ИНН", "КПП", "Грузополучатель", "Адрес", "Расчетный счет", "Корсчет", "ЮрАдрес", "Факс", "Создатель") 
    VALUES (FirmNameRE, FirmName, ZipCode, arg_INN, KPP, Consignee, DeliveryAddress, R_account_complex, K_account, LegalAddress, Fax, 1
) 
    RETURNING "Код"
)
SELECT inserted."Код" INTO FirmCode FROM inserted;
RAISE NOTICE 'Создано предприятие Код=%, ЮрНазвание=[%], Предприятие=[%], ИНН=%, КПП=%', FirmCode, FirmName, FirmNameRE, arg_INN, quote_nullable(KPP);

if no_vat(arg_INN) then
    insert into "СоотношениеСтатуса" ("КодПредприятия", "СтатусПредприятия") values(FirmCode, 12);
    RAISE NOTICE 'NO_VAT предприятие Код=%', FirmCode;
end if;

RETURN FirmCode;
END

$function$;

ALTER FUNCTION arc_energo.create_firm(integer, character varying, character varying)
    OWNER TO arc_energo;

