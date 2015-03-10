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
   -- arrMesUnits varchar[];
   item varchar;
   item_str varchar;
   EmpCode integer;
   item_id integer;
   Npp INTEGER;
   -- OKEIcode integer;
   INN VARCHAR;
   KPP VARCHAR;
   VAT numeric;
   bill_no INTEGER;
   Price numeric;
   flgLegalEntity BOOLEAN;
BEGIN
SELECT fvalue INTO INN
    FROM bx_order_feature 
    WHERE "bx_order_Номер" = bx_order_no AND fname = 'ИНН';
flgLegalEntity := found; 

SELECT bo.*, bb.bx_name, bf.fvalue AS email INTO o 
    FROM bx_order bo, bx_buyer bb, bx_order_feature bf
    WHERE 
        bo."Номер" = bx_order_no 
        AND bo.bx_buyer_id = bb.bx_buyer_id
        AND (bo."Номер" = bf."bx_order_Номер" AND bf.fname = 'Контактный email');
CreateResult := 3; -- пустой состав заказа
FOR oi in SELECT * FROM bx_order_item WHERE o."Номер" = "bx_order_Номер" ORDER BY id LOOP
    --RAISE NOTICE 'Товар=%', oi.Наименование;
    SELECT "КодСодержания" into KS from vwsyncdev WHERE ie_name = oi."Наименование";
    IF (KS is null) THEN
       CreateResult := 2; -- есть не синхронизированная позиция в заказе
       RAISE NOTICE 'The order % has not synched items. Skip this order', bx_order_no;
       EXIT; -- дальше не проверяем
    ELSE
       CreateResult := 1; -- позиция заказа синхронизирована
       item_str := format(' %s, %s, ''%s'', %s', KS, oi."Код", (SELECT "ЕдИзм" FROM "ОКЕИ" WHERE "КодОКЕИ" = oi."Код") , oi."Количество");
       -- RAISE NOTICE ' format item_str=%', item_str;
       arrOrderItems := array_append(arrOrderItems, item_str);
       -- arrMesUnits := array_append(arrMesUnits, oi."Код");
    END IF;    
    
END LOOP; -- orders item

--  RAISE NOTICE 'CreateResult = %', CreateResult;
IF (CreateResult = 1) THEN -- все позиции заказа синхронизированы
   EmpCode := fn_GetEmpCode(o.bx_buyer_id, o.bx_name, o.email);
   bill := fn_InsertBill(o."Сумма", o."Номер", EmpCode);
   -- RAISE NOTICE 'SELECT fn_GetEmpCode(%,%,%)', o.bx_buyer_id, o.name, o.email;
   Npp := 1;
   VAT := bill."ставкаНДС";
   bill_no := bill."№ счета";
   FOREACH item IN ARRAY arrOrderItems loop
      -- item_str := concat('item_id := fn_InsertBillItem(', bill."№ счета", item) ;
      SELECT "НазваниевСчет", "Цена" INTO soderg FROM "Содержание" s WHERE s."КодСодержания" = KS;
      -- SELECT "КодОКЕИ" INTO OKEIcode FROM "ОКЕИ" WHERE "ЕдИзм" = arrMesUnits[Npp];
      Price := soderg."Цена"*100/(100 + VAT);
      -- RAISE NOTICE 'bill_no=%, item=%', bill."№ счета", item;
      
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
END IF;
UPDATE bx_order SET billcreated = CreateResult, "Счет" = bill_no WHERE "Номер" = bx_order_no ;
  
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_createinetbill(integer)
  OWNER TO arc_energo;
