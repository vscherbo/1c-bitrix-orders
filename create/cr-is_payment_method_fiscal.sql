create or replace function
is_payment_method_fiscal(IN arg_bx_order_id integer)
returns boolean
AS
$body$
BEGIN
PERFORM FROM arc_energo.bx_order_feature oif
        WHERE oif."bx_order_Номер" = arg_bx_order_id
              AND oif.fname = 'Метод оплаты ИД'
              AND oif.fvalue='25';
RETURN FOUND;
END
$body$
LANGUAGE plpgsql;
