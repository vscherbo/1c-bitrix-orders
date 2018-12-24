
-- DROP FUNCTION create_inet_bill(integer);

CREATE OR REPLACE FUNCTION create_inet_bill(bx_order_no integer)
  RETURNS integer AS
$BODY$
DECLARE
   oi RECORD;
   bill RECORD;
   loc_KS integer;
   CreateResult integer;
   item RECORD;
   item_id integer;
   Npp INTEGER;
   VAT numeric;
   loc_bill_no INTEGER;
   Price NUMERIC;
   PriceVAT NUMERIC; 
   bx_sum NUMERIC;
   loc_OrderItemProcessingTime varchar;
   inserted_bill_item RECORD;
   vendor_id INTEGER;
   flgOwen BOOLEAN;
   skipCheckOwen BOOLEAN;
   debug_rec RECORD;
   loc_in_stock NUMERIC; 
   loc_in_stock_wh NUMERIC; -- склад Ясная
   loc_in_stock_exh NUMERIC; -- склад Выставка
   loc_lack_wh NUMERIC; -- не хватает на Ясной для заказанного количества
   real_discount INTEGER;
   dbg_notice VARCHAR;
   loc_delivery_quantity TEXT;
   loc_parts TEXT[];
   loc_article_id INTEGER;
   loc_article_str TEXT;
   loc_when TEXT;
   loc_qnt NUMERIC;
   loc_part TEXT;
   loc_sum NUMERIC;
   loc_lack_reserve NUMERIC;
   loc_lack_reason TEXT;
   loc_aub_msg TEXT;
dbg_order_items_count INTEGER;
loc_where_buy VARCHAR;
loc_okei_code integer;
loc_measure_unit varchar;
loc_item_name varchar;
loc_price NUMERIC;
loc_modificators varchar;
loc_1C_article varchar;
loc_kp integer;
loc_emp_code integer;
loc_firm_code integer;
loc_delivery_qnt_flag boolean;
loc_suspend_bill_msg_flag boolean;
loc_suspend_bill_msg text;
loc_no_autobill_item  boolean;
loc_count_qnt  numeric;
loc_wrong_qnt  numeric;
BEGIN
RAISE NOTICE '##################### Начало create_inet_bill, заказ=%', bx_order_no;
INSERT INTO aub_log(bx_order_no, descr, mod_id) VALUES(bx_order_no, 'Начало обработки заказа', -1);

-- SELECT * INTO loc_buyer_id, loc_buyer_name, loc_email, loc_is_valid FROM get_bx_order_ids(bx_order_no) ;
-- IF loc_is_valid THEN
IF is_bx_order_valid(bx_order_no) THEN
    CreateResult := -8; -- инициируем значением "пустой состав заказа"
    bx_sum := 0;
ELSE
    CreateResult := 4; -- отменённый или неполный заказ, покупатель или отсутствуют оба 'EMail' и 'Контактный email'
    UPDATE bx_order SET billcreated = CreateResult, "Счет" = loc_bill_no WHERE "Номер" = bx_order_no ;
    RETURN CreateResult;
END IF;

DROP TABLE IF EXISTS tmp_order_items;
CREATE TEMPORARY TABLE IF NOT EXISTS tmp_order_items(ks integer, oi_id TEXT, oi_okei_code integer, oi_measure_unit character varying(50), whid integer, oi_quantity numeric(18,3), oi_delivery_qnt TEXT, oi_name VARCHAR, oi_mod_id VARCHAR, oi_modificators VARCHAR) ON COMMIT DROP;
TRUNCATE tmp_order_items; -- if exists

CREATE temporary TABLE IF NOT EXISTS qnt_in_stock (ks INTEGER, whid INTEGER, whqnt NUMERIC) ON COMMIT DROP;
TRUNCATE qnt_in_stock; -- if exists

flgOwen := False;
skipCheckOwen := FALSE;

