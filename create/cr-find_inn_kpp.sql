CREATE OR REPLACE FUNCTION arc_energo.find_inn_kpp(arg_order_id integer, arg_inn character varying, arg_kpp character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
declare
    loc_kpp text;
    len_inn INTEGER;
    loc_FirmCode INTEGER;
begin
len_inn := length(arg_INN);
IF 12 = len_inn THEN -- для ИП не м.б. КПП, защита
    arg_KPP := NULL; 
END IF;

IF len_inn IN (10,12) THEN
    loc_FirmCode := select_firm(arg_INN, arg_kpp);
    IF -1 = loc_FirmCode THEN -- Предприятие НЕ найдено
        loc_kpp := verify_KPP_by_INN(arg_INN);
        IF 'N/A'= loc_kpp THEN -- нет ответа 1С
            loc_kpp := arg_KPP;
        ELSE -- ищем с КПП из Инета
            loc_FirmCode := select_firm(arg_INN, loc_kpp);
            IF loc_FirmCode = -1 THEN -- с КПП из Инета тоже не найдено, создаём
                loc_FirmCode := create_firm(arg_order_id, arg_INN, loc_kpp);
            END IF;
        END IF;
    ELSIF -2 = loc_FirmCode THEN -- есть дубли Предприятия
        -- выбрать из дублей с последним счётом
        NULL;
    END IF; -- loc_FirmCode < 0
ELSE
    loc_FirmCode := -3;
    RAISE NOTICE 'Непредвиденная длина ИНН=%, ИНН=% ', len_inn, INN;
END IF; -- length(INN)

RETURN loc_FirmCode;
end
$function$
