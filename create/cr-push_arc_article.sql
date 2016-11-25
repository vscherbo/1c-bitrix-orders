-- Function: push_arc_article(integer, text, integer)

-- DROP FUNCTION push_arc_article(integer, text, integer);

CREATE OR REPLACE FUNCTION push_arc_article(
    "Кому" integer,
    "Содержание" text,
    importance integer)
  RETURNS boolean AS
$BODY$
DECLARE
   loc_article_id INTEGER;
BEGIN
WITH inserted AS (
    INSERT INTO "Статьи"("Содержание", "ДатаСтатьи", "Автор", importance) 
    VALUES ("Содержание", clock_timestamp(), 0, 1)
    RETURNING "НомерСтатьи"
)

SELECT "НомерСтатьи" INTO loc_article_id FROM inserted;

INSERT INTO "Задания"("НомерСтатей", "Кому") VALUES (loc_article_id, "Кому");

RETURN FOUND;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION push_arc_article(integer, text, integer)
  OWNER TO arc_energo;

