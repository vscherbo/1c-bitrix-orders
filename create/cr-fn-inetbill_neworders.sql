
CREATE OR REPLACE FUNCTION fn_inetbill_neworders()
  RETURNS void AS
$BODY$ DECLARE
  o RECORD;
  cr_bill_result INTEGER;
  bill_no INTEGER;
  enterprise_code INTEGER;
  payment_method_id INTEGER;
  delivery_service VARCHAR;
  buyer_comment VARCHAR;
  doc_fname VARCHAR;
  doc_bank_fname VARCHAR;
BEGIN
    FOR o IN SELECT * FROM bx_order WHERE billcreated = 0 ORDER BY "Номер" LOOP
        RAISE NOTICE 'Создаём счёт для заказа=%', o."Номер";
        cr_bill_result := fn_createinetbill(o."Номер");
        IF 1 = cr_bill_result THEN -- автосчёт создан
            SELECT "Код", "Счет" INTO bill_no, enterprise_code FROM bx_order WHERE "Номер" = o."Номер";
            SELECT fvalue INTO buyer_comment FROM bx_order_feature WHERE o."Номер" = "bx_order_Номер" AND fname = 'Комментарий покупателя';
            if buyer_comment IS NULL THEN
                SELECT fvalue INTO payment_method_id FROM bx_order_feature WHERE o."Номер" = "bx_order_Номер" AND fname = 'Метод оплаты ИД';
                -- 21 - Наличные
                -- 22 - Банк
                -- 26 - Платрон
                SELECT fvalue INTO delivery_service FROM bx_order_feature WHERE o."Номер" = "bx_order_Номер" AND fname = 'Способ доставки';
                -- Если Физлицо, формируем и отправлем документы
                IF 223719 = enterprise_code THEN
                    -- Если НЕ 'Курьерская служба', формируем и отправлем документы
                    IF 'Курьерская служба' != delivery_service THEN
                       IF 22 = payment_method_id THEN -- Квитанция для Банка
                          -- формируем квитанцию
                          doc_bank_fname := fn_doc_person_bank(bill_no);
                       END IF; -- 22, Банк
                       -- Бланк заказа
                       doc_fname := fn_order_form(bill_no);
                       -- send_attach(  .... doc_array
                       public.send_attachment(
    'root@arc.world',
    '',
    'root@arc.world',
    'mail.arc.world',
    25,
    'it-events@arc.world',
    E'Ваш заказ '|| str(bill_no) || E' на сайте kipspb.ru',
    E'Добрый день.\n\nВаш заказ получен.\n\n С уважением, "АРК "Энергосервис""',
    string_to_array(doc_bank_fname|| ',' ||doc_fname, ',')
);




                       
                    END IF; -- 'Курьерская служба'
                ELSE
                    -- счёт-факс
                END IF; -- физлицо
            END IF; -- NO buyer_comments
        END IF; -- 1 = cr_bill_result
    END LOOP;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
COMMENT ON FUNCTION fn_inetbill_neworders() IS 'Пытается создать счета, сформировать документы и отправить их по почте для новых загруженных заказов';
