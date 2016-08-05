-- Function: fn_insertbill(numeric, integer, integer, integer, character varying, character varying)

-- DROP FUNCTION fn_insertbill(numeric, integer, integer, integer, character varying, character varying);

CREATE OR REPLACE FUNCTION fn_insertbill(
    sum numeric,
    bx_order integer,
    acode integer,
    aempcode integer,
    ourfirm character varying)
  RETURNS record AS
$BODY$ DECLARE
  ret_bill RECORD;
  BuyerComment VARCHAR = '';
  DeliveryMode VARCHAR;
  Delivery VARCHAR;
  PaymentType VARCHAR;
  DeliveryService VARCHAR;
  BillInfo VARCHAR = 'Автосчёт, ' ; -- инфо
 -- Дополнительно
  ExtraInfo VARCHAR = ' Отгрузка со склада после поступления денег на расчетный счет.'; -- пока только так
  exInfo_truncated VARCHAR;
  inet_bill_owner integer;
  Max_ExtraInfo CONSTANT INTEGER := 250;
  Max_BillInfo CONSTANT INTEGER := 500;
  bill_no INTEGER;
  loc_OrderProcessingTime VARCHAR;
BEGIN
    SELECT fvalue INTO BuyerComment FROM bx_order_feature WHERE "bx_order_Номер" = bx_order AND fname = 'Комментарии покупателя';
    IF found THEN BillInfo := BillInfo || 'Покупатель: ' ||BuyerComment; END IF;
    SELECT fvalue INTO PaymentType FROM bx_order_feature WHERE "bx_order_Номер" = bx_order AND fname = 'Метод оплаты';
    IF found THEN BillInfo := BillInfo || ' Метод оплаты:' || PaymentType; END IF;
    SELECT fvalue INTO DeliveryService FROM bx_order_feature WHERE "bx_order_Номер" = bx_order AND fname = 'Название службы доставки';
    IF found THEN BillInfo := BillInfo || ' Служба доставки:' || DeliveryService; END IF;


    -- TODO заполняем Дополнительно
    ExtraInfo := Extranfo ||  " Оплата доставки при получении.";

    /*
    IF length(ExtraInfo) > Max_ExtraInfo  THEN
       exInfo_truncated = rpad(ExtraInfo, Max_ExtraInfo);
       RAISE NOTICE 'ExtraInfo % longer than %, truncated.', ExtraInfo,Max_ExtraInfo;
    ELSE
       exInfo_truncated = ExtraInfo;
    END IF;
    RAISE NOTICE 'exInfo_truncated=%', exInfo_truncated;
    */

    SELECT fvalue INTO DeliveryMode FROM bx_order_feature WHERE "bx_order_Номер" = bx_order AND fname = 'Способ доставки';

    IF DeliveryMode = 'Самовывоз' THEN 
       Delivery := 'Самовывоз'; 
       DeliveryMode = NULL; -- Важно! для формирования счёт-факса
       loc_OrderProcessingTime := '!Со склада';
    ELSE
       Delivery := 'Отправка';
       loc_OrderProcessingTime := '1...3 рабочих дня'; 
    END IF;
    
    -- SELECT Order_ProcessingTime() INTO loc_OrderProcessingTime;
    inet_bill_owner := get_bill_owner_by_entcode(aCode);
    bill_no := fn_GetNewBillNo(inet_bill_owner);
    WITH inserted AS (
        INSERT INTO "Счета"
            ("Код", "фирма", "Хозяин", "№ счета", "предок", "Дата счета", "Сумма", "Интернет", "ИнтернетЗаказ", "КодРаботника", "Статус", "инфо", "Дополнительно", "Отгрузка", "ОтгрузкаКем", "Срок", "ОтгрузкаОплата") 
        VALUES (acode, ourFirm, inet_bill_owner, bill_no, bill_no, CURRENT_DATE, sum, 't', bx_order, aEmpCode, 0, 
                rpad(BillInfo, Max_BillInfo), 
                rpad(ExtraInfo, Max_ExtraInfo), 
                Delivery, DeliveryMode, loc_OrderProcessingTime, "Они")
    RETURNING * 
    )
    SELECT * INTO ret_bill FROM inserted;

    RETURN ret_bill;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_insertbill(numeric, integer, integer, integer, character varying)
  OWNER TO arc_energo;
COMMENT ON FUNCTION fn_insertbill(numeric, integer, integer, integer, character varying) IS 'С сайта ''Способ доставки''
1    Самовывоз
9    Почта России
5    Междугородний автотранспорт, Почта, Экспресс-почта
7    Транспортная компания (ж/д, авиа, авто)
2    Курьер по СПб
8    Курьерская служба
6    Иное
';
