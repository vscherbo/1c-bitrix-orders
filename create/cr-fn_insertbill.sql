CREATE OR REPLACE FUNCTION arc_energo.fn_insertbill(arg_createresult integer, sum numeric, bx_order_no integer, acode integer, aempcode integer, flgowen boolean, flg_delivery_qnt boolean)
 RETURNS record
 LANGUAGE plpgsql
AS $function$ DECLARE
  ret_bill RECORD;
  BuyerComment VARCHAR = '';
  DeliveryMode VARCHAR;
  Delivery VARCHAR;
  PaymentType VARCHAR;
  DeliveryService VARCHAR;
  BillInfo VARCHAR = 'Автосчёт' ; -- инфо
 -- Дополнительно
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
locAutobillFlag BOOLEAN;
loc_payment_method varchar;
loc_comment BOOLEAN;
loc_in_stock BOOLEAN;
loc_courier BOOLEAN;
loc_aub_msg text;
loc_no_aub_reason text;
loc_reason_code integer := 100;
BEGIN
    RAISE NOTICE 'start fn_insertbill, arg_createresult=%', arg_createresult;
    loc_in_stock := (1 = arg_createresult); -- всё доступно, для дилера м.б. в т.ч. из идущих 
    SELECT fvalue INTO PaymentGuarantee FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_no AND fname = 'Гарантия оплаты дилером';
    IF found THEN BillInfo := BillInfo || ', ' ||PaymentGuarantee; END IF;
    SELECT fvalue INTO BuyerComment FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_no AND fname = 'Комментарии покупателя';
    IF found THEN BillInfo := BillInfo || ', Покупатель: ' ||BuyerComment; END IF;
    loc_comment := BuyerComment IS NOT NULL;  -- есть комментарий
    RAISE NOTICE 'bx_order_no=%, BuyerComment=%,  loc_comment=%', bx_order_no,  COALESCE(BuyerComment, 'strNULL'), COALESCE(loc_comment::text, 'strNULL');

    SELECT fvalue INTO DeliveryMode FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_no AND fname = 'Способ доставки';
    RAISE NOTICE 'bx_order_no=%, DeliveryMode=%', bx_order_no,  COALESCE(DeliveryMode, 'strNULL');
    loc_courier := (position('урьер' in DeliveryMode)>0); -- доставка курьером или курьерской службой
    RAISE NOTICE 'bx_order_no=%, DeliveryMode=%,  loc_courier=%', bx_order_no,  COALESCE(DeliveryMode, 'strNULL'), COALESCE(loc_courier::text, 'strNULL');

    SELECT fvalue INTO loc_payment_method FROM bx_order_feature WHERE "bx_order_Номер" = bx_order_no AND fname = 'Метод оплаты ИД';

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
       loc_DeliveryPayer := 'Они';
    END IF;

    PERFORM 1 FROM "vwДилеры" WHERE "Код" = acode;
    locDealerFlag := FOUND;
    /**
    locAutobillFlag := (BuyerComment IS NULL -- без комментария
                        AND 1 = arg_createresult -- всё доступно, м.б. в т.ч. из идущих
                        AND (position('урьер' in DeliveryMode)=0) -- доставка не курьером и не курьерской службой
                        AND NOT flg_delivery_qnt -- нет разбивки срок-количество
                       );
    **/
    locAutobillFlag := loc_in_stock  -- всё доступно
                       AND NOT loc_comment  -- без комментария
                       AND NOT loc_courier  -- НЕ доставка курьером или курьерской службой
                       AND NOT flg_delivery_qnt; -- нет разбивки срок-количество

    RAISE NOTICE 'bx_order_no=%, locDealerFlag=%,  locAutobillFlag=%', bx_order_no, locDealerFlag, locAutobillFlag;
    IF locDealerFlag OR locAutobillFlag THEN -- или дилерский, или возможен автосчёт
        inet_bill_owner := get_bill_owner_by_entcode(aCode);
        IF inet_bill_owner IS NULL THEN
            inet_bill_owner := inetbill_mgr();
            loc_aub_msg := format(E'не удалось выбрать хозяина счёта, вызывали inetbill_mgr=%s', inet_bill_owner);
            RAISE NOTICE '%', loc_aub_msg;
            INSERT INTO aub_log(bx_order_no, mod_id, descr) VALUES(bx_order_no, -1, loc_aub_msg);
        END IF;
    ELSE -- или не дилерский, или невозможен автосчёт
        -- inet_bill_owner := inetbill_mgr();

        loc_no_aub_reason := E'';
        IF loc_in_stock THEN -- всё в наличии, но не можем отправить автосчёт. Протоколируем причину
            inet_bill_owner := 41;
            loc_aub_msg := format(E'Всё в наличии, явно задаём хозяина счёта %s', inet_bill_owner);
            RAISE NOTICE '%', loc_aub_msg;
            INSERT INTO aub_log(bx_order_no, mod_id, descr) VALUES(bx_order_no, -1, loc_aub_msg);
            IF loc_comment THEN
                loc_no_aub_reason := format(E'Заказ с комментарием: %s', BuyerComment);
                loc_reason_code := loc_reason_code + 1;
            END IF;

            IF loc_courier THEN
                loc_no_aub_reason := concat_ws('/', loc_no_aub_reason, format(E'Доставка не для автосчёта: %s', DeliveryMode));
                loc_reason_code := loc_reason_code + 4;
            END IF;

            IF flg_delivery_qnt THEN -- разбивка срок-количество для НЕ-дилера
                inet_bill_owner := inetbill_mgr();
                loc_no_aub_reason := concat_ws('/', loc_no_aub_reason, E'есть разбивка срок-количество');
                loc_reason_code := loc_reason_code + 8;
            END IF;

        ELSE -- не всё в наличии, значит менеджеру-человеку
            inet_bill_owner := inetbill_mgr();
        END IF;
    END IF;
    RAISE NOTICE '% %', loc_no_aub_reason, format(E'автосчёт создан от менеджера %s', inet_bill_owner);
    INSERT INTO aub_log(bx_order_no, mod_id, descr, res_code) VALUES(bx_order_no, -1, loc_no_aub_reason, loc_reason_code);

    loc_bill_no := fn_GetNewBillNo(inet_bill_owner);
    ourFirm := getFirm(acode, flgOwen, loc_payment_method);

    WITH inserted AS (
        INSERT INTO "Счета"
            ("Код", "фирма", "Хозяин", "№ счета", "предок", "Дата счета", "Сумма", "Интернет", "ИнтернетЗаказ", "КодРаботника", "инфо", "Дополнительно", "Отгрузка", "ОтгрузкаКем", "Срок", "ОтгрузкаОплата", "Дилерский", "ставкаНДС") 
        VALUES (acode, ourFirm, inet_bill_owner, loc_bill_no, loc_bill_no, CURRENT_DATE, sum, 't', bx_order_no, aEmpCode,
                rtrim(rpad(BillInfo, Max_BillInfo)),
                rtrim(rpad(ExtraInfo, Max_ExtraInfo)),
                Delivery, DeliveryMode, loc_OrderProcessingTime, loc_DeliveryPayer, locDealerFlag, vat_rate(ourFirm, acode))
    RETURNING * 
    )
    SELECT * INTO ret_bill FROM inserted;
    IF loc_in_stock AND loc_reason_code > 100 THEN -- всё в наличии, но не можем отправить автосчёт. Регистрируем для отчётности
        INSERT INTO aub_in_stock (bill_no, reason_code, no_aub_reason)
        VALUES (ret_bill."№ счета", loc_reason_code, loc_no_aub_reason)
        ON CONFLICT (bill_no) DO 
        UPDATE SET reason_code = excluded.reason_code, no_aub_reason = excluded.no_aub_reason;
    END IF;

    /**
    locVAT := getVAT(acode);
    IF locVAT IS NOT NULL THEN
       UPDATE "Счета" SET "ставкаНДС" = locVAT WHERE "№ счета" = ret_bill."№ счета";
       ret_bill."ставкаНДС" := locVAT;
    END IF; -- locVAT
    **/

    RETURN ret_bill;
END
$function$
;

