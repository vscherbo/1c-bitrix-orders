-- View: vwbxdev_synced

-- DROP VIEW vwbxdev_synced;

CREATE OR REPLACE VIEW vwbxdev_synced AS 
 SELECT d.bx_dev_id,
    d.ie_xml_id,
    d.ie_name,
    d.ip_prop475,
    d.ip_prop474,
    d.ip_prop609,
    d.ip_prop689,
    d.ip_prop103,
    d.ip_prop675,
    d.ip_prop674,
    d.ip_prop656,
    d.ip_prop657,
    d.ip_prop663,
    d.ip_prop984,
    d.ip_prop658,
    d.ip_prop659,
    d.ip_prop661,
    d.ip_prop662,
    d.ip_prop660,
    d.ic_group0,
    d.ic_code0,
    d.ic_group1,
    d.ic_code1,
    d.ic_group2,
    d.ic_code2,
    d.ic_group3,
    d.ic_code3,
    d.cp_weight
   FROM devmod.bx_dev d,
    vwarcbx a
  WHERE d.ie_active = true AND d.ie_xml_id = a.ie_xml_id;

ALTER TABLE vwbxdev_synced
  OWNER TO arc_energo;
