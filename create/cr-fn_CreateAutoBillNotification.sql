-- Function: "fnCreateAutoBillNotification"(integer)

-- DROP FUNCTION "fnCreateAutoBillNotification"(integer);

CREATE OR REPLACE FUNCTION "fnCreateAutoBillNotification"(order_id integer, a_reason integer)
  RETURNS integer AS
$BODY$DECLARE 
mstr varchar(255);
message_id integer;
bill_no INTEGER;
ord_date timestamp without time zone;
ord_time VARCHAR;
loc_str VARCHAR;
BEGIN 
    SELECT "Счет", "Дата", "Время" INTO bill_no, ord_date, ord_time FROM bx_order WHERE "Номер" = order_id;

    mstr := E'Создан автосчёт '|| to_char(bill_no, 'FM9999-9999') 
            || E' по заказу ' || order_id::VARCHAR || ' на kipspb.ru'
            || E'. Проверьте его, пожалуйста!';
    IF a_reason = -1 THEN
       loc_str := E'\nЗаказ с комментарием покупателя.';
    ELSIF a_reason = -2 THEN
       loc_str := E'\nПокупателем физ.лицом выбрана доставка курьерской службой.';
    ELSIF a_reason = -3 THEN
       loc_str := E'\nПокупателем юр.лицом выбрана доставка, несовместимая с автосчётом.';
    END IF; 
    IF length(loc_str) > 0 THEN
       mstr := mstr || loc_str ||  E'\nАвтосчёт НЕ отправлен клиенту.';
    END IF; 

    WITH inserted AS (
        INSERT INTO СчетОчередьСообщений ("№ счета", msg_to, msg, msg_type)
               values (bill_no, 1, mstr, 9) RETURNING id
    )
    SELECT id INTO message_id FROM inserted;

    RETURN message_id;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION "fnCreateAutoBillNotification"(integer, integer)
  OWNER TO arc_energo;
