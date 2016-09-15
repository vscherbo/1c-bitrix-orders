-- Function: "fnCreateAutoBillNotification"(integer)

-- DROP FUNCTION "fnCreateAutoBillNotification"(integer);

CREATE OR REPLACE FUNCTION "fnCreateAutoBillNotification"(order_id integer)
  RETURNS integer AS
$BODY$DECLARE 
mstr varchar(255);
message_id integer;
bill_no INTEGER;
ord_date timestamp without time zone;
ord_time VARCHAR;
BEGIN 
    SELECT "Счет", "Дата", "Время" INTO bill_no, ord_date, ord_time FROM bx_order WHERE "Номер" = order_id;

    mstr := E'Создан автосчёт '|| to_char(bill_no, 'FM9999-9999') 
            || E' по заказу ' || order_id::VARCHAR || ' на kipspb.ru'
            || E'. Проверьте его, пожалуйста!';
    WITH inserted AS (
        INSERT INTO СчетОчередьСообщений ("№ счета", msg_to, msg, msg_type)
               values (bill_no, 1, mstr, 9) RETURNING id
    )
    SELECT id INTO message_id FROM inserted;

    RETURN message_id;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION "fnCreateAutoBillNotification"(integer)
  OWNER TO arc_energo;
