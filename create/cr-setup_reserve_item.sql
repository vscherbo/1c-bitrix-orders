-- Function: setup_reserve_item(integer, integer, double precision)

-- DROP FUNCTION setup_reserve_item(integer, integer, double precision);

CREATE OR REPLACE FUNCTION setup_reserve_item(
    bill_no integer,
    ks integer,
    kol double precision)
  RETURNS double precision AS
$BODY$DECLARE
	rs RECORD;
	okei INTEGER;
	var_order INTEGER;
	rsr RECORD;
	reserve  INTEGER DEFAULT 0;
	stock DOUBLE PRECISION;
	stockpile INTEGER DEFAULT 0;
	kk INTEGER;
	kod integer default 0;
--	cur_st INTEGER;
--	clc_st INTEGER;		
BEGIN

--
--SELECT setup_reserve_item(13200056,110021162,4)

-- в этой процедуре получаем счет, код содержания и количество, которое необходимо поставить на резерв

SELECT Код INTO kod FROM arc_energo.Счета WHERE "№ счета"= bill_no;
-- считаем свободный склад с резервами
RAISE NOTICE 'Вх. параметры: % % %', bill_no, ks, kol;

If kol >0 THEN
	FOR rs IN
		SELECT k.КодСодержания,k.КодСклада, k.kk, k.Скл::double precision, k.Примечание, coalesce(r.Рез2,0) Рез, k.quality, k.КодОКЕИ
		FROM (SELECT k.КодСодержания, 
			CASE WHEN Not (quality=0 AND  (Not КодСклада=5 Or (КодСклада =2 AND Примечание IS NULL))) OR coalesce(ОКЕИ,796)=6 THEN КодКоличества ELSE 0 END kk, 
			КодСклада, Sum(Свободно) as Скл, 
			Примечание,
			quality,
			coalesce(s.ОКЕИ,796) КодОКЕИ 
			FROM arc_energo.Количество k
			JOIN arc_energo.Содержание s  ON k.КодСодержания=s.КодСодержания
			WHERE Свободно<>0 
			GROUP BY k.КодСодержания,КодСклада,Примечание,ОКЕИ, 
			CASE WHEN Not (quality=0 AND  (Not КодСклада=5 Or (КодСклада =2 AND Примечание IS NULL))) OR coalesce(ОКЕИ,796)=6 THEN КодКоличества ELSE 0 END, quality) k
		LEFT JOIN
		     
		     (SELECT  SUM(Резерв) Рез2,  КодСодержания, КодСклада, ПримечаниеСклада, coalesce(КодКоличества,0) kk,
		        CASE WHEN КодСклада=2 AND ПримечаниеСклада IS NULL 
		        THEN 0 ELSE (SELECT k2.quality FROM Количество k2 WHERE k2.КодКоличества=r2.КодКоличества) 
		        END quality	
		      FROM arc_energo.Резерв r2
		      WHERE КогдаСнял IS NULL 
		      GROUP BY КодКоличества,КодСодержания, КодСклада, ПримечаниеСклада ) r
		      
			ON coalesce(r.ПримечаниеСклада,'') =coalesce(k.Примечание,'')
				AND r.КодСклада=k.КодСклада
				AND r.КодСодержания=k.КодСодержания
				AND r.kk = k.kk
			WHERE k.КодСклада IN (2,5) AND k.quality =0 AND k.КодСодержания=ks
			AND Скл - coalesce(r.Рез2,0)>0
			ORDER BY k.КодСклада,
			CASE WHEN k.Примечание Is NULL THEN 1 ELSE 2 END
	LOOP
			RAISE NOTICE 'R. КодСклада: % Примечание: % Резерв: %', rs.КодСклада, rs.Примечание, rs.Рез;
		-- ставим резерв
	IF kol>0 AND coalesce(rs.Скл-rs.Рез,0) >0 THEN
		
		IF kol <= coalesce(rs.Скл-rs.Рез,0)  THEN
			INSERT INTO arc_energo.Резерв (Резерв, КодКоличества, КодСодержания, Счет, КодСклада, ПримечаниеСклада,Когда, Докуда, Кем, Подкого, "Подкого_Код" , Кем_Номер)
			VALUES (
			kol, nullif(rs.kk,0), ks, bill_no, rs.КодСклада, rs.Примечание,now(), now()+'10 days'::interval,'PG auto',
			(SELECT Предприятие FROM arc_energo.Предприятия WHERE Код =kod),kod,0);

			RAISE NOTICE 'R. Поставили на резерв: % ', kol;
			--rs.Рез:= rs.Рез+kol;
			kol:=0;
			
		ELSIF kol > 0 AND coalesce(rs.Скл-rs.Рез,0) >0 THEN
			INSERT INTO arc_energo.Резерв (Резерв, КодКоличества, КодСодержания, Счет, КодСклада, ПримечаниеСклада,Когда, Докуда, Кем, Подкого, "Подкого_Код", Кем_Номер)
			VALUES (
			rs.Скл-rs.Рез, nullif(rs.kk,0), ks, bill_no, rs.КодСклада, rs.Примечание,now(), now()+'10 days'::interval,'PG auto',
			(SELECT Предприятие FROM arc_energo.Предприятия WHERE Код=kod),kod,0);
			
			
			RAISE NOTICE 'R. Поставили на резерв: % ', coalesce(rs.Скл-rs.Рез,0);
			kol:=coalesce(rs.Скл-rs.Рез,0);

		ELSE
				--kol =0 OR  coalesce(rs.Скл-rs.Рез,0) =0
				RAISE NOTICE 'R. Я не знаю, что это было';
		END IF;
		-- уменьшаем количество
	END IF;
	END LOOP;	
END IF; --If kol >0 THEN


RAISE NOTICE '2. КодСодержания %, Не поставилось под резерв: %, склад: %', ks, kol, stock; --1		
------------------------------------------------------------------------------------
RETURN kol;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION setup_reserve_item(integer, integer, double precision)
  OWNER TO arc_energo;
