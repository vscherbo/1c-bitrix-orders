-- Function: fn_inetbill_neworders()

-- DROP FUNCTION fn_inetbill_neworders();

CREATE OR REPLACE FUNCTION fn_inetbill_neworders()
  RETURNS void AS
$BODY$ DECLARE
  o RECORD;
  loc_RETURNED_SQLSTATE TEXT;
  loc_MESSAGE_TEXT TEXT;
  loc_PG_EXCEPTION_DETAIL TEXT;
  loc_PG_EXCEPTION_HINT TEXT;
  loc_PG_EXCEPTION_CONTEXT TEXT;
  loc_exception_txt TEXT;
BEGIN
FOR o IN SELECT * FROM bx_order WHERE billcreated = 0
                                -- AND now() - dt_insert < interval '5 minute' 
                       ORDER BY "Номер" DESC LOOP
    BEGIN
        PERFORM bxorder2bill(o."Номер");
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            loc_RETURNED_SQLSTATE = RETURNED_SQLSTATE,
            loc_MESSAGE_TEXT = MESSAGE_TEXT,
            loc_PG_EXCEPTION_DETAIL = PG_EXCEPTION_DETAIL,
            loc_PG_EXCEPTION_HINT = PG_EXCEPTION_HINT,
            loc_PG_EXCEPTION_CONTEXT = PG_EXCEPTION_CONTEXT ;
        loc_exception_txt = format('fn_inetbill_neworders RETURNED_SQLSTATE=%s, MESSAGE_TEXT=%s, PG_EXCEPTION_DETAIL=%s, PG_EXCEPTION_HINT=%s, PG_EXCEPTION_CONTEXT=%s', loc_RETURNED_SQLSTATE, loc_MESSAGE_TEXT, loc_PG_EXCEPTION_DETAIL, loc_PG_EXCEPTION_HINT, loc_PG_EXCEPTION_CONTEXT);
        UPDATE bx_order SET billcreated = -2 WHERE "Номер" = o."Номер";
        RAISE NOTICE 'ОШИБКА при создании автосчёта по заказу [%] exception=[%]', o."Номер", loc_exception_txt;
    END; -- создание счёта
END LOOP;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_inetbill_neworders()
  OWNER TO arc_energo;
COMMENT ON FUNCTION fn_inetbill_neworders() IS 'Пытается создать счета, сформировать документы и отправить их по почте для новых загруженных заказов';
