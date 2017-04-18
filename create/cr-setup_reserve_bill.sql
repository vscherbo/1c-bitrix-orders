-- Function: setup_reserve_bill(integer, boolean)

-- DROP FUNCTION setup_reserve_bill(integer, boolean);
-- 2017-04.10
CREATE OR REPLACE FUNCTION setup_reserve_bill(
    a_bill_no integer,
    on_go boolean)
  RETURNS character varying AS
$BODY$DECLARE
	ks INTEGER;
	rs RECORD;
	stockpile INTEGER DEFAULT 0;
	ostatok INTEGER DEFAULT 0;
	resume  character varying default 'Не удалось зарезервировать: ';

BEGIN
-- on_go boolean - параметр разрешающий (true) постановку резерва в идущих.

--SELECT * FROM setup_reserve(13200056)
-- on_go boolean - параметр разрешающий (true) постановку резерва в идущих.
-- Выбираем позиции в счете, по следующим критериям:
--   КодСодержания не пустой
--   Гдезакупать  - "Рез.склада"
--	или 
--   срок поставки - в наличии
--   Галка готов - false (позиция не отгружена) 
--   Галка НеЗаказывать - false
--  по этой выборке из количества вычитаем то, что уже отгружено и то, что зарезервировано.

For rs IN 
	-- Смотрим строки, где резерв не равен количеству по счету
	SELECT ss.КодСодержания, 
		ss."Кол-во"::double precision, 
		coalesce(k.wh,0)  Скл, 
		coalesce(r.Рез2,0)  Рез, 
		coalesce(pcx.Отгр2,0) Отгр,
		Coalesce(s.ОКЕИ,796) КодОКЕИ
	FROM arc_energo."Содержание счета" ss 
	LEFT JOIN (
		-- обзор стоящих по счету резервов
		SELECT КодСодержания, Sum(Резерв) as Рез2 FROM arc_energo.Резерв 
		WHERE Счет = a_bill_no
		AND КогдаСнял IS NULL
		GROUP BY КодСодержания) r
	ON ss.КодСодержания = r.КодСодержания
	LEFT JOIN 
		-- прошедшие отгрузки
		(SELECT k.КодСодержания, Sum(Отгружено) Отгр2 
		FROM Расход 
		JOIN Количество k ON Расход.КодКоличества=k.КодКоличества
		WHERE Счет=a_bill_no
		GROUP BY k.КодСодержания ) pcx
	ON ss.КодСодержания=pcx.КодСодержания

	JOIN 
		(SELECT k1.КодСодержания, Sum(k1.Свободно) wh
		FROM Количество k1 
		WHERE k1.Свободно <>0 AND k1.quality= 0
		GROUP BY k1.КодСодержания) k
	ON ss.КодСодержания=k.КодСодержания
	
		JOIN Содержание s
	ON ss.КодСодержания=s.КодСодержания
	
	WHERE ss."№ счета"= a_bill_no --13200056
	AND Not (coalesce(ss.Готов,'f') ='t' or coalesce(ss.НеЗаказывать,'f') = 't') --исключаем подобные позиции
	AND Not ss.КодСодержания Is Null 
	AND (coalesce(ss.Гдезакупать,'')='' OR ss.Гдезакупать LIKE 'Рез%склада' ) --Or coalesce(sz.Раб,0) >0
--	AND Not (ss."Кол-во" = coalesce(sz.Вып,0))

LOOP
	ostatok:=0;	
	ks:= rs.КодСодержания;
	stockpile:= rs."Кол-во" - rs.Рез - rs.Отгр;

			RAISE NOTICE 'КодСодержания %, Кол-во: %;  Отгружено: %, Резерв: %, Поставить: %', ks, rs."Кол-во"::double precision, rs.Отгр, rs.Рез, stockpile ;
-----------------------------
	IF rs.Скл - rs.Рез > 0 AND stockpile >0 THEN
			RAISE NOTICE 'КодСодержания %, Кол-во: %;  Отгружено: %, Резерв: %, Поставить: %', ks, rs."Кол-во"::double precision, rs.Отгр, rs.Рез, stockpile ;
		IF rs.КодОКЕИ <>6 THEN  -- если к резервированию больше нуля и не мерный товар
			RAISE NOTICE 'ШТУЧНЫЙ %!',rs.КодОКЕИ;
			ostatok:= setup_reserve_item(a_bill_no, ks, stockpile,-1);
		ELSIF rs.КодОКЕИ = 6 THEN  -- если к резервированию больше нуля и немерный товар
			RAISE NOTICE 'МЕРНЫЙ %!',rs.КодОКЕИ;
			-- напишем процедуру постановки на резерв мерного товара
			 ostatok:= setup_reserve_measured(a_bill_no, ks, stockpile,-1);
		END IF;
			-- PERFORM setup_reserve_expected (a_bill_no, ks, stockpile);
	ELSE
	END IF;
-- Если количество после резервирования больше нуля - ставим резерв в идущих
	IF ostatok  > 0  AND on_go THEN
		RAISE NOTICE 'Поставить резерв в идущих';
		resume:= resume || '' || ks || ';' || stockpile || '->'  || ostatok || '; '; 
	else
		-- по идее можно отправить оповещение менеджеру о том, что невозможно зарезервировать на складе весь товар.
	END IF;
	
-----------------------------
END LOOP;
If resume= 'Не удалось зарезервировать: ' THEN
resume = '';
END IF;

RAISE NOTICE ' Вернули: %', resume ;

RETURN resume;
--
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION setup_reserve_bill(integer, boolean)
  OWNER TO arc_energo;