FOR oi in (SELECT bx_order_item.*
                , lpad(bx_order_item_feature.fvalue::VARCHAR, 12, '0')  as mod_id
            FROM bx_order_item
            LEFT JOIN bx_order_item_feature ON bx_order_item_feature.bx_order_item_id = bx_order_item."Ид" 
                                    AND bx_order_item_feature."bx_order_Номер" = bx_order_item."bx_order_Номер"
                                    AND ( 
                                         bx_order_item_feature.fname = 'КодМодификации'
                                         OR bx_order_item_feature.fname = 'СвойствоКорзины#SKU_CODE'
                                        )
            WHERE bx_order_no = bx_order_item."bx_order_Номер" 
              AND POSITION(':' in bx_order_item."Наименование") = 0
UNION
            SELECT bx_order_item.*
                , regexp_replace(bx_order_item."Наименование", '^.*: ', '')::VARCHAR AS mod_id
           FROM bx_order_item
           WHERE bx_order_no = bx_order_item."bx_order_Номер" 
             AND POSITION(':' in bx_order_item."Наименование") > 0
           ORDER BY id 
) LOOP
    --
    RAISE NOTICE 'Заказ=%, обрабатываем Товар=%, oi.mod_id=%', oi."bx_order_Номер", oi.Наименование, oi.mod_id;
    INSERT INTO aub_log(bx_order_no, mod_id, descr) VALUES(bx_order_no, oi.mod_id, format('Старт %s', oi."Наименование"));
    SELECT "КодСодержания","Поставщик" INTO loc_KS, vendor_id from vwsyncdev 
            WHERE vwsyncdev.mod_id = oi.mod_id;
    RAISE NOTICE 'loc_KS=%, vendor_id=%', loc_KS, vendor_id;
    
    IF (loc_KS is null) THEN
        CreateResult := GREATEST(2, CreateResult); -- есть не синхронизированная позиция в заказе
        PERFORM 1 FROM vw_bxsyncdev WHERE vw_bxsyncdev.mod_id = oi.mod_id;
        IF FOUND THEN
            loc_aub_msg := format('%s - позиция отсутствует в базе АРК', oi.Наименование);
        ELSE
            loc_aub_msg := format('%s - не синхронизированный прибор', oi.Наименование);
        END IF;
        INSERT INTO aub_log(bx_order_no, mod_id, descr, res_code) VALUES(bx_order_no, oi.mod_id, loc_aub_msg, CreateResult);
        RAISE NOTICE 'В заказе % % с mod_id=%', bx_order_no, loc_aub_msg, oi.mod_id;
    ELSE
       -- если Овен, "Поставщик" = 30049
       -- TODO вынести из цикла, написать один SELECT ANY или EXISTS
       IF 30049 = vendor_id AND NOT skipCheckOwen THEN
         flgOwen := TRUE;
       ELSE
         flgOwen := FALSE;
         skipCheckOwen := TRUE; -- если встретился 'не Овен', больше не проверяем
       END IF;
       
       loc_delivery_quantity := '';
       loc_in_stock := stock_availability_mod_id(oi.mod_id, TRUE, loc_KS);
       INSERT INTO aub_qnt_in_stock(bx_order_no, ks, mod_id, whqnt) VALUES(bx_order_no, loc_KS, oi.mod_id, loc_in_stock);
       RAISE NOTICE 'KS=%, loc_in_stock=%, нужно=%', loc_KS, loc_in_stock, oi."Количество";
       IF loc_in_stock >= oi."Количество" THEN -- достаточно на Ясной+Выставка
          CreateResult := GREATEST(1, CreateResult); -- если были несинхронизированные (2) или нехватка (6)

          -- DEBUG only
          INSERT INTO aub_log(bx_order_no, mod_id, descr, res_code) VALUES(bx_order_no, oi.mod_id, format(
             '%s(KS=%s) ОК [в наличии %s, нужно %s]', oi.Наименование, loc_KS, loc_in_stock, oi."Количество"
          ), 1 ); 

       ELSE -- недостаточно Ясная+Выставка
          loc_delivery_quantity := get_delivery_quantity(bx_order_no, oi."Ид");
          IF loc_delivery_quantity IS NOT NULL AND loc_delivery_quantity <> '' THEN
              CreateResult := GREATEST(1, CreateResult); -- если есть разбивка сроки-количество, создаём автосчёт
              -- DEBUG only
              INSERT INTO aub_log(bx_order_no, mod_id, descr, res_code) VALUES(bx_order_no, oi.mod_id, format(
                 '%s(KS=%s) синхронизирован, нужно [%s], со склада [%s]', oi.Наименование, loc_KS, oi."Количество", loc_in_stock
              ), CreateResult ); 
              INSERT INTO aub_log(bx_order_no, mod_id, descr, res_code) VALUES(bx_order_no, oi.mod_id, format(
                 '%s(KS=%s) указаны срок-количество=[%s]', oi.Наименование, loc_KS, loc_delivery_quantity
              ), CreateResult ); 
              RAISE NOTICE 'Для Ид строки заказа=% есть сроки-количество=%', oi."Ид", loc_delivery_quantity;
              -- часть со склада
              -- часть/части из идущих
              -- часть в сроки стандартной поставки
              -- loc_parts :=
          ELSE
              CreateResult := GREATEST(6, CreateResult); -- позиция заказа синхронизирована, но недостаточно количества
              -- TODO из идущих, т.к. позиция заказа синхронизирована, но недостаточно количества
              -- TODO loc_delivery_quantity := format('со склада: %s; : %s',  loc_in_stock, oi."Количество"-loc_in_stock); -- , get_expected_shipment(loc_KS, False));
              RAISE NOTICE 'Для KS=% нет достаточного количества=%', loc_KS, oi."Количество";
              INSERT INTO aub_log(bx_order_no, mod_id, descr, res_code) VALUES(bx_order_no, oi.mod_id, format(
                'Для %s(KS=%s) нужно [%s], доступно [%s]', oi.Наименование, loc_KS, oi."Количество", loc_in_stock
              ), CreateResult );
              /** DEBUG only **/
              FOR dbg_notice IN SELECT ' Склад=' || wh."Склад" || ', KS=' ||  "КодСодержания" 
                                        || ', qaulity=' || CASE quality WHEN 0 THEN 'надлежащее' ELSE 'некондиция' END --CASE
                                        || ', кол-во=' || SUM("НаСкладе" - COALESCE("Рез", 0))
                               FROM "vwСкладВсеПодробно" v
                               JOIN "Склады" wh ON v."КодСклада" = wh."КодСклада"
                               WHERE
                                    v."КодСклада" = ANY (valid_wh(1)) AND -- 1 autobil_creator ID
                                    "КодСодержания" = loc_KS
                                    GROUP BY wh."Склад", "КодСодержания", quality
              LOOP
                INSERT INTO aub_log(bx_order_no, mod_id, descr, res_code) VALUES(bx_order_no, oi.mod_id, dbg_notice, CreateResult);
              END LOOP;
              /** end of DEBUG **/
            END IF; -- loc_delivery_quantity IS NOT NULL
       END IF; -- достаточно на Ясной+Выставка
    END IF; -- loc_KS is not null

    SELECT oif.fvalue INTO loc_modificators FROM arc_energo.bx_order_item_feature oif
    WHERE oif."bx_order_Номер" = bx_order_no AND oif.bx_order_item_id = oi."Ид" 
          AND (oif.fname = 'Модификация' OR oif.fname = 'СвойствоКорзины#SKU_NAME');
    INSERT INTO tmp_order_items(ks, oi_id, oi_okei_code, oi_measure_unit, whid, oi_quantity, oi_delivery_qnt, oi_name, oi_mod_id, oi_modificators)
                        VALUES (loc_KS, oi."Ид", oi."Код", (SELECT "ЕдИзм" FROM "ОКЕИ" WHERE "КодОКЕИ" = oi."Код"),
                                2, -- Ясная
                                oi."Количество", loc_delivery_quantity, oi."Наименование", oi.mod_id, COALESCE(loc_modificators, ''));

    -- Для контроля "потерянных" позиций
    bx_sum := bx_sum + oi."Сумма";
    RAISE NOTICE 'boi loop CreateResult = %', CreateResult;
    INSERT INTO aub_log(bx_order_no, mod_id, descr) VALUES(bx_order_no,  oi.mod_id, format(
        'Финиш %s , результат=%s', oi.Наименование, CreateResult
    ));
