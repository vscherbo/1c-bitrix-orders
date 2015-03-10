-- Function: fn_bx_buyer2emp(integer)

-- DROP FUNCTION fn_bx_buyer2emp(integer);

CREATE OR REPLACE FUNCTION fn_bx_buyer2emp("anID" integer)
  RETURNS void AS
$BODY$
DECLARE 
  buyer record;
  emp record;
begin
  SELECT * into buyer from bx_buyer WHERE id=anID;
  select * into emp from "Работники" e where e."Код" = 223719 AND buyer.bx_buyer_id = e.bx_buyer_id;
  IF (emp IS NULL) THEN -- new emp
        insert INTO "Работники" ("КодРаботника", "Код", bx_buyer_id, "Дата", "ФИО", "ЕАдрес") 
                         values ((SELECT MAX("КодРаботника")+1 FROM "Работники"), 223719, buyer.bx_buyer_id, now(), buyer.name, buyer.email);
  elsif buyer.email != emp."ЕАдрес" THEN 
        UPDATE "Работники" set "ЕАдрес" = buyer.email, "Дата" = now() WHERE "КодРаботника" = emp."КодРаботника";
  Elsif buyer.name != emp."ФИО" THEN
        UPDATE "Работники" set "ФИО" = buyer.name, "Дата" = now() WHERE "КодРаботника" = emp."КодРаботника";
  END if;

end
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_bx_buyer2emp(integer)
  OWNER TO arc_energo;
