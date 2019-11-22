-- DROP FUNCTION arc_energo.ctr_time_consuming(varchar, numeric);

CREATE OR REPLACE FUNCTION arc_energo.ctr_time_consuming(arg_mod_id varchar, arc_qnt numeric)
    RETURNS bool
    LANGUAGE plpgsql
AS $function$   
BEGIN
/** ДЖ
Как вариант для начала внести пневмоцилиндры, а затем этот список дополнять.
Самые долгие это создание пневмоцилиндров
и рассверловка катушек S21H , S91H при установке их на клапан НО.
**/
    perform 1 from "Содержание" s 
    WHERE 
        "КодНаименования" = 110021 -- Пневмоцилиндры
        AND "КодСодержания" = get_ks(arg_mod_id);
    RETURN FOUND;
END    
 $function$;

