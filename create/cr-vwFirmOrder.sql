-- View: vwfirmorder

-- DROP VIEW vwfirmorder;

CREATE OR REPLACE VIEW vwfirmorder AS 
 SELECT o."Номер"
   FROM bx_order o,
    bx_order_feature f
  WHERE o."Номер" = f."bx_order_Номер" AND f.fname = 'ИНН'::character varying;

ALTER TABLE vwfirmorder
  OWNER TO arc_energo;
