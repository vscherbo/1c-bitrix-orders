-- DROP FUNCTION autobill_mgr_attrs(integer);

CREATE OR REPLACE FUNCTION autobill_mgr_attrs(arg_bill_no integer, OUT out_mgr_email VARCHAR, OUT out_mgr_name VARCHAR, OUT out_firm_name VARCHAR, OUT out_ext_phone VARCHAR)
RETURNS record
language plpgsql
AS
$BODY$
BEGIN
	SELECT e.email, e.Имя, f.Название, e.telephone
    FROM Сотрудники e, Счета b, Фирма f
    WHERE arg_bill_no = b."№ счета"
        AND b.фирма = f.КлючФирмы
        AND autobill_mgr(b.Хозяин) = e.Менеджер
    INTO out_mgr_email, out_mgr_name, out_firm_name, out_ext_phone;
END
$BODY$
