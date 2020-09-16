-- DROP FUNCTION arc_energo.bill_mgr_attrs(integer);

CREATE OR REPLACE FUNCTION arc_energo.bill_mgr_attrs(arg_bill_no integer, OUT out_mgr_email character varying, OUT out_mgr_name character varying, OUT out_firm_name character varying, OUT out_firm_phone character varying, OUT out_ext_phone character varying, OUT out_mob_phone character varying, OUT out_email_to character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
WITH bill AS (SELECT b."№ счета", b.Хозяин, autobill_mgr(b.Хозяин) AS bill_mgr, b.фирма
    FROM Счета b
    WHERE arg_bill_no = b."№ счета")
SELECT e.email, e.Имя, f.Название, '(812)327-327-4', e.telephone, e.mob_phone, coalesce (s.bill_no::varchar, e.email)
FROM bill, Сотрудники e, Фирма f
left join aub_in_stock s on s.bill_no = arg_bill_no
WHERE bill.фирма = f.КлючФирмы
      AND bill.bill_mgr = e.Менеджер
INTO out_mgr_email, out_mgr_name, out_firm_name, out_firm_phone, out_ext_phone, out_mob_phone, out_email_to;

-- patch
IF out_email_to = arg_bill_no::varchar THEN
    -- out_email_to := 'snitko@kipspb.ru';
    SELECT email FROM "Сотрудники" WHERE "Менеджер" = 49 and "Активность" INTO out_email_to;
    IF NOT FOUND THEN
        out_email_to := out_mgr_email;
    END IF;
END IF;
END
$function$
