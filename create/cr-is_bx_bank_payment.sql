CREATE OR REPLACE FUNCTION is_bx_bank_payment(
    arg_bx_order_id INTEGER)
returns boolean 
language plpgsql 
as
$body$
declare
v_payment_method_id integer;
begin
    SELECT COALESCE(fvalue, -1) INTO v_payment_method_id 
    FROM bx_order_feature 
    WHERE arg_bx_order_id = "bx_order_Номер" 
        AND fname = 'Метод оплаты ИД';
    RETURN (22 = v_payment_method_id); 
end;
$body$;
 
