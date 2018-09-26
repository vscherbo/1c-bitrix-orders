with fast_orders as (select bof."bx_order_Номер"
from bx_order_feature bof
where fname = 'Комментарий покупателя' and fvalue like '%Быстрый заказ%'
and dt_insert >= '2017-01-01 00:00:00')
, inet_bill as (select b."Сумма", b."Статус" from "Счета" b
where 
"ИнтернетЗаказ" in (select "bx_order_Номер" from fast_orders)
-- and "Сумма" > 50000
)
select 'payed', sum("Сумма"), count("Сумма"), sum("Сумма")/count("Сумма") from (
select "Сумма" from inet_bill
where "Статус" >=2 
) payed
union
select 'unpayed', sum("Сумма"), count("Сумма"), sum("Сумма")/count("Сумма") from (
select "Сумма" from inet_bill
where "Статус" <2 
) unpayed