-- Function: "fnCreateAutoBillNotification"(integer, integer)

-- DROP FUNCTION "fnCreateAutoBillNotification"(integer, integer);

CREATE OR REPLACE FUNCTION "fnCreateAutoBillNotification"(
    order_id integer,
    a_reason integer)
  RETURNS integer AS
$BODY$DECLARE 
mstr varchar;
message_id integer;
loc_bill_no INTEGER;
loc_str VARCHAR := '';
BEGIN 
    SELECT "Счет", "Дата", "Время" INTO loc_bill_no FROM bx_order WHERE "Номер" = order_id;

    -- mstr := E'Создан автосчёт '|| to_char(loc_bill_no, 'FM9999-9999')|| E' по заказу ' || order_id::VARCHAR || E' на kipspb.ru\n'; 
    mstr := format(E'Создан автосчёт %s по заказу %s на kipspb.ru\n', to_char(loc_bill_no, 'FM9999-9999'), order_id); 
    /**
    IF a_reason = 2 THEN
       loc_str := E'Встретились несинхронизированные позиции.';
    ELSIF a_reason = 6 THEN
       loc_str := E'Для некоторых позиций не хватило товара со склада.';
    ELSIF a_reason = 7 THEN
       loc_str := E'Некоторые резервы не удалось поставить.';
    END IF; 
    **/
    -- IF a_reason IN (2,6,7,11) THEN
    IF a_reason IN (SELECT ab_code FROM arc_energo.vw_autobill_partly) THEN
        SELECT string_agg(descr, E'\n') INTO loc_str FROM arc_energo.aub_log
                            WHERE bx_order_no=order_id and res_code in (SELECT ab_code FROM arc_energo.vw_autobill_partly) and mod_id <>'-1';
        loc_str := E'Счёт требует ручной доработки:\n' || loc_str;                            
    END IF;
    mstr := mstr || loc_str || E'\nПроверьте его, пожалуйста!';
    -- 2020-09-08 loc_str := '';

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
               values (loc_bill_no, 1, mstr, 9) RETURNING id
    )
    SELECT id INTO message_id FROM inserted;

    RETURN message_id;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION "fnCreateAutoBillNotification"(integer, integer)
  OWNER TO arc_energo;
