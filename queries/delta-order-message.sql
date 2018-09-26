SELECT bo."Дата", bo."Время", dt_insert, q."Дата"   
,  age(
--GREATEST(msg_timestamp , ("Дата"::timestamp + "Время"::time))
--, LEAST(msg_timestamp , ("Дата"::timestamp + "Время"::time))
GREATEST(dt_insert, q."Дата")
, LEAST(dt_insert, q."Дата")
) as delta
, bo."Счет", "Ид"
FROM bx_order bo -- vw_bx_order_today
join "ДозвонНТУ" q on q."Счет" = bo."Счет"
where bo."Дата"::timestamp >= '2017-10-30'
and billcreated = 1
and "КтоЗвонил" = 'робот' 
and position('@kipspb.ru' in "КомуПередал") = 0
and status=0
and "Примечание" like 'Ваш заказ % на сайте kipspb.ru%' 
-- and "Счет"/1000000 = 55
order by delta desc