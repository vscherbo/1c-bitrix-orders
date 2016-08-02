-- Function: fn_create_attachment(integer, integer)

-- DROP FUNCTION fn_create_attachment(integer, integer);

CREATE OR REPLACE FUNCTION fn_create_attachment(
    bill_no integer,
    msg_type integer)
  -- RETURNS character varying[] AS
  RETURNS character varying AS
$BODY$DECLARE
  arr_docs varchar = E''; --[];
BEGIN
   IF 4 = msg_type THEN -- счёт-факс
      -- arr_docs := array_append(arr_docs, fn_bill_fax(bill_no));
      arr_docs := fn_bill_fax(bill_no);
   ELSE
      IF 3 = msg_type THEN -- квитанция
         -- arr_docs := array_append(arr_docs, fn_doc_person_bank(bill_no));
         arr_docs := fn_doc_person_bank(bill_no) || ',';
      END IF;
      -- arr_docs := array_append(arr_docs, fn_order_form(bill_no));
      arr_docs := arr_docs || fn_order_form(bill_no);
   END IF;
   RETURN arr_docs;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_create_attachment(integer, integer)
  OWNER TO arc_energo;
