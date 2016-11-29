-- Function: reserve_partly(text, integer, integer)

-- DROP FUNCTION reserve_partly(text, integer, integer);

CREATE OR REPLACE FUNCTION reserve_partly(
    delivery_qnt text,
    bill_no integer,
    ks integer)
  RETURNS void AS
$BODY$DECLARE
-- loc_str TEXT := 'со склада: 10;к 2016-12-12: 2;к 2016-12-22: 22;через 7-8 недель:1;';
--loc_str TEXT := 'со склада: 10; ';
loc_when TEXT;
loc_qnt NUMERIC;
loc_part TEXT;
loc_res TEXT[];
loc_lack NUMERIC;
loc_reason TEXT;
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
    RAISE NOTICE 'when={%}, quantity={%}', loc_when, loc_qnt;

    IF position('со склада' in loc_when) > 0 THEN
        loc_lack := setup_reserve(bill_no, ks, loc_qnt);
    ELSIF regexp_matches(loc_when, '.*(\d{4}.\d{2}.\d{2}|\d{2}.\d{2}.\d{4})', 'g'::TEXT) IS NOT NULL THEN
        loc_res := regexp_matches(loc_when, '.*(\d{4}.\d{2}.\d{2}|\d{2}.\d{2}.\d{4})', 'g'::TEXT);
        RAISE NOTICE '___expected=%', loc_res[1];
        SELECT * INTO loc_lack, loc_reason FROM setup_reserve_expected(bill_no, ks, loc_qnt, loc_res[1]::timestamp without time zone);
    ELSIF regexp_matches(loc_when, '.*\d+.*\d+ недел.*', 'g'::TEXT) IS NOT NULL THEN -- m-n недель
        loc_res := regexp_matches(loc_when, '.*(\d+.*\d+) недел.*', 'g'::TEXT);
        RAISE NOTICE '-->> default period=%', loc_res[1];
        loc_lack := loc_qnt;
        loc_reason := 'Не реализована постановка в Свободный Резерв';
    ELSE --unknown
        loc_lack := loc_qnt;
        loc_reason := 'Неверный формат срок-количество:{' || loc_part || '}';
    END IF;

    IF loc_lack > 0 THEN
        RAISE NOTICE '___в части {%} нехватка для резерва={%}, причина={%}', loc_when, loc_lack, quote_nullable(loc_reason);
    END IF;
END LOOP;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION reserve_partly(text, integer, integer)
  OWNER TO arc_energo;

