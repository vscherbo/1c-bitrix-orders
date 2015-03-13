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
-- Хозяин=38 - Гараханян
-- Хозяин=77 - Бондаренко
  inet_bill_owner integer = 77;
BEGIN
    SELECT fvalue INTO BuyerComment 
    FROM bx_order_feature
    WHERE "bx_order_Номер" = bx_order
        AND fname = 'Комментарии покупателя';

    SELECT fvalue INTO DeliveryMode 
    FROM bx_order_feature
    WHERE "bx_order_Номер" = bx_order
        AND fname = 'Способ доставки';

    IF DeliveryMode = 'Самовывоз' 
        THEN Delivery := 'Самовывоз';
        ELSE Delivery := 'Отправка';
    END IF;

    WITH inserted AS (
        INSERT INTO "Счета"
            ("Код", "фирма", "Хозяин", "№ счета", "Дата счета", "Сумма", "Интернет", "ИнтернетЗаказ", "КодРаботника", "Статус", "инфо", "Дополнительно", "Отгрузка", "ОтгрузкаКем") 
        VALUES (aFirmCode, 'АРКОМ', inet_bill_owner, fn_GetNewBillNo(inet_bill_owner), CURRENT_DATE, sum, 't', bx_order, aEmpCode, 0, 'Автосчёт на заказ с сайта', BuyerComment, Delivery, DeliveryMode)
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

-- С сайта
-- 1	Самовывоз
-- 9	Почта России
-- 5	Междугородний автотранспорт, Почта, Экспресс-почта
-- 7	Транспортная компания (ж/д, авиа, авто)
-- 2	Курьер по СПб
-- 8	Курьерская служба
-- 6	Иное
