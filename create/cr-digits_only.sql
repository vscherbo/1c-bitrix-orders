-- Function: digits_only(text)

-- DROP FUNCTION digits_only(text);

CREATE OR REPLACE FUNCTION digits_only(str1 text)
  RETURNS text AS
$BODY$BEGIN
RETURN regexp_replace(str1, '[^0-9]', '', 'g');
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION digits_only(text)
  OWNER TO arc_energo;
COMMENT ON FUNCTION digits_only(text) IS 'удаляет всё кроме цифр';

