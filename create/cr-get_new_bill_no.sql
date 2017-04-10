CREATE OR REPLACE FUNCTION get_new_bill_no(manager_id integer)
  RETURNS integer AS
$BODY$
DECLARE
  loc_bill_no integer;
  curr_year integer;
  seq_name text;
  hi_part integer;
  lo_part integer := 1;
  loc_str text;
begin
  curr_year := extract(Year from now());
  hi_part := (manager_id * 100 + curr_year - 1996) * 10000;
  seq_name := 'billno_' || manager_id || '_' || curr_year ||  '_seq';
  lo_part := nextval(seq_name::regclass);
  loc_bill_no := hi_part + lo_part ;
  loc_str := format('curr_year=%s, hi_part=%s, seq_name=%s, lo_part=%s, loc_bill_no=%s', curr_year, hi_part, seq_name, lo_part, loc_bill_no);
  RAISE NOTICE 'notice:%', loc_str;

  RETURN loc_bill_no;
end
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
