-- Function: fn_insertbill(numeric, integer, integer, integer)

-- DROP FUNCTION fn_insertbill(numeric, integer, integer, integer);

CREATE OR REPLACE FUNCTION fn_insertbill(
    sum numeric,
    bx_order integer,
    afirmcode integer,
    aempcode integer)
  RETURNS record AS
$BODY$ DECLARE
  ret_bill RECORD;
  BuyerComment VARCHAR;
  DeliveryMode VARCHAR;
  Delivery VARCHAR;
  PaymentType VARCHAR;
  DeliveryService VARCHAR;
  ExtraInfo VARCHAR;
  exInfo_truncated VARCHAR;
-- Хозяин=38 - Гараханян
-- Хозяин=77 - Бондаренко
--  inet_bill_owner integer = 77;
  Max_ExtraInfo CONSTANT INTEGER := 250;
  loc_OrderProcessingTime varchar;
BEGIN
    SELECT fvalue INTO BuyerComment FROM bx_order_feature WHERE "bx_order_Номер" = bx_order AND fname = 'Комментарии покупателя';
    IF found THEN ExtraInfo := BuyerComment; END IF;
    SELECT fvalue INTO PaymentType FROM bx_order_feature WHERE "bx_order_Номер" = bx_order AND fname = 'Метод оплаты';
    IF found THEN ExtraInfo := ExtraInfo || ' Метод оплаты:' || PaymentType; END IF;
    SELECT fvalue INTO DeliveryService FROM bx_order_feature WHERE "bx_order_Номер" = bx_order AND fname = 'Название службы доставки';
    IF found THEN ExtraInfo := ExtraInfo || ' Название службы доставки:' || DeliveryService; END IF;
    IF length(ExtraInfo) > Max_ExtraInfo  THEN
       exInfo_truncated = rpad(ExtraInfo, Max_ExtraInfo);
       RAISE NOTICE 'ExtraInfo % longer than %, truncated to=%', ExtraInfo,Max_ExtraInfo,exInfo_truncated;
    END IF;

    SELECT fvalue INTO DeliveryMode FROM bx_order_feature WHERE "bx_order_Номер" = bx_order AND fname = 'Способ доставки';

    IF DeliveryMode = 'Самовывоз' THEN Delivery := 'Самовывоз'; ELSE Delivery := 'Отправка'; END IF;
    
    SELECT Order_ProcessingTime() INTO loc_OrderProcessingTime;
    WITH inserted AS (
        INSERT INTO "Счета"
            ("Код", "фирма", "Хозяин", "№ счета", "Дата счета", "Сумма", "Интернет", "ИнтернетЗаказ", "КодРаботника", "Статус", "инфо", "Дополнительно", "Отгрузка", "ОтгрузкаКем", "Срок") 
        VALUES (aFirmCode, 'АРКОМ', get_owner_by_firm_code(aFirmCode), fn_GetNewBillNo(inet_bill_owner), CURRENT_DATE, sum, 't', bx_order, aEmpCode, 0, 'Автосчёт на заказ с сайта', exInfo_truncated, Delivery, DeliveryMode, loc_OrderProcessingTime)
    RETURNING * 
    )
    SELECT * INTO ret_bill FROM inserted;

    RETURN ret_bill;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_insertbill(numeric, integer, integer, integer)
  OWNER TO arc_energo;
COMMENT ON FUNCTION fn_insertbill(numeric, integer, integer, integer) IS 'С сайта ''Способ доставки''
1    Самовывоз
9    Почта России
5    Междугородний автотранспорт, Почта, Экспресс-почта
7    Транспортная компания (ж/д, авиа, авто)
2    Курьер по СПб
8    Курьерская служба
6    Иное
';
