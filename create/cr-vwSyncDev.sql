CREATE view vwSyncDev as 
select "КодСодержания",d.ie_name from dev_sinccat_arcbx s, devmod.bx_dev d
where s.Разбор=1
AND (d.ie_xml_id = s.ie_xml_id)
AND d.ie_active = 't'