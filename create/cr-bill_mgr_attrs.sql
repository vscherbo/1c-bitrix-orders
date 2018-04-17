CREATE OR REPLACE FUNCTION arc_energo.bill_mgr_attrs(arg_bill_no integer, OUT out_mgr_email character varying, OUT out_mgr_name character varying, OUT out_firm_name character varying, OUT out_firm_phone character varying, OUT out_ext_phone character varying, OUT out_mob_phone character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
WITH bill AS (SELECT b."№ счета", b.Хозяин, autobill_mgr(b.Хозяин) AS bill_mgr, b.фирма 
FROM Счета b 
WHERE arg_bill_no = b."№ счета")
SELECT e.email, e.Имя, f.Название, '(812)327-327-4', e.telephone, e.mob_phone
FROM bill, Сотрудники e, Фирма f
WHERE bill.фирма = f.КлючФирмы
      AND bill.bill_mgr = e.Менеджер        
INTO out_mgr_email, out_mgr_name, out_firm_name, out_firm_phone, out_ext_phone, out_mob_phone;
END
$function$
