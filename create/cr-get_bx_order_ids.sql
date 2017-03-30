-- DROP FUNCTION get_bx_order_ids(integer);

CREATE OR REPLACE FUNCTION get_bx_order_ids(bx_order_no integer,
	OUT out_buyer_id INTEGER,
	OUT out_name VARCHAR,
	OUT out_email VARCHAR,
	OUT is_valid BOOLEAN
	)
  RETURNS RECORD AS
$BODY$
DECLARE
    o RECORD;
BEGIN
SELECT bo.*, bb.bx_name, bf.fvalue AS email INTO o
    FROM vw_bx_actual_order bo, bx_buyer bb, bx_order_feature bf
    WHERE
        bo."Номер" = bx_order_no
        AND bo.bx_buyer_id = bb.bx_buyer_id
        AND (bo."Номер" = bf."bx_order_Номер" AND bf.fname = 'Контактный Email')
UNION
SELECT bo.*, bb.bx_name, bf.fvalue AS email
    FROM vw_bx_actual_order bo, bx_buyer bb, bx_order_feature bf
    WHERE
        bo."Номер" = bx_order_no
        AND bo.bx_buyer_id = bb.bx_buyer_id
        AND (bo."Номер" = bf."bx_order_Номер" AND bf.fname = 'EMail')
UNION
SELECT bo.*, bb.bx_name, bf.fvalue AS email
    FROM vw_bx_actual_order bo, bx_buyer bb, bx_order_feature bf
    WHERE
        bo."Номер" = bx_order_no
        AND bo.bx_buyer_id = bb.bx_buyer_id
        AND (bo."Номер" = bf."bx_order_Номер" AND bf.fname = 'EMail покупателя');

is_valid := FOUND;        
out_buyer_id := o.bx_buyer_id;
out_name := o.bx_name;
out_email := o.email;
RETURN;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
