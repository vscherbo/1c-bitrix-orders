CREATE OR REPLACE VIEW vwdev_out_of_sync AS 
 SELECT v."Категория",
    v."Модель",
    v."Стат",
    v."Предприятие",
    v."КодСодержания",
    v."Дил",
    v."НазваниевСчет",
    v.nosinc_dm
   FROM vw_import_or_dealers v
     LEFT JOIN ( SELECT modifications."КодСодержания" AS ks
           FROM modifications
          WHERE modifications.version_num = 1 AND NOT modifications."КодСодержания" IS NULL
        UNION
         SELECT modif_ks_nosinc."КодСодержания"
           FROM modif_ks_nosinc
          WHERE modif_ks_nosinc.version_num = 1) t1 ON v."КодСодержания" = t1.ks
  WHERE NOT COALESCE(v.nosinc_dm, false) AND t1.ks IS NULL;

ALTER TABLE vwdev_out_of_sync
  OWNER TO arc_energo;