\set QUIET on
\t on
-- summary
select 'Автосчёт не создан: ' || count(*)
FROM arc_energo.bx_order bo
where
bo.billcreated not in (select * from vw_autobill_created) -- (1,2,6,7,10) -- прочее, ошибки
and dt_insert > now()- '1 day'::INTERVAL;

select 'Создан частичный автосчёт: ' || count(*) 
FROM arc_energo.bx_order bo 
where 
bo.billcreated in (select * from vw_autobill_partly) -- (2,6,7,10) -- частичный
and dt_insert > now()- '1 day'::INTERVAL;

select aub_rep.rep_text from (
with aub as (select bo.*
from bx_order bo
where bo.billcreated = 1 -- полный 
and bo.dt_insert > now()- '1 day'::interval)
-- and bo.dt_insert between '2017-08-18' and '2017-08-19')
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
order by 1) aub_rep;

-- in details
\echo
select 'Автосчёт не создан: ' || count(*)
FROM arc_energo.bx_order bo
where
bo.billcreated not in (select * from vw_autobill_created) -- (1,2,6,7,10) -- прочее, ошибки
and dt_insert > now()- '1 day'::INTERVAL;

\t off
SELECT bx_order_no AS "Заказ", format('%s: %s', descr, abr.ab_reason) AS "Описание"
            FROM aub_log
            left join autobill_reason abr on abr.ab_code = res_code
            where 
            res_code NOT IN (select * from vw_autobill_created)  -- (1,2,6,7,10) 
            AND mod_id = '-1' AND dt_insert > now()- '1 day'::interval
            and not exists (SELECT 1 FROM aub_log al1
                                     where aub_log.bx_order_no = al1.bx_order_no 
                                           and al1.res_code IN (select * from vw_autobill_created) -- (1,2,6,7,10)
                                           and mod_id = '-1')
            ORDER BY id;

\echo
\t on
select 'Создан частичный автосчёт: ' || count(*) 
FROM arc_energo.bx_order bo 
where 
bo.billcreated in (select * from vw_autobill_partly) -- (2,6,7,10) -- частичный
and dt_insert > now()- '1 day'::INTERVAL;
\t off
SELECT bx_order_no AS "Заказ", descr AS "Описание"
FROM aub_log 
    WHERE bx_order_no IN
        (SELECT bx_order_no
            FROM aub_log
            where 
            res_code IN (select * from vw_autobill_partly) -- (2,6,7,10)
            AND mod_id = '-1' AND dt_insert > now()- '1 day'::INTERVAL)
AND res_code IS NOT NULL            
ORDER BY id;



\echo
\t on
select aub_rep.rep_text from (
with aub as (select bo.*
from bx_order bo
where bo.billcreated = 1 -- полный 
and bo.dt_insert > now()- '1 day'::interval)
-- and bo.dt_insert between '2017-08-18' and '2017-08-19')
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
order by 1) aub_rep;
\t off
\echo
SELECT bx_order_no AS "Заказ", descr AS "Описание"
FROM aub_log
    WHERE bx_order_no IN
        (SELECT bx_order_no
            FROM aub_log
            WHERE mod_id='-1'
            AND res_code=1
            AND dt_insert > now()- '1 day'::INTERVAL)
AND res_code=1
ORDER BY id;
