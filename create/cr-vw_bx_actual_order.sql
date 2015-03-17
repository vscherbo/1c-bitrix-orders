-- View: vw_bx_actual_order

-- DROP VIEW vw_bx_actual_order;

CREATE OR REPLACE VIEW vw_bx_actual_order AS 
 SELECT bf.fvalue AS canceled,
    bo.id,
    bo.dt_insert,
    bo.bx_buyer_id,
    bo."Ид",
    bo."Номер",
    bo."Дата",
    bo."ХозОперация",
    bo."Роль",
    bo."Валюта",
    bo."Курс",
    bo."Сумма",
    bo."Время",
    bo."Комментарий",
    bo."Счет",
    bo.billcreated,
    bo."НомерВерсии"
   FROM bx_order bo,
    bx_order_feature bf
  WHERE bo."Номер" = bf."bx_order_Номер" AND bf.fname = 'Отменен'::character varying AND bf.fvalue <> 'true'::character varying;

ALTER TABLE vw_bx_actual_order
  OWNER TO arc_energo;
COMMENT ON VIEW vw_bx_actual_order
  IS 'Заказы, у которых признак "Отменен" не равен true';
