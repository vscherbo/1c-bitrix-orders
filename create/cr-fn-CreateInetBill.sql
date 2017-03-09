-- Function: fn_createinetbill(integer)

-- DROP FUNCTION fn_createinetbill(integer);

CREATE OR REPLACE FUNCTION fn_createinetbill(bx_order_no integer)
  RETURNS integer AS
$BODY$
DECLARE
   oi RECORD;
   soderg RECORD;
   bill RECORD;
   loc_KS integer;
   CreateResult integer;
   item RECORD;
   item_id integer;
   Npp INTEGER;
   INN VARCHAR;
   KPP VARCHAR;
   VAT numeric;
   bill_no INTEGER;
   Price NUMERIC;
   PriceVAT NUMERIC; 
   bx_sum NUMERIC;
   EmpRec RECORD;
   loc_OrderItemProcessingTime varchar;
   inserted_bill_item RECORD;
   our_emp_id INTEGER;
   vendor_id INTEGER;
   flgOwen BOOLEAN;
   skipCheckOwen BOOLEAN;
   ourFirm VARCHAR;
   debug_rec RECORD;
   loc_in_stock NUMERIC; 
   loc_in_stock_wh NUMERIC; -- склад Ясная
   loc_in_stock_exh NUMERIC; -- склад Выставка
   loc_lack_wh NUMERIC; -- не хватает на Ясной для заказанного количества
   real_discount INTEGER;
   vw_notice VARCHAR;
   mstr VARCHAR;
   message_id INTEGER;
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
   loc_buyer_id INTEGER;
   loc_buyer_name VARCHAR;
   loc_email VARCHAR;
   loc_is_valid BOOLEAN := FALSE;
BEGIN
RAISE NOTICE '##################### Начало fn_createinetbill, заказ=%', bx_order_no;
INSERT INTO aub_log(bx_order_no, descr, mod_id) VALUES(bx_order_no, 'Начало обработки заказа', -1);

SELECT * INTO loc_buyer_id, loc_buyer_name, loc_email, loc_is_valid FROM get_bx_order_ids(bx_order_no) ;
-- IF is_bx_order_valid(bx_order_no) THEN
IF loc_is_valid THEN
    CreateResult := 3; -- инициируем значением "пустой состав заказа"
    bx_sum := 0;
ELSE
    CreateResult := 4; -- отменённый или неполный заказ, покупатель или отсутствуют оба 'EMail' и 'Контактный email'
    RETURN CreateResult;
END IF;

