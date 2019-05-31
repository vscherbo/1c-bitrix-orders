CREATE OR REPLACE VIEW arc_energo.vw_autobill_created
AS SELECT autobill_reason.ab_code
   FROM autobill_reason
  WHERE autobill_reason.bill_status > 0;
