with rds as ( 
SELECT "КодСодержания", sum("Свободно") as RDS FROM arc_energo."Количество"
WHERE "КодСклада" = 49 group by "КодСодержания")
select * from
(select rds."КодСодержания", rds.RDS, foo.not_RDS
from rds 
join (select "КодСодержания" ks, sum("Свободно") not_RDS from "Количество" where "КодСодержания" in (select "КодСодержания" from rds) 
and "КодСклада" not in (49, 9) 
group by "КодСодержания") as foo
on foo.ks = "КодСодержания") full_rds
where rds < 5