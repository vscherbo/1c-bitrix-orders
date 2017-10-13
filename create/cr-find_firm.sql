
-- DROP FUNCTION find_firm(integer);

CREATE OR REPLACE FUNCTION find_firm(arg_bx_order_id INTEGER)
RETURNS integer AS
$BODY$
declare
    bx_INN text;
    bx_KPP text;
    loc_kpp text;
    len_inn INTEGER;
    loc_FirmCode INTEGER;
begin
SELECT digits_only(trim(both FROM fvalue)) INTO bx_INN FROM bx_order_feature WHERE "bx_order_Номер" = arg_bx_order_id AND fname = 'ИНН';
IF '' = bx_INN THEN bx_INN := NULL; END IF;
SELECT digits_only(trim(both FROM fvalue)) INTO bx_KPP FROM bx_order_feature WHERE "bx_order_Номер" = arg_bx_order_id AND fname = 'КПП';

IF (bx_INN IS NOT NULL) THEN -- юр. лицо, у ИП нет КПП
    RAISE NOTICE 'find_firm: Юр. лицо, ИНН=%, КПП=%.', bx_INN, COALESCE(bx_KPP, '_не_задан_');
    len_inn := length(bx_INN);
    IF len_inn in (9, 12) THEN -- для ИП и Беларуси не м.б. КПП, защита от неверных значений
        bx_KPP := NULL; 
    END IF;

    IF len_inn IN (10,12) THEN
        loc_FirmCode := select_firm(bx_INN, bx_KPP); -- с учётом Статуса=10 (отец дублей)
        IF -1 = loc_FirmCode THEN -- Предприятие НЕ найдено
            loc_kpp := verify_KPP_by_INN(bx_INN);
            IF 'N/A'= loc_kpp THEN -- нет ответа 1С
                loc_kpp := bx_KPP;
            END IF;
            -- ELSE -- ищем с КПП из Инета
            loc_FirmCode := select_firm(bx_INN, loc_kpp);
            IF loc_FirmCode = -1 THEN -- с КПП из Инета тоже не найдено, создаём
                loc_FirmCode := create_firm(arg_bx_order_id, bx_INN, loc_kpp);
            END IF;
        ELSIF -2 = loc_FirmCode THEN -- не удалось выбрать из дублей Предприятия
            NULL;
        END IF; -- loc_FirmCode < 0
    ELSIF len_inn IN (9) THEN -- Республика Беларусь
        loc_FirmCode := select_firm(bx_INN, bx_KPP); -- с учётом Статуса=10 (отец дублей)
    ELSE
        loc_FirmCode := -3;
        RAISE NOTICE 'Непредвиденная длина ИНН=%, ИНН=% ', len_inn, bx_INN;
    END IF; -- length(INN)
ELSIF (bx_INN IS NULL) AND (bx_KPP IS NULL) AND NOT is_bank_payment(arg_bx_order_id) THEN -- физ. лицо, не м.б. Банковский перевод(22)
    RAISE NOTICE 'find_firm: Физ. лицо.';
    loc_FirmCode := 223719;
ELSE
    loc_FirmCode := -4;
END IF;

RETURN loc_FirmCode;
end
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
