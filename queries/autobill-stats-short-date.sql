\set QUIET on
\t on
-- summary
select 'Автосчёт не создан: ' || count(*)
FROM arc_energo.bx_order bo
where
bo.billcreated not in (select * from vw_autobill_created) -- (1,2,6,7,10) -- а прочее, ошибки
-- and bo.billcreated < 10000000  -- повторно принятый заказ с сайта
and bo.billcreated < 99  -- 99 - "не kipspb"
and dt_insert BETWEEN :aub_date::TIMESTAMP AND :aub_date::TIMESTAMP + '1 day'::INTERVAL;
-- and dt_insert > now()- '1 day'::INTERVAL;

select 'Создан частичный автосчёт: ' || count(*) 
FROM arc_energo.bx_order bo 
where 
bo.billcreated in (select * from vw_autobill_partly) -- (2,6,7,10) -- частичный
and dt_insert BETWEEN :aub_date::TIMESTAMP AND :aub_date::TIMESTAMP + '1 day'::INTERVAL;
-- and dt_insert > now()- '1 day'::INTERVAL;

select aub_rep.rep_text from (
with aub as (select bo.*
from bx_order bo
where bo.billcreated = 1 -- полный 
and dt_insert BETWEEN :aub_date::TIMESTAMP AND :aub_date::TIMESTAMP + '1 day'::INTERVAL)
-- and bo.dt_insert > now()- '1 day'::interval)
select 10, 'Автосчёт создан: ' || count(*) as rep_text FROM aub
union
select 20, '   в т.ч. дилерских: ' || count(*) FROM aub
join "Счета" on "Счета"."№ счета" = aub."Счет" and "Счета"."Дилерский"
union
select 30, '   в т.ч. юр.лиц: ' || count(*) FROM aub
join "Счета" on "Счета"."№ счета" = aub."Счет" and not "Счета"."Дилерский" and "Счета"."Код" <> 223719
union
select 35, '      в т.ч. юр.лиц без регистрации: ' || count(*) FROM aub
join bx_order_feature bof on bof."bx_order_Номер" = aub."Номер" and bof.fname = 'Комментарии покупателя' and bof.fvalue LIKE 'Быстрый заказ%'
join "Счета" on "Счета"."№ счета" = aub."Счет" and not "Счета"."Дилерский" and "Счета"."Код" <> 223719
union
select 40, '   в т.ч. физ.лиц: ' || count(*) FROM aub
join "Счета" on "Счета"."№ счета" = aub."Счет" and "Счета"."Код" = 223719
union
select 50, '      в т.ч. физ.лиц без регистрации: ' || count(*) FROM aub
join bx_order_feature bof on bof."bx_order_Номер" = aub."Номер" and bof.fname = 'Комментарии покупателя' and bof.fvalue LIKE 'Быстрый заказ%'
join "Счета" on "Счета"."№ счета" = aub."Счет" and "Счета"."Код" = 223719
union
select 60, 'в т.ч. менеджером 41: ' || count(*) FROM aub where aub."Счет" / 1000000 = 41
union
select 70, 'в т.ч. НЕ менеджером 41: ' || count(*) FROM aub
join "Счета" on "Счета"."№ счета" = aub."Счет" and not "Счета"."Дилерский" and aub."Счет" / 1000000 <> 41
order by 1
) aub_rep;

/**
with aub as (select bo.*
from bx_order bo
where bo.billcreated = 1 -- полный 
and bo.dt_insert > now()- '1 day'::interval)
select "Номер", dt_insert, aub."Сумма", "Счет", billcreated
FROM aub
join "Счета" on "Счета"."№ счета" = aub."Счет" and not "Счета"."Дилерский" and aub."Счет" / 1000000 <> 41
order by "Номер";
**/

SELECT row_number() over (), bx_order_no AS "Заказ", descr AS "Описание" --, res_code, mod_id 
FROM aub_log
    WHERE bx_order_no IN
        (SELECT bx_order_no
            FROM aub_log
            WHERE mod_id='-1'
            AND res_code=1
            -- AND dt_insert > now()- '1 day'::INTERVAL)
            and dt_insert BETWEEN :aub_date::TIMESTAMP AND :aub_date::TIMESTAMP + '1 day'::INTERVAL)
AND res_code>100
and mod_id='-1'
ORDER BY id;

SELECT :aub_date::TIMESTAMP, :aub_date::TIMESTAMP + '1 day'::INTERVAL;
