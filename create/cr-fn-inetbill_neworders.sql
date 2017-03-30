
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
  loc_bill_no INTEGER;
BEGIN
    FOR o IN SELECT * FROM bx_order WHERE billcreated = 0 ORDER BY "Номер" LOOP
        SELECT f.fvalue INTO SiteID FROM bx_order_feature f WHERE f."bx_order_Номер" = o."Номер" AND f.fname = 'Сайт';
        of_Site_found := found;
        is_kipspb := position('ar' in SiteID) > 0;
        IF of_Site_found AND is_kipspb THEN
            SELECT "№ счета" INTO loc_bill_no FROM "Счета" WHERE "ИнтернетЗаказ" = o."Номер";
            IF FOUND THEN
                UPDATE bx_order SET billcreated = -1 WHERE "Номер" = o."Номер";
                RAISE NOTICE 'Для заказа с номером % уже создан счёт=%', o."Номер", loc_bill_no;
            ELSE
                RAISE NOTICE 'Создаём счёт для заказа=%', o."Номер";
                cr_bill_result := fn_createinetbill(o."Номер");
                RAISE NOTICE 'Результат создания счёта=% для заказа=%', cr_bill_result, o."Номер";
                IF 1 = cr_bill_result THEN -- автосчёт создан
                    RAISE NOTICE 'Создаём сообщение клиенту для заказа=%', o."Номер";
                    msg_id := "fnCreateAutoBillMessage"(o."Номер");
                    -- клиенту
                    IF msg_id IS NOT NULL AND msg_id > 0 THEN
                        PERFORM sendbillsinglemsg(msg_id);
                        -- В очередь обновления статуса для Инет заказов с нашего сайта
                        /** изменение статуса заказа на сайте на "Ожидает оплату"
                         * после появления квитанции (статус 999) в СчётОчередьСообщений по этому счёту
                        PERFORM "fn_InetOrderNewStatus"(0, o."Номер");
                        **/
                    ELSE
                        RAISE NOTICE 'не создано сообщение клиенту для заказа=%, msg_id=%', o."Номер", quote_nullable(msg_id);
                    END IF;
                    -- менеджеру 
                    RAISE NOTICE 'Создаём сообщение менеджеру для заказа=%', o."Номер";
                    msg_id := "fnCreateAutoBillNotification"(o."Номер", msg_id);
                    IF msg_id IS NOT NULL THEN
                        PERFORM sendbillsinglemsg(msg_id);
                    ELSE
                        RAISE NOTICE 'ERROR: не создано сообщение менеджеру для заказа=%', o."Номер";
                    END IF;
                END IF; -- 1 = cr_bill_result
            END IF; -- FOUND "№ счета"
        ELSE
            RAISE NOTICE 'Пропускаем заказ: of_Site_found=%, is_kipspb=%', of_Site_found, is_kipspb;
            UPDATE bx_order SET billcreated = 99 WHERE "Номер" = o."Номер";
        END IF; -- SiteID contains 'ar'
    END LOOP;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
COMMENT ON FUNCTION fn_inetbill_neworders() IS 'Пытается создать счета, сформировать документы и отправить их по почте для новых загруженных заказов';
