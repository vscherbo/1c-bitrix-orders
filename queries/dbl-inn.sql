(select "ИНН", count(*) --, "ОГРН", "КПП"
from "Предприятия"
WHERE "ИНН" IS NOT NULL AND "ИНН" <> '0' 
GROUP BY "ИНН" 
having count(*) > 4
ORDER BY 2 DESC) dbl