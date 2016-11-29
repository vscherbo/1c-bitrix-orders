-- Function: setup_reserve_expected(integer, integer, double precision, timestamp without time zone)

-- DROP FUNCTION setup_reserve_expected(integer, integer, double precision, timestamp without time zone);

CREATE OR REPLACE FUNCTION setup_reserve_expected(
    IN bill_no integer,
    IN ks integer,
    IN kol double precision,
    IN expected_date timestamp without time zone,
    OUT residual integer,
    OUT message character varying)
  RETURNS record AS
$BODY$DECLARE

	rs RECORD;
	--bill_no INTEGER; 
	--ks INTEGER;
	kol0 DOUBLE PRECISION;
	--kol DOUBLE PRECISION;

	condition character varying;
	kod integer default 0;
	kr INTEGER;
	msg  character varying;

BEGIN
-- SELECT * FROM setup_reserve_expected (12201063,108004471,2, null)
kol0:= kol;
SELECT Код INTO kod FROM arc_energo.Счета WHERE "№ счета"= bill_no;

IF  expected_date IS NULL THEN
	condition:= '';
ELSE
	condition:= ' AND sz.ДатаОжидания =' || quote_literal(expected_date);
END IF;

 

condition := 'SELECT sz.КодСпискаЗаказа, ДатаОжидания, Количество Идет, coalesce(r.Рез2,0) Рез '
	|| 'FROM СписокЗаказа sz '
	|| 'LEFT JOIN ' 
	|| '	(SELECT КодСпискаЗаказа, Sum(Резерв) as Рез2 '
	|| '	FROM РезервИдущий WHERE КогдаСнял IS NULL AND КодСодержания =' || ks || ' '
	|| '	GROUP BY КодСпискаЗаказа) r '
	|| 'ON  sz.КодСпискаЗаказа=r.КодСпискаЗаказа '
	|| 'WHERE NOT Выполнен AND NOT Отменен AND КодСодержания =' || ks || ' '
	|| condition
	|| '  ORDER BY sz.ДатаОжидания ';


--RAISE NOTICE '%',condition;

FOR rs IN 
	EXECUTE condition
LOOP 
	RAISE NOTICE 'Проверка1';
	IF kol>0 AND coalesce(rs.Идет-rs.Рез,0) >0 THEN
	
		SELECT Max(КодРезерва) +1 INTO kr FROM РезервИдущий; 
		
		IF kol <= coalesce(rs.Идет-rs.Рез,0) THEN
			INSERT INTO arc_energo.РезервИдущий (КодРезерва, КодСпискаЗаказа, Резерв, КодСодержания, Счет ,Когда, Докуда, Кем, Подкого, "Подкого_Код" , "Кем_Номер")
			VALUES (
			kr, rs.КодСпискаЗаказа, kol, ks, bill_no, now(), now()+'10 days'::interval,'PG auto',
			coalesce((SELECT Предприятие FROM arc_energo.Предприятия WHERE Код=kod),Null),kod,0);

			RAISE NOTICE 'R. Поставили на резерв в ид.: % ', kol;
			--rs.Рез:= rs.Рез+kol;
			kol:=0;
			
		ELSE --kol > 0 THEN
			INSERT INTO arc_energo.Резерв (КодРезерва, Резерв, КодКоличества, КодСодержания, Счет, КодСклада, ПримечаниеСклада,Когда, Докуда, Кем, Подкого, "Подкого_Код", "Кем_Номер")
			VALUES 
			(kr ,rs.КодСпискаЗаказа,rs.Идет-rs.Рез, ks, bill_no,now(), now()+'10 days'::interval,'PG auto',
			coalesce((SELECT Предприятие FROM arc_energo.Предприятия WHERE Код=kod), Null ),kod,0);
			
			
			RAISE NOTICE 'R. Поставили на резерв в ид.: % ', coalesce(rs.Скл-rs.Рез,0);
			kol:= kol - coalesce(rs.Идет-rs.Рез,0);
		END IF;	
	ELSE
	RAISE NOTICE 'Проверка2';
		IF kol > 0 AND kol = kol0 then
		msg :=coalesce(msg,'') || ks ||': Все количество под резервом';
		--RAISE NOTICE 'Нету';
		ELSIF kol > 0 AND kol = kol0 then 
		msg :=coalesce(msg,'') || ks ||': Количества в идущих недостаточно.';
		--RAISE NOTICE 'Недостаточно';
		END IF;
		
	END IF;
END LOOP;
		RAISE NOTICE 'КодСодержания %, ДатаОжидания %, Количество %, Остаток: %', ks, coalesce(quote_literal(expected_date),' не указана'),kol0, kol;
		--RAISE NOTICE 'КодСодержания %, ДатаОжидания %, Количество %, Остаток: %', ks, rs.ДатаОжидания,kol0, kol ;
----------------------------- Конец условной процедуры 	increase_stockpile(ks, var_invoice, stockpile )----------------
    
    IF kol > 0 AND kol = kol0  AND coalesce(msg,'')='' then 
	message := coalesce(msg,'') || ks || ': Срок поставки ' || coalesce(quote_literal(expected_date),'') || ' не обнаружен';
	residual := -1;
    ELSE 
	message:= 	coalesce(msg,'');
	residual := kol;
    END IF;

END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION setup_reserve_expected(integer, integer, double precision, timestamp without time zone)
  OWNER TO arc_energo;
