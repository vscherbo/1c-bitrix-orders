-- Function: "fnCreateAutoBillMessage"(integer)

-- DROP FUNCTION "fnCreateAutoBillMessage"(integer);

CREATE OR REPLACE FUNCTION "fnCreateAutoBillMessage"(order_id integer)
  RETURNS integer AS
$BODY$DECLARE 
mstr varchar(255);
-- loc_msg_to integer = 2; -- в файл, если ниже не заданое иное
loc_msg_to integer = 0; -- клиенту, если ниже не заданое иное
loc_message_id integer;
bill_no INTEGER;
enterprise_code INTEGER;
payment_method_id INTEGER;
delivery_mode VARCHAR;
buyer_comment VARCHAR;
ord_date timestamp without time zone;
ord_time VARCHAR;
loc_msg_type INTEGER;
BEGIN 
SELECT "Счет", "Дата", "Время" INTO bill_no, ord_date, ord_time FROM bx_order WHERE "Номер" = order_id;
SELECT "Код" INTO enterprise_code FROM "Счета" WHERE "№ счета" = bill_no;
SELECT fvalue INTO buyer_comment FROM bx_order_feature WHERE order_id = "bx_order_Номер" AND fname = 'Комментарий покупателя';
    if buyer_comment IS NULL THEN
        mstr := E'Ваш заказ '|| order_id::VARCHAR || ' от '|| ord_date + ord_time::INTERVAL || ' на сайте kipspb.ru '
               || E'\nобработан и сформирован счёт №' || to_char(bill_no, '9999-9999') || E'.\n';
        RAISE NOTICE 'Извещение для Автосчёта=%', mstr;
        SELECT fvalue INTO payment_method_id FROM bx_order_feature WHERE order_id = "bx_order_Номер" AND fname = 'Метод оплаты ИД';
        -- 21 - Наличные
        -- 22 - Банк???
        -- 25 - Квитанция
        -- 26 - Платрон
        SELECT fvalue INTO delivery_mode FROM bx_order_feature WHERE order_id = "bx_order_Номер" AND fname = 'Способ доставки';
        IF 223719 = enterprise_code THEN -- Если Физлицо
            RAISE NOTICE 'Автосчёт физ. лица.';
            -- Если НЕ 'Курьерская служба', формируем текст письма
            IF 'Курьерская служба' != delivery_mode THEN
                mstr := mstr || E'\nВо вложении находится бланк Вашего заказа.';
                loc_msg_type := 2; -- бланк-заказа
                IF 25 = payment_method_id THEN -- Квитанция для Банка
                    mstr := mstr || E'\nТам же - квитанция для оплаты в отделении банка.';               
                    loc_msg_type := 3; -- бланк-заказа и квитанция
                END IF; -- 25, Квитанция
            ELSE
                RAISE NOTICE 'Автосчёт с доставкой курьерской службой, пропускаем.';
                loc_message_id := -2; -- обработать в CreateAutoBillNotification
            END IF; -- 'Курьерская служба'
        ELSE
           RAISE NOTICE 'Автосчёт юр. лица.';
           IF delivery_mode IN ('Самовывоз', 'Курьерская служба', 'Деловые Линии', 'ПЭК', 'Байкал Сервис', 'ТК КИТ') THEN -- Курьерская служба, широко используемые ТК или Самовывоз
               -- формируем текст письма (счёт-факс)
               mstr := mstr || E'\nВо вложении находится счёт для оплаты. Счёт действителен в течение 5 дней.';
               loc_msg_type := 4; -- счёт-факс
            ELSE
               RAISE NOTICE 'Доставка не совместимая с авточётом. Пропускаем извещение для клиента.';
               loc_message_id := -3; -- обработать в CreateAutoBillNotification
            END IF; -- широко используемые ТК или Самовывоз
        END IF; -- физлицо

        IF length(mstr) > 0 AND loc_msg_type IS NOT NULL THEN -- помещаем письмо в очередь сообщений
            WITH inserted AS (
            INSERT INTO СчетОчередьСообщений ("№ счета", msg_to, msg, msg_type) 
                    values (bill_no, loc_msg_to, mstr, loc_msg_type) 
                    RETURNING id)
            SELECT id INTO loc_message_id FROM inserted;
        END IF;
    ELSE -- there is buyer_comment
        RAISE NOTICE 'Автосчёт с комментариями, пропускаем, bx_order_id=%', order_id;
        loc_message_id := -1; -- обработать в CreateAutoBillNotification
    END IF; -- NO buyer_comment

    RETURN loc_message_id;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION "fnCreateAutoBillMessage"(integer)
  OWNER TO arc_energo;
