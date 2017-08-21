-- drop function select_emp(integer, integer);

create or replace function select_emp(IN arg_bx_order_id integer, IN arg_firm_code integer)
returns integer 
language plpgsql
as
$body$
DECLARE
ret_emp_code integer;
loc_email text;
loc_templ_email text;
loc_aub_msg text;
text_var1 text;
text_var2 text;
text_var3 text;
BEGIN
loc_email := bx_order_email(arg_bx_order_id); -- always NOT NULL 
loc_templ_email := '%' || loc_email || '%';
RAISE NOTICE 'select_emp: покупатель для предприятия=% по buyer_id не найден. Ищем по email=%', arg_firm_code, loc_email;
BEGIN
    --SELECT "КодРаботника" INTO STRICT ret_emp_code FROM "Работники" WHERE "Работники"."ЕАдрес" = loc_email AND "Код" = arg_firm_code;
    --RAISE NOTICE 'select_emp: Найден Работник Предприятия=% по email=%', arg_firm_code, loc_email;
    SELECT "КодРаботника" INTO STRICT ret_emp_code FROM "Работники" WHERE "Работники"."ЕАдрес" LIKE loc_templ_email AND "Код" = arg_firm_code;
    RAISE NOTICE 'select_emp: Найден Работник Предприятия=% по templ_email=%', arg_firm_code, loc_templ_email;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE NOTICE 'select_emp: Работник с email=% не найден', loc_email;
        RAISE NOTICE 'get_emp: Создаём Работника-физ.лицо bx_order_id=%, firm_code=%', arg_bx_order_id, arg_firm_code;
        ret_emp_code := create_employee(arg_bx_order_id, arg_firm_code, loc_email);
    WHEN TOO_MANY_ROWS THEN
        /**
        loc_aub_msg := format('ТУПИК: найдено более одного Работника по email=%s для Предприятия=%s', loc_email, arg_firm_code);
        INSERT INTO aub_log(bx_order_no, descr, res_code, mod_id) VALUES(bx_order_id, loc_aub_msg, 9, -1);
        RAISE NOTICE 'select_emp: %', loc_aub_msg;
        **/
        -- выбираем Работника с loc_email и arg_firm_code из последнего отгруженного счёта
        SELECT e."КодРаботника" INTO ret_emp_code 
        FROM "Работники" e
        JOIN "Счета" b ON b."Код" = e."Код" AND b."КодРаботника" = e."КодРаботника" 
        -- WHERE "ЕАдрес" = loc_email 
        WHERE "ЕАдрес" LIKE loc_templ_email 
              AND e."Код" = arg_firm_code
              AND "Статус" > 0 -- = 10
        ORDER BY "Дата счета" DESC LIMIT 1;
        ret_emp_code :=  COALESCE(ret_emp_code, -2);
        IF -2 = ret_emp_code THEN
            loc_aub_msg := format('Не удалось выйти из ТУПИКА: более одного Работника по email=%s для Предприятия=%s', loc_email, arg_firm_code);
            INSERT INTO aub_log(bx_order_no, descr, res_code, mod_id) VALUES(arg_bx_order_id, loc_aub_msg, 9, -1);
            RAISE NOTICE 'select_emp: %', loc_aub_msg;
        END IF;
    WHEN OTHERS THEN
        ret_emp_code := -3;
        GET STACKED DIAGNOSTICS text_var1 = MESSAGE_TEXT, text_var2 = PG_EXCEPTION_DETAIL, text_var3 = PG_EXCEPTION_HINT;
        RAISE NOTICE 'select_emp: MESSAGE_TEXT=%, PG_EXCEPTION_DETAIL=%, PG_EXCEPTION_HINT=%', text_var1, text_var2, text_var3;
   
END;

return COALESCE(ret_emp_code, -4);
END;
$body$;
