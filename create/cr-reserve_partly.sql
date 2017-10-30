-- Function: reserve_partly(text, integer, integer)

-- DROP FUNCTION reserve_partly(text, integer, integer);

CREATE OR REPLACE FUNCTION reserve_partly(
    IN delivery_qnt text,
    IN a_bill_no integer,
    IN ks integer,
    OUT out_lack numeric,
    OUT out_reason text)
  RETURNS record AS
$BODY$DECLARE
-- loc_str TEXT := 'со склада: 10;к 2016-12-12: 2;к 2016-12-22: 22;через 7-8 недель:1;';
--loc_str TEXT := 'со склада: 10; ';
loc_when TEXT;
loc_qnt NUMERIC;
loc_part TEXT;
loc_res TEXT[];
loc_lack NUMERIC;
loc_result NUMERIC := 0;
loc_reason TEXT;
loc_str TEXT;
loc_reasons TEXT[];
BEGIN
FOR loc_part IN SELECT regexp_split_to_table(trim(both ' ;' FROM delivery_qnt) , ';')
LOOP
    -- RAISE NOTICE 'loc_part=%', loc_part;
    loc_when := TRIM(split_part(loc_part, ':'::TEXT, 1));
    BEGIN
        loc_qnt := TRIM(split_part(loc_part, ':'::TEXT, 2))::NUMERIC;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Неверный формат числа в [%]', loc_part;
        loc_qnt := 0;
    END; -- cast to numeric
    RAISE NOTICE 'Срок-количество: {%}-{%}, length(loc_when)=%', loc_when, loc_qnt, length(loc_when);

    IF position('со склада' in loc_when) > 0 THEN
        -- loc_lack := setup_reserve(a_bill_no, ks, loc_qnt);
        loc_lack := ctr_reserve(a_bill_no, ks, loc_qnt);
        IF loc_lack > 0 THEN 
            loc_reason := 'нет в наличии';
        ELSE
            loc_reason := '';
        END IF;
        RAISE NOTICE '->%=%', loc_reason, loc_lack;
    ELSIF 0 = length(loc_when) THEN 
        RAISE NOTICE 'empty loc_when, loc_qnt=%', loc_qnt;
        SELECT * INTO loc_lack, loc_reason FROM setup_reserve_expected(a_bill_no, ks, loc_qnt, NULL);
        RAISE NOTICE '-->из идущих={%}, причина нехватки={%}', loc_lack, loc_reason;
    ELSIF regexp_matches(loc_when, '^к (\d{4}.\d{2}.\d{2}|\d{2}.\d{2}.\d{4})', 'g'::TEXT) IS NOT NULL THEN
        loc_res := regexp_matches(loc_when, '.*(\d{4}.\d{2}.\d{2}|\d{2}.\d{2}.\d{4})', 'g'::TEXT);
        RAISE NOTICE 'parsed expected=%', loc_res[1];
        SELECT * INTO loc_lack, loc_reason FROM setup_reserve_expected(a_bill_no, ks, loc_qnt, loc_res[1]::timestamp without time zone);
        RAISE NOTICE '-->из идущих={%}, причина нехватки={%}', loc_lack, loc_reason;
    ELSIF regexp_matches(loc_when, '.од заказ.*(\d{4}.\d{2}.\d{2}|\d{2}.\d{2}.\d{4})', 'g'::TEXT) IS NOT NULL THEN
        loc_res := regexp_matches(loc_when, '.*(\d{4}.\d{2}.\d{2}|\d{2}.\d{2}.\d{4})', 'g'::TEXT);
        RAISE NOTICE 'parsed planning=%', loc_res[1];
        loc_lack := loc_qnt;
        loc_reason := 'Не реализована постановка резерва из планируемых поставок';
        /**
        SELECT * INTO loc_lack, loc_reason FROM setup_reserve_planning(a_bill_no, ks, loc_qnt, loc_res[1]::timestamp without time zone);
        RAISE NOTICE '-->планируемая поставка={%}, причина={%}', loc_lack, loc_reason;
        **/
    ELSIF regexp_matches(loc_when, '.*\d+.*\d+ недел.*', 'g'::TEXT) IS NOT NULL THEN -- 'm-n недел'
        loc_res := regexp_matches(loc_when, '.*(\d+.*\d+) недел.*', 'g'::TEXT);
        RAISE NOTICE '---> default period=%', loc_res[1];
        loc_lack := loc_qnt;
        loc_reason := 'Не реализована постановка в Свободный Резерв';
    ELSIF regexp_matches(loc_when, 'через.*\d+.*', 'g'::TEXT) IS NOT NULL THEN -- 'через 000'
        loc_res := regexp_matches(loc_when, 'через.*\d+.*', 'g'::TEXT);
        RAISE NOTICE '---> default period=%', loc_res[1];
        loc_lack := loc_qnt;
        loc_reason := 'Не реализована постановка в Свободный Резерв';
    ELSE --unknown
        loc_lack := loc_qnt;
        loc_reason := 'Неверный формат срок-количество:{' || loc_part || '}';
    END IF;

    IF loc_lack > 0 THEN
        loc_result := loc_result + loc_lack;
        loc_str := format('в части {%s} нехватка для резерва={%s}, причина={%s}', loc_when, loc_lack, quote_nullable(loc_reason));
        loc_reasons := array_append(loc_reasons, loc_str);
        RAISE NOTICE '___%', loc_str;
    END IF;
END LOOP;

out_lack := loc_result;
out_reason := array_to_string(loc_reasons, '/', '');
RETURN;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION reserve_partly(text, integer, integer)
  OWNER TO arc_energo;

