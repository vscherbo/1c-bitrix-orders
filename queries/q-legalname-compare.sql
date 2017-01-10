SELECT "Код", upper("Предприятие") AS "Предприятие", upper(newname) AS newname, "ЮрНазвание"
FROM (
SELECT  "Код"
       ,"Предприятие"
       , "ЮрНазвание"
--       , aname, lname, lname[2] l2
, TRIM(lname[1] || lname[3]) || ' ' || lname[2] As newname
FROM       
(SELECT "Код"
       ,"Предприятие"
       , "ЮрНазвание"
       , regexp_replace("ЮрНазвание", '["''«»“]*', '', 'g') AS aname
, regexp_matches(
      regexp_replace("ЮрНазвание", '["''«»]*', '', 'g')
      , '(.*)(ООО|ОАО|ПАО|ЗАО|\mАО|АООТ|АОЗТ|ТОО)(.*)')
      AS lname
  FROM "Предприятия"
  ORDER BY "Код" DESC
  LIMIT 400
) as ln
) as names_compare
WHERE upper(newname) <> upper("Предприятие")
