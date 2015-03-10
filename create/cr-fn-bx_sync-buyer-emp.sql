CREATE OR REPLACE FUNCTION fn_bx_sync_buyer_emp("anEmail" varchar)
  RETURNS void AS
$BODY$
DECLARE 
  buyer record;
  emp record;
begin
  SELECT * into buyer from bx_buyer WHERE email="anEmail";
  select e.* into emp from "Работники" e, vwPersonalBuyer p where e."Код" = 223719 AND p.email = "anEmail" AND p.email = e."ЕАдрес";
  IF (emp IS NULL) THEN -- new emp
     --RAISE NOTICE '
     insert INTO "Работники" ("КодРаботника", "Код", bx_buyer_id, "Дата", "ФИО", "ЕАдрес") values ((SELECT MAX("КодРаботника")+1 FROM "Работники"), 223719, buyer.bx_buyer_id, now(), buyer.name, buyer.email);
  else 
     -- RAISE NOTICE '
     UPDATE "Работники" set bx_buyer_id = buyer.bx_buyer_id, "Дата" = now() WHERE "КодРаботника" = emp."КодРаботника";
--  elsif buyer.email != emp."ЕАдрес" THEN 
        --RAISE NOTICE 'UPDATE "Работники" set "ЕАдрес" = buyer.email, "Дата" = now() WHERE "КодРаботника" = emp."КодРаботника";' ;
--        RAISE NOTICE 'Email: old/new %/%', emp."ЕАдрес", buyer.email;
--  Elsif buyer.name != emp."ФИО" THEN
        -- RAISE NOTICE 'UPDATE "Работники" set "ФИО" = buyer.name, "Дата" = now() WHERE "КодРаботника" = emp."КодРаботника";' ;
--        RAISE NOTICE 'ФИО: old/new %/%', emp."ФИО", buyer.name;
  END if;

end
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
