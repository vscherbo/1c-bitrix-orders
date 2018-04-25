CREATE OR REPLACE VIEW vw_import_or_dealers AS 
 SELECT k."Категория",
    n."Модель",
    t1."Стат",
    p."Предприятие",
    s."КодСодержания",
        CASE
            WHEN COALESCE(s."Дилерский", false) THEN '+'::text
            ELSE NULL::text
        END AS "Дил",
    s."НазваниевСчет",
    s."Кратко",
    s."КодТНВЭД",
    s.nosinc_dm
   FROM "Содержание" s
     --LEFT JOIN vwsupcurrent v ON s."КодСодержания" = v."КодСодержания"
     LEFT JOIN "Предприятия" p ON s."Поставщик" = p."Код"
LEFT JOIN ( SELECT "КодСодержания",
            'Разраб'::text AS "Стат"
           FROM devmod.modifications
          WHERE modifications.version_num = 0) t1 ON s."КодСодержания" = t1."КодСодержания"
     JOIN "Наименование" n ON s."КодНаименования" = n."КодНаименования"
     JOIN "Категория" k ON n."КодКатегории" = k."КодКатегории"
  WHERE COALESCE(s."Активность", false) AND (s."Поставщик" = 215878 OR COALESCE(s."Дилерский", false)) AND s.stop IS NULL;

ALTER TABLE vw_import_or_dealers
  OWNER TO arc_energo;
