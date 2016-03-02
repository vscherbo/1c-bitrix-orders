-- Function: fn_createinetbill(integer)

-- DROP FUNCTION fn_createinetbill(integer);

CREATE OR REPLACE FUNCTION fn_createinetbill(bx_order_no integer)
  RETURNS void AS
$BODY$
DECLARE
   oi record;
   o record;
   soderg RECORD;
   bill record;
   KS integer;
   CreateResult integer;
   arrOrderItems varchar[];
   item varchar;
   item_str varchar;
   item_id integer;
   Npp INTEGER;
   INN VARCHAR;
   KPP VARCHAR;
   VAT numeric;
   bill_no INTEGER;
   Price numeric;
   bx_sum NUMERIC;
   EmpRec RECORD;
BEGIN
RAISE NOTICE 'Начало fn_createinetbill';

SELECT bo.*, bb.bx_name, bf.fvalue AS email INTO o
    FROM vw_bx_actual_order bo, bx_buyer bb, bx_order_feature bf
    WHERE 
        bo."Номер" = bx_order_no
        AND bo.bx_buyer_id = bb.bx_buyer_id
        AND (bo."Номер" = bf."bx_order_Номер" AND bf.fname = 'Контактный email')
UNION
SELECT bo.*, bb.bx_name, bf.fvalue AS email
    FROM vw_bx_actual_order bo, bx_buyer bb, bx_order_feature bf
    WHERE 
        bo."Номер" = bx_order_no
        AND bo.bx_buyer_id = bb.bx_buyer_id
        AND (bo."Номер" = bf."bx_order_Номер" AND bf.fname = 'EMail');     

IF o IS NULL THEN
   CreateResult := 4; -- неполный заказ, покупатель или отсутствуют оба 'EMail' и 'Контактный email'
END IF;

CreateResult := 3; -- пустой состав заказа
bx_sum := 0;
FOR oi in SELECT bx_order_item.*, bx_order_item_feature.fvalue as mod_id 
                 FROM bx_order_item
                 LEFT JOIN bx_order_item_feature ON bx_order_item_feature.bx_order_item_id = bx_order_item."Ид" 
                                            AND bx_order_item_feature."bx_order_Номер" = bx_order_item."bx_order_Номер"
                                            AND bx_order_item_feature.fname = 'КодМодификации'
                 WHERE o."Номер" = bx_order_item."bx_order_Номер" 
                 ORDER BY id 
                 LOOP
    --
    RAISE NOTICE 'Товар=%', oi.Наименование;
    -- TODO split oi.Наименование by ":" to get 2nd part (order_mod_id)
    -- SELECT "КодСодержания" into KS FROM "Содержание" WHERE mod_id = order_mod_id;
    SELECT "КодСодержания" into KS from vwsyncdev WHERE dev_name = oi."Наименование" OR mod_id = oi.mod_id;
    IF (KS is null) THEN
       CreateResult := 2; -- есть не синхронизированная позиция в заказе
       RAISE NOTICE 'The order % has not synched items. Skip this order', bx_order_no;
       EXIT; -- дальше не проверяем
    ELSE
       CreateResult := 1; -- позиция заказа синхронизирована
       item_str := format(' %s, %s, ''%s'', %s', KS, oi."Код", (SELECT "ЕдИзм" FROM "ОКЕИ" WHERE "КодОКЕИ" = oi."Код") , oi."Количество");
       -- 
       RAISE NOTICE ' format item_str=%', item_str;
       arrOrderItems := array_append(arrOrderItems, item_str);
    END IF;    
    -- Для контроля "потерянных" позиций
    bx_sum := bx_sum + oi."Сумма";
END LOOP; -- orders item

-- Контроль "потерянных" позиций по сумме
IF (o."Сумма" <> bx_sum) AND (CreateResult = 5) THEN
   CreateResult := 5;
   RAISE NOTICE 'bx_order_sum=%, items_sum=%', o."Сумма", bx_sum; 
END IF;
--  
RAISE NOTICE 'CreateResult = %', CreateResult;
IF (CreateResult = 1) THEN -- все позиции заказа синхронизированы
    EmpRec := fn_GetEmpCode(o.bx_buyer_id, o."Номер");
    RAISE NOTICE 'FirmCode=%, EmpCode=%', EmpRec."Код", EmpRec."КодРаботника" ;

    IF EmpRec."Код" is NOT NULL THEN
        bill := fn_InsertBill(o."Сумма", o."Номер", EmpRec."Код", EmpRec."КодРаботника");
        Npp := 1;
        VAT := bill."ставкаНДС";
        bill_no := bill."№ счета";
        FOREACH item IN ARRAY arrOrderItems loop
            SELECT "НазваниевСчет", "Цена" INTO soderg FROM "Содержание" s WHERE s."КодСодержания" = KS;
            Price := soderg."Цена"*100/(100 + VAT);
            --
            RAISE NOTICE 'bill_no=%, item=%', bill."№ счета", item;
            -- TODO Выявлять услугу "Оплата доставки"
      
            EXECUTE E'INSERT INTO "Содержание счета" '
                    || E'("КодПозиции", '
                    || E'"№ счета", '
                    || E'"КодСодержания", "КодОКЕИ", "Ед Изм", "Кол-во", '
                    || E'"ПозицияСчета", "Наименование", '
                    || E'"Цена", "ЦенаНДС") '
                    || E'VALUES ((SELECT MAX("КодПозиции")+1 FROM "Содержание счета"), '
                    || bill_no || ', ' -- '"№ счета"
                    || item || ', '  -- "КодСодержания", "КодОКЕИ", "Ед Изм", "Кол-во",'
                    || Npp || ', ''' || soderg."НазваниевСчет" || ''', '  -- '"ПозицияСчета", "Наименование", '
                    || round(Price, 2)  || ', ' || soderg."Цена" -- '"Цена", "ЦенаНДС") '
                    || ');' ;
            Npp := Npp+1;      
        END LOOP;
    ELSE -- Код IS NULL
        CreateResult := 9; -- bad Firm
        RAISE NOTICE 'Невозможно определить Код Предприятия. Счёт не создан. bx_order.billcreated=%', CreateResult;
    END IF;
END IF;
UPDATE bx_order SET billcreated = CreateResult, "Счет" = bill_no WHERE "Номер" = bx_order_no ;
  
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_createinetbill(integer)
  OWNER TO arc_energo;
