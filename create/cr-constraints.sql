
--FK_bx_buyer_id

-- !!! sb_id NOT unique
--ALTER TABLE bx_order
--  ADD CONSTRAINT "FK_bx_buyer_id" FOREIGN KEY (sb_id) REFERENCES bx_buyer (sb_id) ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE bx_order
  ADD CONSTRAINT "UX_bx_order_id" UNIQUE ("Номер");

ALTER TABLE bx_order_feature
  ADD CONSTRAINT "FK_bx_order" FOREIGN KEY (bx_order_Номер) REFERENCES bx_order ("Номер") ON UPDATE NO ACTION ON DELETE NO ACTION;


ALTER TABLE bx_order_item
  ADD CONSTRAINT "FK_bx_order" FOREIGN KEY (bx_order_Номер) REFERENCES bx_order ("Номер") ON UPDATE NO ACTION ON DELETE NO ACTION;

CREATE INDEX "FKI_bx_order_Номер_item" ON bx_order_item USING btree ("bx_order_Номер");
CREATE INDEX "FKI_bx_order_Номер_feature" ON bx_order_feature USING btree ("bx_order_Номер");


