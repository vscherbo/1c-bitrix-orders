CREATE OR REPLACE FUNCTION bx_order_email(
    arg_bx_order_id INTEGER)
returns text
language plpgsql 
as
$body$
declare
    loc_email text;
    loc_email1 text;
    loc_email2 text;
begin

SELECT fvalue INTO loc_email FROM bx_order_feature WHERE "bx_order_Номер" = arg_bx_order_id AND fname = 'Контактный Email';
SELECT fvalue INTO loc_email1 FROM bx_order_feature WHERE "bx_order_Номер" = arg_bx_order_id AND fname = 'EMail';
IF 'siteorders@kipspb.ru' <> loc_email1 AND loc_email <> loc_email1 THEN
    loc_email := loc_email1;
    RAISE NOTICE 'bx_order_email: заменяем _контактный email_ на EMail';
END IF;
-- 'EMail покупателя' приоритетнее, чем 'Контактный EMail', который дублируется
SELECT fvalue INTO loc_email2 FROM bx_order_feature WHERE "bx_order_Номер" = arg_bx_order_id AND fname = 'EMail покупателя';
IF loc_email <> loc_email2 THEN
    loc_email := loc_email2;
    RAISE NOTICE 'bx_order_email: заменяем _контактный email_ на EMail покупателя';
END IF;
loc_email := COALESCE(loc_email, '');
return loc_email;
end;
$body$;
 
