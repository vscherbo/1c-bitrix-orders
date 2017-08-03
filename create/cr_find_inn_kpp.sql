-- Function: find_inn_kpp(character varying, character varying)

-- DROP FUNCTION find_inn_kpp(character varying, character varying);

CREATE OR REPLACE FUNCTION find_inn_kpp(
    arg_order_id INTEGER, 
    arg_INN character varying,
    arg_KPP character varying)
  RETURNS record AS
$BODY$
declare
    loc_kpp text;
    len_inn INTEGER;
    loc_FirmCode INTEGER;
    locFirm RECORD;
begin
len_inn := length(arg_INN);
IF 12 = len_inn THEN -- для ИП не м.б. КПП, защита
    arg_KPP := NULL; 
END IF;

IF len_inn IN (10,12) THEN
    loc_kpp := verify_KPP_by_INN(arg_INN);
    IF 'N/A'= loc_kpp THEN -- нет ответа 1С
        loc_kpp := arg_KPP;
    END IF;

    loc_FirmCode := select_firm(arg_INN, loc_kpp);
    IF loc_FirmCode = -1 THEN -- не найдено
        loc_FirmCode := create_firm(arg_order_id, arg_INN, loc_kpp);
    END IF;
    SELECT * INTO locFirm FROM "Предприятия" WHERE "Код" = loc_FirmCode;
ELSE
    RAISE NOTICE 'Непредвиденная длина ИНН=%, ИНН=% ', len_inn, INN;
END IF; -- length(INN)

RETURN locFirm;
end
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION find_inn_kpp(integer, character varying, character varying) OWNER TO arc_energo;
