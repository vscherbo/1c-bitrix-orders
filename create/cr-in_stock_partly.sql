-- Function: in_stock_partly(text)

-- DROP FUNCTION in_stock_partly(text);

CREATE OR REPLACE FUNCTION in_stock_partly(order_item_id text)
  RETURNS numeric AS
$BODY$DECLARE
    loc_time_qnt TEXT;
    loc_first_part TEXT;
    loc_partly NUMERIC;
BEGIN
    SELECT fvalue INTO loc_time_qnt FROM bx_order_item_feature WHERE bx_order_item_id = order_item_id AND fname = 'Срок-Количество';
    IF FOUND THEN
        -- разбор loc_time_qnt
        loc_first_part := split_part(loc_time_qnt, ';', 1);
        -- RAISE NOTICE 'loc_first_part={%}', loc_first_part;
        IF position('со склада' in loc_first_part) > 0 THEN
            BEGIN
                loc_partly := split_part(loc_first_part, ':', 2)::NUMERIC;
                -- loc_partly := to_number('99'::TEXT, split_part(trim(loc_first_part), ':', 2));
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE 'Неверный формат числа после ''со склада''=[%]', loc_first_part;
            END; -- cast to numeric
           RAISE NOTICE 'loc_partly=[%]', loc_partly;
           IF loc_partly <= 0 THEN loc_partly := NULL; END IF;
        END IF; -- 'Со склада' найдено
    END IF;
    RETURN loc_partly;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION in_stock_partly(text)
  OWNER TO arc_energo;

