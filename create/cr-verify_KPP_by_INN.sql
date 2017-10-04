-- Function: verify_kpp_by_inn(character varying)

-- DROP FUNCTION verify_kpp_by_inn(character varying);

CREATE OR REPLACE FUNCTION verify_kpp_by_inn(inn character varying)
  RETURNS character varying AS
$BODY$DECLARE
  rec_answer record;
  ret_kpp varchar := 'N/A';
  rec_kpp record;
begin
  rec_answer := get_reqs_by_INN(INN);
  IF rec_answer.ret_flg THEN
      rec_kpp := parse_KPP(rec_answer.ret_txt);
      IF rec_kpp.ret_kpp_flg THEN
        ret_kpp := rec_kpp.ret_kpp;
      ELSE
         RAISE NOTICE 'verify_kpp_by_inn: не удалось извлечь КПП из ответа сайта ИТС, ret_kpp=%', rec_kpp.ret_kpp;
      END IF;
  ELSE
     RAISE NOTICE 'verify_kpp_by_inn: не получен ответ от сайта ИТС, ret_txt=%, ret_kpp=%', rec_answer.ret_txt, ret_kpp;
  END IF;

  RAISE NOTICE 'verify_kpp_by_inn: inn=%, RETURN ret_kpp=%', inn, ret_kpp;
  RETURN ret_kpp;
end
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION verify_kpp_by_inn(character varying)
  OWNER TO arc_energo;
