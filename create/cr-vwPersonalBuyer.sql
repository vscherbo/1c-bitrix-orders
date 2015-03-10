-- View: vwpersonalbuyer

-- DROP VIEW vwpersonalbuyer;

CREATE OR REPLACE VIEW vwpersonalbuyer AS 
 SELECT DISTINCT b.bx_logname AS email,
    b.bx_name,
    b.bx_buyer_id
   FROM bx_buyer b,
    bx_order o
  WHERE o.bx_buyer_id = b.bx_buyer_id AND NOT (o."Номер" IN ( SELECT vwfirmorder."Номер"
           FROM vwfirmorder));

ALTER TABLE vwpersonalbuyer
  OWNER TO arc_energo;
