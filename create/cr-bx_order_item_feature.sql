-- Table: bx_order_item_feature

DROP TABLE bx_order_item_feature;

CREATE TABLE bx_order_item_feature
(
  id serial NOT NULL,
  dt_insert timestamp without time zone DEFAULT now(),
  bx_order_item_id character varying,
  fname character varying,
  fvalue character varying,
  "bx_order_Номер" integer,
  CONSTRAINT "PK_bx_order_item_feature" PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE bx_order_item_feature
  OWNER TO arc_energo;
