
CREATE OR REPLACE FUNCTION fn_inetbill_neworders()
  RETURNS void AS
$BODY$ DECLARE
  o RECORD;
  cr_bill_result INTEGER;
  msg_id INTEGER;
  bill_no INTEGER;
  enterprise_code INTEGER;
  payment_method_id INTEGER;
  delivery_service VARCHAR;
  buyer_comment VARCHAR;
  SiteID VARCHAR;
  of_Site_found BOOLEAN;
  is_kipspb BOOLEAN;
BEGIN
    FOR o IN SELECT * FROM bx_order WHERE billcreated = 0 ORDER BY "Номер" LOOP
        SELECT f.fvalue INTO SiteID FROM bx_order_feature f WHERE f."bx_order_Номер" = o."Номер" AND f.fname = 'Сайт';
        of_Site_found := found;
        is_kipspb := position('ar' in SiteID) > 0;
        IF of_Site_found AND is_kipspb THEN
            RAISE NOTICE 'Создаём счёт для заказа=%', o."Номер";
            cr_bill_result := fn_createinetbill(o."Номер");
            IF 1 = cr_bill_result THEN -- автосчёт создан
                msg_id := "fnCreateAutoBillMessage"(o."Номер");
                PERFORM fn_sendbillsinglemsg(msg_id);
            END IF; -- 1 = cr_bill_result
        ELSE
            RAISE NOTICE 'Пропускаем заказ: of_Site_found=%, is_kipspb=%', of_Site_found, is_kipspb;
            UPDATE bx_order SET billcreated = 99 WHERE "Номер" = o."Номер";
        END IF; -- SiteID contains 'ar'
    END LOOP;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
COMMENT ON FUNCTION fn_inetbill_neworders() IS 'Пытается создать счета, сформировать документы и отправить их по почте для новых загруженных заказов';
