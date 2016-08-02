
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
BEGIN
    FOR o IN SELECT * FROM bx_order WHERE billcreated = 0 ORDER BY "Номер" LOOP
        RAISE NOTICE 'Создаём счёт для заказа=%', o."Номер";
        cr_bill_result := fn_createinetbill(o."Номер");
        IF 1 = cr_bill_result THEN -- автосчёт создан
           PERFORM "fnCreateAutoBillMessage"(o."Номер");
        END IF; -- 1 = cr_bill_result
    END LOOP;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
COMMENT ON FUNCTION fn_inetbill_neworders() IS 'Пытается создать счета, сформировать документы и отправить их по почте для новых загруженных заказов';