CREATE TEMPORARY TABLE IF NOT EXISTS tmp_order_items(ks integer, oi_id TEXT, oi_okei_code integer, oi_measure_unit character varying(50), whid integer, oi_quantity numeric(18,3), oi_delivery_qnt TEXT);
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
                                    AND bx_order_item_feature.fname = 'КодМодификации'
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
    INSERT INTO aub_log(bx_order_no, mod_id, descr) VALUES(bx_order_no, oi.mod_id, format('Старт %s', oi.Наименование));
    SELECT "КодСодержания","Поставщик" INTO loc_KS, vendor_id from vwsyncdev 
            WHERE vwsyncdev.mod_id = oi.mod_id;
    RAISE NOTICE 'loc_KS=%, vendor_id=%', loc_KS, vendor_id;
    
    IF (loc_KS is null) THEN
       CreateResult := 2; -- есть не синхронизированная позиция в заказе
       RAISE NOTICE 'В заказе %  не синхронизированная позиция с mod_id=%', bx_order_no, oi.mod_id;
       INSERT INTO aub_log(bx_order_no, mod_id, descr, res_code) VALUES(bx_order_no, oi.mod_id,  format(
        '%s - не синхронизированная позиция', oi.Наименование
       ), CreateResult );
       -- не прерываем обработку! EXIT; -- дальше не проверяем
    ELSE
       -- если Овен, "Поставщик" = 30049
       IF 30049 = vendor_id AND NOT skipCheckOwen THEN
         flgOwen := TRUE;
       ELSE
         flgOwen := FALSE;
         skipCheckOwen := TRUE; -- если встретился 'не Овен', больше не проверяем
       END IF;
       
       INSERT INTO qnt_in_stock(ks, whid, whqnt) SELECT loc_KS, (is_in_stock(loc_KS)).* ;
       loc_in_stock := 0;
       loc_in_stock := COALESCE(
                           (SELECT SUM(whqnt) FROM qnt_in_stock WHERE qnt_in_stock.ks = loc_KS)
                           , 0);
       RAISE NOTICE 'KS=%, loc_in_stock=%, нужно=%', loc_KS, loc_in_stock, oi."Количество";
       IF loc_in_stock >= oi."Количество" THEN -- достаточно на Ясной+Выставка
          IF CreateResult NOT IN (2,6) THEN 
             CreateResult := 1; -- позиция заказа синхронизирована
          END IF;    
          INSERT INTO aub_log(bx_order_no, mod_id, descr, res_code) VALUES(bx_order_no, oi.mod_id, format(
             '%s(KS=%s) синхронизирован и есть на складе [%s]', oi.Наименование, loc_KS, loc_in_stock
          ), 1 ); 

          INSERT INTO tmp_order_items(ks, oi_id, oi_okei_code, oi_measure_unit, whid, oi_quantity)
                              VALUES (loc_KS, oi."Ид", oi."Код", (SELECT "ЕдИзм" FROM "ОКЕИ" WHERE "КодОКЕИ" = oi."Код"),
                                      2, -- Ясная
                                      oi."Количество");
        /**
          SELECT SUM(whqnt) INTO loc_in_stock_wh FROM qnt_in_stock WHERE whid=2 AND qnt_in_stock.ks = loc_KS; -- только Ясная
          RAISE NOTICE 'KS=%, loc_in_stock_wh2=%, нужно=%', loc_KS, loc_in_stock_wh, oi."Количество";
          IF loc_in_stock_wh >= oi."Количество" THEN -- на Ясной хватает
              INSERT INTO tmp_order_items(ks, oi_okei_code, oi_measure_unit, whid, oi_quantity)
                     VALUES (loc_KS, oi."Код", (SELECT "ЕдИзм" FROM "ОКЕИ" WHERE "КодОКЕИ" = oi."Код"),
                             2, -- Ясная
                             oi."Количество");
          ELSE -- на Ясной НЕ хватает
              RAISE NOTICE 'На Ясной не хватило, берём с  Выставки (склад 5)';
              INSERT INTO tmp_order_items(ks, oi_okei_code, oi_measure_unit, whid, oi_quantity)
                     VALUES (loc_KS, oi."Код", (SELECT "ЕдИзм" FROM "ОКЕИ" WHERE "КодОКЕИ" = oi."Код"),
                             2, -- Ясная
                             loc_in_stock_wh); -- с Ясной резервируем сколько есть.
              SELECT SUM(whqnt) INTO loc_in_stock_exh FROM qnt_in_stock WHERE whid=5 AND qnt_in_stock.ks = loc_KS;
              loc_lack_wh := oi."Количество" - loc_in_stock_wh; -- столько не хватает на Ясной
              IF loc_in_stock_exh >= loc_lack_wh THEN -- кол-ва на Выставке хватает 
                 -- INSERT whid=5, loc_in_stock_exh
                  INSERT INTO tmp_order_items(ks, oi_okei_code, oi_measure_unit, whid, oi_quantity)
                         VALUES (loc_KS, oi."Код", (SELECT "ЕдИзм" FROM "ОКЕИ" WHERE "КодОКЕИ" = oi."Код"),
                                 5, -- Выставка
                                 loc_lack_wh); -- с Выставки резервируем остаток.
              END IF; -- кол-ва на Выставке хватает
          END IF; -- на Ясной хватает
        **/
       ELSE -- недостаточно Ясная+Выставка
          /**/
          loc_delivery_quantity := get_delivery_quantity(oi."Ид");
          IF loc_delivery_quantity IS NOT NULL AND loc_delivery_quantity <> '' THEN
              CreateResult := 8; -- если есть разбивка сроки-количество, создаём автосчёт
              RAISE NOTICE 'Для mod_id=% есть сроки-количество=%', oi."Ид", loc_delivery_quantity;
              -- часть со склада
              -- часть/части из идущих
              -- часть в сроки стандартной поставки
              -- loc_parts :=
              INSERT INTO tmp_order_items(ks, oi_okei_code, oi_measure_unit, whid, oi_quantity, oi_delivery_qnt)
                     VALUES (loc_KS, oi."Код", (SELECT "ЕдИзм" FROM "ОКЕИ" WHERE "КодОКЕИ" = oi."Код"),
                             2, -- Ясная
                             oi."Количество", loc_delivery_quantity);
          ELSE
               /**/
              CreateResult := 6; -- позиция заказа синхронизирована, но недостаточно количества
              RAISE NOTICE 'Для KS=% нет достаточного количества=%', loc_KS, oi."Количество";
              INSERT INTO aub_log(bx_order_no, mod_id, descr, res_code) VALUES(bx_order_no, oi.mod_id, format(
                'Для %s(KS=%s) нужно [%s], доступно [%s]', oi.Наименование, loc_KS, oi."Количество", loc_in_stock
              ), CreateResult );
              /** DEBUG only **/
              FOR vw_notice IN SELECT ' Склад=' || wh."Склад" || ', KS=' ||  "КодСодержания" 
                                        || ', qaulity=' || CASE quality WHEN 0 THEN 'надлежащее' ELSE 'некондиция' END --CASE
                                        || ', кол-во=' || SUM("НаСкладе" - COALESCE("Рез", 0))
                               FROM "vwСкладВсеПодробно" v
                               JOIN "Склады" wh ON v."КодСклада" = wh."КодСклада"
                               WHERE
                                    v."КодСклада" In (2,5) AND
                                    "КодСодержания" = loc_KS
                                    GROUP BY wh."Склад", "КодСодержания", quality
              LOOP
                INSERT INTO aub_log(bx_order_no, mod_id, descr, res_code) VALUES(bx_order_no, oi.mod_id, vw_notice, CreateResult);
              END LOOP;
              /** end of DEBUG **/
              -- не прерываем обработку! EXIT; -- дальше не проверяем
            END IF; -- loc_delivery_quantity IS NOT NULL
       END IF; -- достаточно на Ясной+Выставка
    END IF; -- loc_KS is not null
    -- Для контроля "потерянных" позиций
    bx_sum := bx_sum + oi."Сумма";
    RAISE NOTICE 'CreateResult = %', CreateResult;
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
-- 
IF (CreateResult = 1) THEN -- все позиции заказа синхронизированы и достаточное количество на складе
    INSERT INTO aub_qnt_in_stock(bx_order_no, ks, whid, whqnt) SELECT bx_order_no, * FROM qnt_in_stock; -- DEBUG
    -- EmpRec := get_emp(bx_order_no);
    SELECT "out_КодРаботника" AS "КодРаботника", "out_Код" AS "Код", "out_ЕАдрес" AS "ЕАдрес" FROM get_emp(bx_order_no) INTO EmpRec;

    RAISE NOTICE 'Получили для счёта Код=%, КодРаботника=%, ЕАдрес=%', EmpRec."Код", quote_nullable(EmpRec."КодРаботника"), quote_nullable(EmpRec."ЕАдрес") ;

    IF EmpRec."Код" IS NOT NULL THEN
        ourFirm := getFirm(EmpRec."Код", flgOwen);
        loc_OrderItemProcessingTime := 'В наличии'; -- для всего счёта: если Отправка, '1...3 рабочих дня' иначе '!Со склада'
        bill := fn_InsertBill(loc_sum, bx_order_no, EmpRec."Код", EmpRec."КодРаботника", ourFirm);
        Npp := 1;
        VAT := bill."ставкаНДС";
        bill_no := bill."№ счета";

        FOR item in SELECT * FROM tmp_order_items LOOP
            IF item.oi_delivery_qnt IS NOT NULL THEN
               -- loc_OrderItemProcessingTime := OrderItem_ProcessingTime(item.ks);
               loc_OrderItemProcessingTime := item.oi_delivery_qnt; -- TODO разбить по ';'
            ELSE
               loc_OrderItemProcessingTime := 'В наличии'; -- для всего счёта: если Отправка, '1...3 рабочих дня' иначе '!Со склада'
            END IF;
            SELECT "НазваниевСчет", "Цена" INTO soderg FROM "Содержание" s WHERE s."КодСодержания" = item.ks;

            real_discount := dlr_discount(EmpRec."Код", item.ks);
            PriceVAT := soderg."Цена"*(100-real_discount)/100;

            Price := PriceVAT*100/(100 + VAT);
            --
            RAISE NOTICE 'bill_no=%, item.ks=%', bill."№ счета", item.ks;
            -- TODO Выявлять услугу "Оплата доставки"

            WITH inserted AS (
               INSERT INTO "Содержание счета"
                    ("КодПозиции",
                    "№ счета",
                    "КодСодержания", "КодОКЕИ", "Ед Изм", "Кол-во",
                    "Срок2",
                    "ПозицияСчета", "Наименование",
                    "Цена", "ЦенаНДС",
                    "Гдезакупать")
                    VALUES ((SELECT max("КодПозиции")+1 FROM "Содержание счета"),
                    bill_no,
                    item.ks, item.oi_okei_code, item.oi_measure_unit, item.oi_quantity,
                    loc_orderitemprocessingtime,
                    npp, soderg."НазваниевСчет",
                    round(Price, 2), PriceVAT,
                    'Рез.склада') 
             RETURNING * 
             ) SELECT * INTO inserted_bill_item FROM inserted;
             Npp := Npp+1;

            loc_lack_reserve := 0;
            SELECT "Номер" INTO our_emp_id FROM "Сотрудники" WHERE bill."Хозяин" = "Менеджер";
            IF item.oi_delivery_qnt IS NOT NULL AND item.oi_delivery_qnt <> '' THEN -- разбивка сроки-количество
                SELECT * INTO loc_lack_reserve, loc_lack_reason FROM reserve_partly(item.oi_delivery_qnt, bill_no, item.ks);
                RAISE NOTICE 'разбивка сроки-количество: % loc_lack_reserve: %', item.oi_delivery_qnt, loc_lack_reserve;
            ELSE -- без разбивки сроки-количество
                loc_lack_reserve := setup_reserve(bill_no, item.ks, item.oi_quantity);
                RAISE NOTICE 'без разбивки сроки-количество, loc_lack_reserve: %', loc_lack_reserve;
            END IF;

            -- Извещение о неудачном резерве
            IF loc_lack_reserve  > 0 THEN
                CreateResult := 7; -- не удалось создать резерв
                loc_lack_reason := format('Счёт %s: для KS=%s не удалось поставить в резерв %s из %s, причина: %s',
                       bill_no, item.ks, loc_lack_reserve, item.oi_quantity, quote_nullable(loc_lack_reason) );
                INSERT INTO aub_log(bx_order_no, descr) VALUES(bx_order_no, loc_lack_reason);
                PERFORM push_arc_article(bill."Хозяин", loc_lack_reason, importance := 1);
                                --'Счёт: ' || bill_no || ', КодСодержания: ' || item.ks ||
                                -- ', нужно: ' || item.oi_quantity || ', НЕ удалось поставить в резерв:' || loc_lack_reserve,
            END IF;
        END LOOP;
        IF CreateResult = 7 THEN
            loc_aub_msg := format('Автосчёт {%s} создан, но не удалось поставить все резервы', bill."№ счета");
        ELSE 
            loc_aub_msg := format('Автосчёт создан {%s}', bill."№ счета");
        END IF;
        INSERT INTO aub_log(bx_order_no, descr, res_code, mod_id) VALUES(bx_order_no, loc_aub_msg, CreateResult, -1);

    ELSE -- Код IS NULL
        CreateResult := 9; -- bad Firm
        RAISE NOTICE 'Невозможно определить Код Предприятия. Счёт не создан. bx_order.billcreated=%', CreateResult;
    END IF;
ELSE
    INSERT INTO aub_log(bx_order_no, descr, res_code, mod_id) VALUES(bx_order_no, 'Автосчёт не создан', CreateResult, -1);
END IF; -- CreateResult = 1



UPDATE bx_order SET billcreated = CreateResult, "Счет" = bill_no WHERE "Номер" = bx_order_no ;

TRUNCATE tmp_order_items;

RETURN CreateResult;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_createinetbill(integer)
  OWNER TO arc_energo;
