-- DROP FUNCTION bxorder2bill(integer);

CREATE OR REPLACE FUNCTION bxorder2bill(arg_bx_order_no integer)
  RETURNS void AS
$BODY$ DECLARE
  SiteID VARCHAR;
  of_Site_found BOOLEAN;
  is_kipspb BOOLEAN;
  loc_bill_no INTEGER;
  loc_cr_bill_result INTEGER;
  loc_msg_id INTEGER;
  loc_part_msg_id INTEGER;
  loc_RETURNED_SQLSTATE TEXT;
  loc_MESSAGE_TEXT TEXT;
  loc_PG_EXCEPTION_DETAIL TEXT;
  loc_PG_EXCEPTION_HINT TEXT;
  loc_PG_EXCEPTION_CONTEXT TEXT;
  loc_exception_txt TEXT;
  loc_reason TEXT;
  loc_func_name text := 'not assigned yet in bxorder2bill';
BEGIN
SELECT f.fvalue INTO SiteID FROM bx_order_feature f WHERE f."bx_order_Номер" = arg_bx_order_no AND f.fname = 'Сайт';
of_Site_found := found;
is_kipspb := position('ar' in SiteID) > 0;
IF of_Site_found AND is_kipspb THEN
    SELECT "№ счета" INTO loc_bill_no FROM "Счета" WHERE "ИнтернетЗаказ" = arg_bx_order_no;
    IF FOUND THEN
        UPDATE bx_order SET billcreated = loc_bill_no WHERE "Номер" = arg_bx_order_no; -- предотвратить повторную обработку
        RAISE NOTICE 'Для заказа с номером % уже создан счёт=%', arg_bx_order_no, loc_bill_no;
    ELSE
        UPDATE bx_order SET billcreated = arg_bx_order_no WHERE "Номер" = arg_bx_order_no; -- предотвратить повторную обработку
        RAISE NOTICE 'Создаём счёт для заказа=%', arg_bx_order_no;
        BEGIN
            loc_cr_bill_result := create_inet_bill(arg_bx_order_no);
        EXCEPTION WHEN OTHERS THEN
            loc_cr_bill_result := -1;
            GET STACKED DIAGNOSTICS
                loc_RETURNED_SQLSTATE = RETURNED_SQLSTATE,
                loc_MESSAGE_TEXT = MESSAGE_TEXT,
                loc_PG_EXCEPTION_DETAIL = PG_EXCEPTION_DETAIL,
                loc_PG_EXCEPTION_HINT = PG_EXCEPTION_HINT,
                loc_PG_EXCEPTION_CONTEXT = PG_EXCEPTION_CONTEXT ;
            loc_exception_txt = format(E'create_inet_bill RETURNED_SQLSTATE=%s, MESSAGE_TEXT=%s,\nPG_EXCEPTION_DETAIL=%s,\nPG_EXCEPTION_HINT=%s,\nPG_EXCEPTION_CONTEXT=%s', loc_RETURNED_SQLSTATE, loc_MESSAGE_TEXT, loc_PG_EXCEPTION_DETAIL, loc_PG_EXCEPTION_HINT, loc_PG_EXCEPTION_CONTEXT);
            UPDATE bx_order SET billcreated = loc_cr_bill_result WHERE "Номер" = arg_bx_order_no;
            loc_reason := format('ОШИБКА при создании автосчёта exception=[%s]', loc_exception_txt);
            INSERT INTO aub_log(bx_order_no, descr, res_code, mod_id) VALUES(arg_bx_order_no, loc_reason, -1, -1);
            RAISE NOTICE '%. Заказ [%]', loc_reason, arg_bx_order_no;
        END; -- создание счёта

        RAISE NOTICE 'Результат создания счёта=% для заказа=%', loc_cr_bill_result, arg_bx_order_no;
        IF 1 = loc_cr_bill_result THEN -- автосчёт создан полностью
            RAISE NOTICE 'Создаём сообщение клиенту для заказа=%', arg_bx_order_no;
            BEGIN -- клиенту
                loc_msg_id := "fnCreateAutoBillMessage"(arg_bx_order_no);
                loc_func_name := 'fnCreateAutoBillMessage';
            EXCEPTION WHEN OTHERS THEN
                loc_msg_id := -10;
                GET STACKED DIAGNOSTICS
                    loc_RETURNED_SQLSTATE = RETURNED_SQLSTATE,
                    loc_MESSAGE_TEXT = MESSAGE_TEXT,
                    loc_PG_EXCEPTION_DETAIL = PG_EXCEPTION_DETAIL,
                    loc_PG_EXCEPTION_HINT = PG_EXCEPTION_HINT,
                    loc_PG_EXCEPTION_CONTEXT = PG_EXCEPTION_CONTEXT ;
                loc_exception_txt = format(E'%s RETURNED_SQLSTATE=%s, MESSAGE_TEXT=%s,\nPG_EXCEPTION_DETAIL=%s,\nPG_EXCEPTION_HINT=%s,\nPG_EXCEPTION_CONTEXT=%s', loc_func_name, loc_RETURNED_SQLSTATE, loc_MESSAGE_TEXT, loc_PG_EXCEPTION_DETAIL, loc_PG_EXCEPTION_HINT, loc_PG_EXCEPTION_CONTEXT);
                RAISE NOTICE 'ERROR in %: %', loc_func_name, loc_exception_txt;
            END; -- создание сообщения клиенту

            IF loc_msg_id IS NOT NULL AND loc_msg_id > 0 THEN
                PERFORM sendbillsinglemsg(loc_msg_id);
                UPDATE "Счета" SET "Статус"=0 WHERE "ИнтернетЗаказ" = arg_bx_order_no; -- вызовет регистрацию в bill_status_history
                -- В очередь обновления статуса для Инет заказов с нашего сайта
                /** изменение статуса заказа на сайте на "Ожидает оплату"
                 * после появления квитанции (статус 999) в СчётОчередьСообщений по этому счёту
                PERFORM "fn_InetOrderNewStatus"(0, arg_bx_order_no);
                **/
            ELSE
                RAISE NOTICE 'не создано сообщение клиенту для заказа=%, loc_msg_id=%', arg_bx_order_no, quote_nullable(loc_msg_id);
            END IF;
        ELSE -- частичный автосчёт
            RAISE NOTICE 'Создаём сообщение клиенту о частичном автосчёте для заказа=%', arg_bx_order_no;
            BEGIN -- клиенту
                loc_func_name := 'partly_autobill_message';
                loc_part_msg_id := partly_autobill_message(arg_bx_order_no);
                RAISE NOTICE 'Создано сообщение %, id=% для заказа=%', loc_func_name, loc_part_msg_id, arg_bx_order_no;
            EXCEPTION WHEN OTHERS THEN
                loc_part_msg_id := -11;
                GET STACKED DIAGNOSTICS
                    loc_RETURNED_SQLSTATE = RETURNED_SQLSTATE,
                    loc_MESSAGE_TEXT = MESSAGE_TEXT,
                    loc_PG_EXCEPTION_DETAIL = PG_EXCEPTION_DETAIL,
                    loc_PG_EXCEPTION_HINT = PG_EXCEPTION_HINT,
                    loc_PG_EXCEPTION_CONTEXT = PG_EXCEPTION_CONTEXT ;
                loc_exception_txt = format(E'%s RETURNED_SQLSTATE=%s, MESSAGE_TEXT=%s,\nPG_EXCEPTION_DETAIL=%s,\nPG_EXCEPTION_HINT=%s,\nPG_EXCEPTION_CONTEXT=%s', loc_func_name, loc_RETURNED_SQLSTATE, loc_MESSAGE_TEXT, loc_PG_EXCEPTION_DETAIL, loc_PG_EXCEPTION_HINT, loc_PG_EXCEPTION_CONTEXT);
                RAISE NOTICE 'ERROR in %: %', loc_func_name, loc_exception_txt;
            END; -- создание сообщения клиенту

            RAISE NOTICE 'Отправляем сообщение id=% для заказа=%', loc_msg_id, arg_bx_order_no;
            IF loc_msg_id IS NOT NULL AND loc_msg_id > 0 THEN
                PERFORM sendbillsinglemsg(loc_msg_id);
            ELSE
                RAISE NOTICE 'не создано сообщение клиенту о частичном автосчёте для заказа=%, loc_msg_id=%', arg_bx_order_no, quote_nullable(loc_msg_id);
            END IF;
        END IF; -- 1 = loc_cr_bill_result

        -- менеджеру 
        -- IF loc_cr_bill_result IN (1,2,6,7,10,11) THEN -- включая частичный автосчёт
        PERFORM 1 FROM vw_autobill_created WHERE ab_code = loc_cr_bill_result;
        IF FOUND THEN -- включая частичный автосчёт
            RAISE NOTICE 'Создаём сообщение менеджеру для заказа=%', arg_bx_order_no;
            IF loc_cr_bill_result <> 1 THEN -- ЗАГОТОВКА
                UPDATE "Счета" SET "Дополнительно" = 'ЗАГОТОВКА:' || "Дополнительно" WHERE "ИнтернетЗаказ" = arg_bx_order_no;
            END IF;

            -- loc_msg_id, которое вернула "fnCreateAutoBillMessage", содержит код_причины неотправки письма клиенту об автосчёте
            BEGIN
                loc_msg_id := "fnCreateAutoBillNotification"(arg_bx_order_no, COALESCE(loc_msg_id, loc_cr_bill_result));
                loc_func_name := 'fnCreateAutoBillNotification';
            EXCEPTION WHEN OTHERS THEN
                loc_msg_id := -20;
                GET STACKED DIAGNOSTICS
                    loc_RETURNED_SQLSTATE = RETURNED_SQLSTATE,
                    loc_MESSAGE_TEXT = MESSAGE_TEXT,
                    loc_PG_EXCEPTION_DETAIL = PG_EXCEPTION_DETAIL,
                    loc_PG_EXCEPTION_HINT = PG_EXCEPTION_HINT,
                    loc_PG_EXCEPTION_CONTEXT = PG_EXCEPTION_CONTEXT ;
                loc_exception_txt = format(E'%s RETURNED_SQLSTATE=%s, MESSAGE_TEXT=%s,\nPG_EXCEPTION_DETAIL=%s,\nPG_EXCEPTION_HINT=%s,\nPG_EXCEPTION_CONTEXT=%s', loc_func_name, loc_RETURNED_SQLSTATE, loc_MESSAGE_TEXT, loc_PG_EXCEPTION_DETAIL, loc_PG_EXCEPTION_HINT, loc_PG_EXCEPTION_CONTEXT);
