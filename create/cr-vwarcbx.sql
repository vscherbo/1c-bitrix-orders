-- View: vwarcbx

-- DROP VIEW vwarcbx;

CREATE OR REPLACE VIEW vwarcbx AS 
 SELECT dev_sinccat_arcbx.ie_xml_id,
    dev_sinccat_arcbx."КодСодержания",
    dev_sinccat_arcbx.id,
    dev_sinccat_arcbx."Номер",
    dev_sinccat_arcbx."Когда"
   FROM dev_sinccat_arcbx
  WHERE dev_sinccat_arcbx."Разбор" = 1;

ALTER TABLE vwarcbx
  OWNER TO arc_energo;
