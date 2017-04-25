-- Function: fn_insertbill(numeric, integer, integer, integer, boolean)

-- DROP FUNCTION fn_insertbill(numeric, integer, integer, integer, boolean);

CREATE OR REPLACE FUNCTION fn_insertbill(
    sum numeric,
    bx_order integer,
    acode integer,
    aempcode integer,
    flgowen boolean)
  RETURNS record AS
$BODY$ DECLARE
  ret_bill RECORD;
  BuyerComment VARCHAR = '';
  DeliveryMode VARCHAR;
  Delivery VARCHAR;
  PaymentType VARCHAR;
  DeliveryService VARCHAR;
  BillInfo VARCHAR = 'Автосчёт' ; -- инфо
 -- Дополнительно
  -- ExtraInfo VARCHAR = ' Отгрузка со склада после поступления денег на расчетный счет.'; -- пока только так
  ExtraInfo VARCHAR = ' после поступления денег на расчетный счет.'; -- пока только так
  exInfo_truncated VARCHAR;
  inet_bill_owner integer;
  Max_ExtraInfo CONSTANT INTEGER := 250;
  Max_BillInfo CONSTANT INTEGER := 500;
  loc_bill_no INTEGER;
  loc_OrderProcessingTime VARCHAR;
  loc_DeliveryPayer VARCHAR := '';
  PaymentGuarantee VARCHAR;
  ourFirm VARCHAR;
  locVAT NUMERIC;
  locDealerFlag BOOLEAN;
BEGIN
    SELECT fvalue INTO PaymentGuarantee FROM bx_order_feature WHERE "bx_order_Номер" = bx_order AND fname = 'Гарантия оплаты дилером';
    IF found THEN BillInfo := BillInfo || ', ' ||PaymentGuarantee; END IF;
    SELECT fvalue INTO BuyerComment FROM bx_order_feature WHERE "bx_order_Номер" = bx_order AND fname = 'Комментарии покупателя';
    IF found THEN BillInfo := BillInfo || ', Покупатель: ' ||BuyerComment; END IF;
    /** 2016-09-30 Арутюн Гараханян: 
       когда создается автосчет в строке Инфо появляется куча информации, которая в целом не нужна. можно ее туда не помещать, 
       только то, что клиент пишет в графе "комментарий заказчика"
    SELECT fvalue INTO PaymentType FROM bx_order_feature WHERE "bx_order_Номер" = bx_order AND fname = 'Метод оплаты';
    IF found THEN BillInfo := BillInfo || ' Метод оплаты:' || PaymentType; END IF;
    SELECT fvalue INTO DeliveryService FROM bx_order_feature WHERE "bx_order_Номер" = bx_order AND fname = 'Название службы доставки';
    IF found THEN BillInfo := BillInfo || ' Служба доставки:' || DeliveryService; END IF;
    **/

    SELECT fvalue INTO DeliveryMode FROM bx_order_feature WHERE "bx_order_Номер" = bx_order AND fname = 'Способ доставки';

    -- SELECT Order_ProcessingTime(... args ...) INTO loc_OrderProcessingTime;
    IF DeliveryMode = 'Самовывоз' THEN 
       Delivery := 'Самовывоз'; 
       DeliveryMode = NULL; -- Важно! для формирования счёт-факса
       /** 2017-04-19 ВВ для автосчетов отключаем **/
       ExtraInfo := ' Отгрузка со склада' || ExtraInfo;
       /**/
       loc_OrderProcessingTime := '!Со склада';
    ELSE
       Delivery := 'Отправка';
       loc_OrderProcessingTime := '1...3 рабочих дня'; 
        -- TODO заполняем Дополнительно
       /** 2017-04-19 ВВ для автосчетов отключаем **/
       ExtraInfo := ' Срок поставки ' || loc_OrderProcessingTime || ExtraInfo 
                    ||  ' Доставка продукции компанией ''' || DeliveryMode || '''.' 
                    ||' Оплата доставки при получении.';
       /**/
       -- ExtraInfo := 'Доставка продукции компанией ''' || DeliveryMode || '''. Оплата доставки при получении.';
       loc_DeliveryPayer := 'Они';
    END IF;
    
    inet_bill_owner := get_bill_owner_by_entcode(aCode);
    -- если не назначен заместитель ? Арутюн
    inet_bill_owner := COALESCE(inet_bill_owner, 38);
 
    loc_bill_no := fn_GetNewBillNo(inet_bill_owner);
    ourFirm := getFirm(acode, flgOwen);
    PERFORM 1 FROM "vwДилеры" WHERE "Код" = acode;
    locDealerFlag := FOUND;

    WITH inserted AS (
        INSERT INTO "Счета"
            ("Код", "фирма", "Хозяин", "№ счета", "предок", "Дата счета", "Сумма", "Интернет", "ИнтернетЗаказ", "КодРаботника", "инфо", "Дополнительно", "Отгрузка", "ОтгрузкаКем", "Срок", "ОтгрузкаОплата", "Дилерский") 
        VALUES (acode, ourFirm, inet_bill_owner, loc_bill_no, loc_bill_no, CURRENT_DATE, sum, 't', bx_order, aEmpCode,
                rtrim(rpad(BillInfo, Max_BillInfo)),
                rtrim(rpad(ExtraInfo, Max_ExtraInfo)),
                Delivery, DeliveryMode, loc_OrderProcessingTime, loc_DeliveryPayer, locDealerFlag)
    RETURNING * 
    )
    SELECT * INTO ret_bill FROM inserted;

    locVAT := getVAT(acode);
    IF locVAT IS NOT NULL THEN
       UPDATE "Счета" SET "ставкаНДС" = locVAT WHERE "№ счета" = ret_bill."№ счета";
       ret_bill."ставкаНДС" := locVAT;
    END IF; -- locVAT

    RETURN ret_bill;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_insertbill(numeric, integer, integer, integer, boolean)
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