--                 loc_exception_txt = format('fnCreateAutoBillMessage RETURNED_SQLSTATE=%s, MESSAGE_TEXT=%s, PG_EXCEPTION_DETAIL=%s, PG_EXCEPTION_HINT=%s, PG_EXCEPTION_CONTEXT=%s', loc_RETURNED_SQLSTATE, loc_MESSAGE_TEXT, loc_PG_EXCEPTION_DETAIL, loc_PG_EXCEPTION_HINT, loc_PG_EXCEPTION_CONTEXT);
                RAISE NOTICE 'ERROR in %: %', loc_func_name, loc_exception_txt;
            END; -- создание сообщения менеджеру

            IF loc_msg_id IS NOT NULL AND loc_msg_id > 0 THEN
                PERFORM sendbillsinglemsg(loc_msg_id);
            ELSE
                RAISE NOTICE 'ERROR: не создано сообщение менеджеру для заказа=%, loc_msg_id=%', arg_bx_order_no, quote_nullable(loc_msg_id);
            END IF;
        END IF; -- loc_cr_bill_result IN vw_autobill_created
    END IF; -- FOUND "№ счета"
ELSE
    loc_reason := format('Заказ не kipspb, пропускаем (of_Site_found=%s, is_kipspb=%s)', of_Site_found, is_kipspb);
    RAISE NOTICE '%', loc_reason;
    INSERT INTO aub_log(bx_order_no, descr, res_code, mod_id) VALUES(arg_bx_order_no, loc_reason, 99, -1);
    UPDATE bx_order SET billcreated = 99 WHERE "Номер" = arg_bx_order_no;
END IF; -- SiteID contains 'ar'

END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
COMMENT ON FUNCTION bxorder2bill(integer) IS 'Создаёт счёт, формирует документы и помещает в очередь отправки сообщений для одного заказа';
