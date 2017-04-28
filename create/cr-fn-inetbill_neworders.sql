-- Function: fn_inetbill_neworders()

-- DROP FUNCTION fn_inetbill_neworders();

CREATE OR REPLACE FUNCTION fn_inetbill_neworders()
  RETURNS void AS
$BODY$ DECLARE
  o RECORD;
  loc_cr_bill_result INTEGER;
  loc_msg_id INTEGER;
  SiteID VARCHAR;
  of_Site_found BOOLEAN;
  is_kipspb BOOLEAN;
  loc_bill_no INTEGER;
  loc_RETURNED_SQLSTATE TEXT;
  loc_MESSAGE_TEXT TEXT;
  loc_PG_EXCEPTION_DETAIL TEXT;
  loc_PG_EXCEPTION_HINT TEXT;
  loc_PG_EXCEPTION_CONTEXT TEXT;
  loc_exception_txt TEXT;
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
                BEGIN
                    loc_cr_bill_result := fn_createinetbill(o."Номер");
                EXCEPTION WHEN OTHERS THEN
                    loc_cr_bill_result := -2;
                    GET STACKED DIAGNOSTICS
                        loc_RETURNED_SQLSTATE = RETURNED_SQLSTATE,
                        loc_MESSAGE_TEXT = MESSAGE_TEXT,
                        loc_PG_EXCEPTION_DETAIL = PG_EXCEPTION_DETAIL,
                        loc_PG_EXCEPTION_HINT = PG_EXCEPTION_HINT,
                        loc_PG_EXCEPTION_CONTEXT = PG_EXCEPTION_CONTEXT ;
                    loc_exception_txt = format('RETURNED_SQLSTATE=%s, MESSAGE_TEXT=%s, PG_EXCEPTION_DETAIL=%s, PG_EXCEPTION_HINT=%s, PG_EXCEPTION_CONTEXT=%s', loc_RETURNED_SQLSTATE, loc_MESSAGE_TEXT, loc_PG_EXCEPTION_DETAIL, loc_PG_EXCEPTION_HINT, loc_PG_EXCEPTION_CONTEXT);
                    UPDATE bx_order SET billcreated = loc_cr_bill_result WHERE "Номер" = o."Номер";
                    RAISE NOTICE 'ОШИБКА при создании автосчёта по заказу [%] exception=[%]', o."Номер", loc_exception_txt;
                END; -- cast to numeric

                RAISE NOTICE 'Результат создания счёта=% для заказа=%', loc_cr_bill_result, o."Номер";
                IF 1 = loc_cr_bill_result THEN -- автосчёт создан полностью
                    RAISE NOTICE 'Создаём сообщение клиенту для заказа=%', o."Номер";
                    loc_msg_id := "fnCreateAutoBillMessage"(o."Номер");
                    -- клиенту
                    IF loc_msg_id IS NOT NULL AND loc_msg_id > 0 THEN
                        PERFORM sendbillsinglemsg(loc_msg_id);
                        UPDATE "Счета" SET "Статус"=0 WHERE "№ счета" = loc_bill_no; -- вызовет регистрацию в bill_status_history
                        -- В очередь обновления статуса для Инет заказов с нашего сайта
                        /** изменение статуса заказа на сайте на "Ожидает оплату"
                         * после появления квитанции (статус 999) в СчётОчередьСообщений по этому счёту
                        PERFORM "fn_InetOrderNewStatus"(0, o."Номер");
                        **/
                    ELSE
                        RAISE NOTICE 'не создано сообщение клиенту для заказа=%, loc_msg_id=%', o."Номер", quote_nullable(loc_msg_id);
                    END IF;
                END IF; -- 1 = loc_cr_bill_result
                -- менеджеру 
                IF loc_cr_bill_result IN (1,2,6,7) THEN -- включая частичный автосчёт
                    RAISE NOTICE 'Создаём сообщение менеджеру для заказа=%', o."Номер";
                    -- loc_msg_id, которое вернула "fnCreateAutoBillMessage", содержит код_причины неотправки письма клиенту об автосчёте
                    loc_msg_id := "fnCreateAutoBillNotification"(o."Номер", COALESCE(loc_msg_id, loc_cr_bill_result));
                    IF loc_msg_id IS NOT NULL THEN
                        PERFORM sendbillsinglemsg(loc_msg_id);
                    ELSE
                        RAISE NOTICE 'ERROR: не создано сообщение менеджеру для заказа=%', o."Номер";
                    END IF;
                END IF; -- loc_cr_bill_result IN (...)
            END IF; -- FOUND "№ счета"
        ELSE
            RAISE NOTICE 'Пропускаем заказ: of_Site_found=%, is_kipspb=%', of_Site_found, is_kipspb;
            UPDATE bx_order SET billcreated = 99 WHERE "Номер" = o."Номер";
        END IF; -- SiteID contains 'ar'
    END LOOP;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_inetbill_neworders()
  OWNER TO arc_energo;
COMMENT ON FUNCTION fn_inetbill_neworders() IS 'Пытается создать счета, сформировать документы и отправить их по почте для новых загруженных заказов';
