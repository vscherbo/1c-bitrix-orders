create or replace function inetbill_mgr()
returns integer
language sql
as
$body$
    -- select 38 as result;
    -- select 89 as result;
select "Менеджер" as result from (
SELECT 10 as priority, "Менеджер" FROM "Сотрудники" where "Активность" = true and "Менеджер" = 38 -- Гараханян
union 
SELECT 20 as priority, "Менеджер" FROM "Сотрудники" where "Активность" = true and "Менеджер" = 89 -- Хапёрский
union 
SELECT 30 as priority, "Менеджер" FROM "Сотрудники" where "Активность" = true and "Менеджер" = 12 -- Шалаевский
union 
SELECT 40 as priority, "Менеджер" FROM "Сотрудники" where "Активность" = true and "Менеджер" = 41 -- Робот ???
ORDER BY priority LIMIT 1) im

$body$
