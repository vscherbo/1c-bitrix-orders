select o."Номер", o."Дата", b.name, b.email
from bx_order o, bx_buyer b
where o.bx_buyer_id = b.bx_buyer_id
AND b.email NOT IN ('danshin', 'Sir', 'testik.platrona@yandex.ru')
AND o."Номер" NOT IN
(select o1."Номер"
from bx_order o1, bx_order_feature f1
where o1."Номер" = f1."bx_order_Номер"
and f1.fname = 'ИНН')
ORDER BY 1