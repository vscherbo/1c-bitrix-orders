-- Function: odt2pdf(character varying)


CREATE OR REPLACE FUNCTION arc_energo.odt2pdf(input_file character varying)
  RETURNS character varying AS
$BODY$DECLARE
  cmd VARCHAR;
  res_exec RECORD;
  str_res VARCHAR;
  out_fname VARCHAR;
  indir VARCHAR = '/opt/autobill/db';
  outdir VARCHAR = '/opt/autobill/output';
  basename VARCHAR;
BEGIN
-- libreoffice --headless --convert-to pdf /opt/autobill/data/39200389-Бланк-заказа.odt
basename = regexp_replace(input_file, '^.+[/\\]', '');
cmd := E'libreoffice --headless --convert-to pdf --outdir ' || outdir || ' ' || indir || '/' || basename;
RAISE NOTICE 'odt2pdf cmd=%', cmd;
res_exec := public.exec_paramiko('ct-apps01.arc.world', 22, 'autobill'::VARCHAR, cmd);

RAISE NOTICE 'odt2pdf res_exec=%', res_exec;

/**/
IF res_exec.err_str <> '' THEN RAISE 'Convert to PDF cmd=%^err_str=[%]', cmd, res_exec.err_str; 
ELSE str_res := res_exec.out_str;
END IF;
/**/

out_fname = replace(basename, '.odt', '.pdf');
RAISE NOTICE 'odt2pdf with pdf extension=%', out_fname;
-- RETURN outdir || '/' || replace(regexp_replace(input_file, '^.+[/\\]', ''), '.odt', '.pdf');
RETURN outdir || '/' || out_fname;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