END LOOP; -- orders item


-- Контроль "потерянных" позиций по сумме
SELECT "Сумма" INTO loc_sum FROM bx_order WHERE "Номер" = bx_order_no;
IF (loc_sum <> bx_sum) AND (1 = CreateResult) THEN
   CreateResult := 5;
   RAISE NOTICE 'Не совпадают bx_order_sum=%, items_sum=%', loc_sum, bx_sum; 
END IF;
IF (CreateResult IN (1,2,6) ) THEN -- включая частичный автосчёт
    -- TODO delete
    -- INSERT INTO aub_qnt_in_stock(bx_order_no, ks, whid, whqnt) SELECT bx_order_no, * FROM qnt_in_stock; -- DEBUG

    loc_firm_code := find_firm(bx_order_no);
    IF loc_firm_code > 0 THEN
        loc_emp_code := find_emp(bx_order_no, loc_firm_code);
        IF loc_emp_code > 0 THEN
            loc_OrderItemProcessingTime := 'В наличии'; -- для всего счёта: если Отправка, '1...3 рабочих дня' иначе '!Со склада'
            loc_delivery_qnt_flag := False;
            FOR item in SELECT * FROM tmp_order_items LOOP
                IF item.oi_delivery_qnt IS NOT NULL AND item.oi_delivery_qnt <> '' THEN
                   loc_delivery_qnt_flag := True;
                   EXIT;
                END IF;
            END LOOP;
            bill := fn_InsertBill(CreateResult, loc_sum, bx_order_no, loc_firm_code, loc_emp_code, flgOwen, loc_delivery_qnt_flag);
            Npp := 1;
            VAT := bill."ставкаНДС";
            loc_bill_no := bill."№ счета";

            SELECT count(*) INTO dbg_order_items_count FROM tmp_order_items ;
            RAISE NOTICE 'строк для счёта=%', dbg_order_items_count;

            FOR item in SELECT * FROM tmp_order_items LOOP
                real_discount := 0;
                PriceVAT := NULL;
                Price := NULL;
                loc_where_buy := NULL;
                loc_okei_code := NULL;
                loc_measure_unit := NULL;
                loc_item_name := NULL;
                loc_delivery_qnt_flag := False;
                loc_suspend_bill_msg_flag := False;
                loc_count_qnt := 0;
                loc_wrong_qnt := 0;
                RAISE NOTICE 'bx_order_no=%, tmp_order_items=%', bx_order_no, item;
                IF item.oi_delivery_qnt IS NOT NULL AND item.oi_delivery_qnt <> '' THEN
                    loc_delivery_qnt_flag := True;
                    if NOT bill."Дилерский" then 
                      loc_suspend_bill_msg_flag := True;
                      loc_suspend_bill_msg := ', но не отправлен клиенту';
                      CreateResult := GREATEST(10, CreateResult); -- для НЕ дилерских с разбивкой по срокам не уведомляем клиента
                    else -- только на период перехода к НДС 20% для ручного повышения цены на Резерв Идущий
                      -- ниже вернуть формирование в aub_log 'для НЕ-дилера'
                      loc_suspend_bill_msg_flag := True;
                      loc_suspend_bill_msg := ', но не отправлен дилеру';
                      CreateResult := GREATEST(14, CreateResult); -- даже для дилерских с разбивкой по срокам, т.е. с резервом из идущих
                    end if;
                   loc_OrderItemProcessingTime := item.oi_delivery_qnt; -- разбиение по ';' в заполнении шаблона libreoffice
                ELSE
                   loc_OrderItemProcessingTime := 'В наличии'; -- для всего счёта: если Отправка, '1...3 рабочих дня' иначе '!Со склада'
                END IF;
                --
                RAISE NOTICE 'loc_bill_no=%, item.ks=%', bill."№ счета", item.ks;
                -- TODO Выявлять услугу "Оплата доставки"

                loc_where_buy := '';
                IF item.ks IS NOT NULL THEN
                    WITH content AS (
                    SELECT "НазваниевСчет", "Цена", COALESCE("ОКЕИ", 796) AS "ОКЕИ" FROM "Содержание" s WHERE "КодСодержания" = item.ks)
                    SELECT content.*, o."ЕдИзм" into loc_item_name, loc_price, loc_okei_code, loc_measure_unit 
                    FROM content
                    JOIN "ОКЕИ" o on o."КодОКЕИ" = "ОКЕИ";

                    real_discount := dlr_discount(loc_firm_code, item.ks);
                    PriceVAT := loc_price*(100-real_discount)/100;
                    Price := PriceVAT*100/(100 + VAT);
                ELSE
                    loc_OrderItemProcessingTime := NULL; -- неопределено для несинхронизированных
                    loc_okei_code := item.oi_okei_code;
                    loc_measure_unit := item.oi_measure_unit;
                    loc_item_name := item.oi_name || E', ' || item.oi_modificators; -- для несинхронизированных позиций имя с сайта
                    RAISE NOTICE 'loc_bill_no=%, NOT synced loc_item_name=%', bill."№ счета", loc_item_name;
                END IF;

                /** Наименование для Фискального накопителя перекрывает предыдущее наименование ***/
                loc_1C_article := NULL;
                IF is_payment_method_fiscal(bx_order_no) THEN -- Яндекс.Касса
                    loc_item_name := he_decode( substring (
                                                format('%s %s', COALESCE(fiscal_name(item.oi_mod_id), item.oi_name), item.oi_modificators)
                                                from 1 for 128)
                                              );
                    RAISE NOTICE 'loc_bill_no=%, FISCAL loc_item_name=%', bill."№ счета", loc_item_name;
                    loc_1C_article := get_code1c4artikul(loc_kp);
                END IF;
                /***/

                WITH inserted AS (
                   INSERT INTO "Содержание счета"
                        ("№ счета",
                        "КодСодержания", "КодОКЕИ", "Ед Изм", "Кол-во",
                        "Срок2",
                        "ПозицияСчета", "Наименование",
                        "Цена", "ЦенаНДС", "Скидка",
                        -- "Гдезакупать", "Артикул1С")
                        "Артикул1С")
                        VALUES (loc_bill_no,
                        item.ks, loc_okei_code, loc_measure_unit, item.oi_quantity,
                        loc_OrderItemProcessingTime,
                        npp, loc_item_name,
                        round(Price, 2), PriceVAT, 0-real_discount,
                        -- loc_where_buy, loc_1C_article) 
                        loc_1C_article) 
                    RETURNING * 
                ) SELECT * INTO inserted_bill_item FROM inserted;
                Npp := Npp+1;

                loc_lack_reserve := 0;
                -- SELECT "Номер" INTO our_emp_id FROM "Сотрудники" WHERE bill."Хозяин" = "Менеджер";

                IF item.ks IS NOT NULL THEN -- далее только для товаров с КС
                    loc_no_autobill_item := no_autobill_item(item.ks); -- не для автосчёта (стопХ)
                    IF loc_no_autobill_item THEN -- не для автосчёта (стопХ)
                        CreateResult := 11; -- имеет флаг СТОП
                        loc_lack_reason := format('№ счёта=%s, %s(KS=%s) имеет флаг СТОП, автосчёт не будет отправлен клиенту',
                               loc_bill_no, item.oi_name, item.ks);
                        INSERT INTO aub_log(bx_order_no, descr, res_code, mod_id) VALUES(bx_order_no, loc_lack_reason, CreateResult, get_mod_id(item.ks));
                        PERFORM push_arc_article(bill."Хозяин", loc_lack_reason, importance := 1);
                    ELSE
                        IF loc_delivery_qnt_flag THEN -- разбивка сроки-количество
                            IF loc_suspend_bill_msg_flag THEN
                               INSERT INTO aub_log(bx_order_no, mod_id, descr, res_code) VALUES(bx_order_no, item.oi_mod_id, format(
                                  -- '%s(KS=%s) для НЕ-дилера обрабатываем срок-количество=[%s], но не отправляем автосчёт', item.oi_name, item.ks, item.oi_delivery_qnt
                                  '%s(KS=%s) обрабатываем срок-количество=[%s], но не отправляем автосчёт', item.oi_name, item.ks, item.oi_delivery_qnt
                                 ), CreateResult ); 
                            END IF;
                            SELECT * INTO loc_lack_reserve, loc_lack_reason FROM reserve_partly(item.oi_delivery_qnt, loc_bill_no, item.ks);
                            RAISE NOTICE 'разбивка сроки-количество: % loc_lack_reserve: %', item.oi_delivery_qnt, loc_lack_reserve;
                            loc_count_qnt := count_time_qnt(item.oi_delivery_qnt);
                            loc_wrong_qnt := item.oi_quantity - loc_count_qnt;
                            if loc_wrong_qnt != 0 then -- некорректная разбивка сроки-количество
                                CreateResult := 13; -- некорректная разбивка сроки-количество
                                loc_aub_msg := format('%s(KS=%s) кол-во в разбивке срок-количество=%s[%s] отличается от заказанного=[%s] на {%s}', 
                                      item.oi_name, item.ks, loc_count_qnt, item.oi_delivery_qnt, item.oi_quantity, loc_wrong_qnt);
                                INSERT INTO aub_log(bx_order_no, mod_id, descr, res_code) VALUES(bx_order_no, item.oi_mod_id, 
                                loc_aub_msg, CreateResult); 
                                RAISE NOTICE '%. CreateResult=%', loc_aub_msg, CreateResult;
                            end if;

                            IF loc_lack_reserve = 0 AND loc_wrong_qnt = 0 THEN
                                -- TODO заменить на Рез.склада, ЖДЁМ. АБ/ВВ не д.б. для loc_lack_reserve = 0
                                loc_where_buy := regexp_replace(item.oi_delivery_qnt, E'со склада', E'Рез.склада');
                                loc_where_buy := regexp_replace(loc_where_buy, E'к ', E'ЖДЁМ ', 'g'); -- global
                            END IF;
                        ELSE -- без разбивки сроки-количество
                            -- loc_lack_reserve := setup_reserve(loc_bill_no, item.ks, item.oi_quantity);
                            loc_lack_reserve := ctr_reserve2(loc_bill_no, item.ks, item.oi_quantity);
                            loc_lack_reason := NULL;
                            loc_where_buy := 'Рез.склада';
                            RAISE NOTICE 'без разбивки сроки-количество, loc_lack_reserve: %', loc_lack_reserve;
                        END IF;

                        -- Извещение о неудачном резерве
                        IF loc_lack_reserve <> 0 THEN -- ВН может вернуть -1
                            -- TODO рассмотреть: CreateResult := GREATEST(7, CreateResult);
                            CreateResult := 7; -- не удалось создать резерв
                            -- UPDATE "Содержание счета" SET "Срок2" = NULL, "Гдезакупать" = NULL WHERE "КодПозиции" = inserted_bill_item."КодПозиции";
                            loc_lack_reason := format('№ счёта=%s, %s(KS=%s) не удалось поставить в резерв %s из %s, причина: %s',
                                   loc_bill_no, item.oi_name, item.ks, loc_lack_reserve, item.oi_quantity, COALESCE(loc_lack_reason, 'нет в наличии') );
                            INSERT INTO aub_log(bx_order_no, descr, res_code, mod_id) VALUES(bx_order_no, loc_lack_reason, CreateResult, get_mod_id(item.ks));
                            PERFORM push_arc_article(bill."Хозяин", loc_lack_reason, importance := 1);
                        END IF; -- loc_lack_reserve <> 0
                    END IF; -- loc_no_autobill_item
                END IF; -- locKS IS NOT NULL
            END LOOP; -- позиции счёта
            IF CreateResult = 7 THEN
                loc_aub_msg := format('Автосчёт {%s} создан, но не удалось поставить все резервы', bill."№ счета");
            ELSE 
                loc_aub_msg := format('Автосчёт создан {%s}%s', bill."№ счета", coalesce(loc_suspend_bill_msg, ''));
            END IF;
            INSERT INTO aub_log(bx_order_no, descr, res_code, mod_id) VALUES(bx_order_no, loc_aub_msg, CreateResult, -1);
        ELSE -- loc_emp_code < 0 
            CreateResult := 8; -- bad Employee
            loc_aub_msg := format('Автосчёт не создан, причина=%s', bad_employee_reason(loc_emp_code));
            INSERT INTO aub_log(bx_order_no, descr, res_code, mod_id) VALUES(bx_order_no, loc_aub_msg, CreateResult, -1);
            RAISE NOTICE '%. CreateResult=%', loc_aub_msg, CreateResult;
        END IF;
    ELSE -- loc_firm_code < 0
        CreateResult := 9; -- bad Firm
        loc_aub_msg := format('Автосчёт не создан, причина=%s', bad_firm_reason(loc_firm_code));
        INSERT INTO aub_log(bx_order_no, descr, res_code, mod_id) VALUES(bx_order_no, '' || loc_aub_msg, CreateResult, -1);
        RAISE NOTICE '%. CreateResult=%', loc_aub_msg, CreateResult;
    END IF;
ELSE -- NOT CreateResult IN (1,2,6)
    INSERT INTO aub_log(bx_order_no, descr, res_code, mod_id) VALUES(bx_order_no, 'Автосчёт не создан', CreateResult, -1);
END IF; -- CreateResult IN (1,2,6)

UPDATE bx_order SET billcreated = CreateResult, "Счет" = loc_bill_no WHERE "Номер" = bx_order_no ;

TRUNCATE tmp_order_items;

RETURN CreateResult;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
