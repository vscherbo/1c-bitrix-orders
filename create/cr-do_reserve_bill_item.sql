-- Function: do_reserve_bill_item(integer, integer, integer, numeric, integer, integer, integer, character varying)

-- DROP FUNCTION do_reserve_bill_item(integer, integer, integer, numeric, integer, integer, integer, character varying);

CREATE OR REPLACE FUNCTION do_reserve_bill_item(
    firm_code integer,
    bill_owner integer,
    ks integer,
    need_quantity numeric,
    position_code integer DEFAULT NULL::integer,
    wh_code integer DEFAULT 2,
    quantity_code integer DEFAULT NULL::integer,
    wh_description character varying DEFAULT NULL::character varying)
  RETURNS boolean AS
$BODY$DECLARE
 bill_no integer;
BEGIN
  INSERT INTO "Резерв"("Резерв", "Подкого", "Когда", "Докуда", "Кем", "КодПозиции", "КодСодержания", "КодКоличества", "ПримечаниеСклада", "КодСклада") 
                          VALUES(need_quantity, firm_code, now(), now()+'10 days'::interval, bill_owner, position_code, ks, quantity_code, '', 2);
  RETURN FOUND;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION do_reserve_bill_item(integer, integer, integer, numeric, integer, integer, integer, character varying)
  OWNER TO arc_energo;
COMMENT ON FUNCTION do_reserve_bill_item(integer, integer, integer, numeric, integer, integer, integer, character varying) IS 'Резервирует позицию счёта';
