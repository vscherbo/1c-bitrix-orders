CREATE OR REPLACE FUNCTION arc_energo.partly_autobill_message(order_id integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$DECLARE
mstr varchar;
-- loc_msg_to integer = 2; -- в файл, если ниже не заданое иное
loc_msg_to integer = 0; -- клиенту, если ниже не заданое иное
loc_message_id integer;
loc_bill_no INTEGER;
enterprise_code INTEGER;
ord_date timestamp without time zone;
ord_time VARCHAR;
loc_msg_type INTEGER;
loc_billcreated integer;
loc_str varchar := E'';
loc_str_ok varchar := E'';
loc_str_todo varchar := E'';
loc_mgr_owner integer;
BEGIN
SELECT "Счет", "Дата", "Время", billcreated INTO loc_bill_no, ord_date, ord_time, loc_billcreated FROM bx_order WHERE "Номер" = order_id;
SELECT "Код", "Хозяин" INTO enterprise_code, loc_mgr_owner FROM "Счета" WHERE "№ счета" = loc_bill_no;
IF loc_billcreated IN (SELECT ab_code FROM arc_energo.vw_autobill_partly) 
    AND loc_mgr_owner in (38, 55)
THEN
    loc_msg_type := 8; -- заказ с сайта получен
    RAISE NOTICE 'Частичный автосчёт по заказу %, формируем сообщение клиенту', order_id;
    loc_str := E'Ваш заказ ' || order_id::varchar || E' с сайта kipspb.ru получен';
    -- из aub_log позиции в порядке
    loc_str_ok := msg_ok_items(order_id);
    IF loc_str_ok IS NOT NULL THEN
        loc_str := loc_str || E'.\nМы автоматически создали резервы для части позиций, а некоторые позиции ещё обрабатываются менеджером.\n\n';
        loc_str := loc_str || E'Следующие позиции уже зарезервированы для Вас:\n' || loc_str_ok || E'\n';
        RAISE NOTICE 'loc_str=%', loc_str;

        -- из aub_log проблемные позиции
        loc_str_todo := msg_todo_items(order_id);
        mstr := loc_str || E'\nЭти позиции обрабатываются менеджером:\n' || loc_str_todo;
        RAISE NOTICE 'проблемные loc_str=%', loc_str_todo;
    ELSE -- все позиции поблемные
        mstr := loc_str || E'\nи уже поступил менеджеру для обработки.\n';
    END IF;
    RAISE NOTICE 'loc_msg_type=%, финальное сообщение: mstr=%', loc_msg_type, mstr;

    IF length(mstr) > 0 AND loc_msg_type IS NOT NULL THEN -- помещаем письмо в очередь сообщений
        WITH inserted AS (
        INSERT INTO СчетОчередьСообщений ("№ счета", msg_to, msg, msg_type)
                values (loc_bill_no, 
                        -- 1, -- manager DEBUG
                        loc_msg_to,
                        mstr, loc_msg_type)
                RETURNING id)
        SELECT id INTO loc_message_id FROM inserted;
    END IF;
END IF; -- оповещаем покупателя: "менеджер обрабатывает заказ"

RETURN loc_message_id;
END;$function$
;
/**
Ваш заказ 55555, созданный на сайте kipspb.ru получен.
Мы автоматически содали резервы для части позиций, а некоторые позиции ещё обрабатываются менеджером.

Следующие позиции уже зарезервированы для Вас:
QWERTY
XYZ12

Эти позиции обрабатываются менеджером:
ABC-11
ZXCVVB
############################################

Ваш заказ 55555, созданный на сайте kipspb.ru получен
и уже поступил менеджеру для обработки.

**/
