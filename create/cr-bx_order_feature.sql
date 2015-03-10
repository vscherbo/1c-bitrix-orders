-- Table: bx_order_feature

-- DROP TABLE bx_order_feature;

CREATE TABLE bx_order_feature
(
  id serial NOT NULL,
  dt_insert timestamp without time zone DEFAULT now(),
  "bx_order_Номер" integer,
  fname character varying,
  fvalue character varying,
  CONSTRAINT "PK_bx_order_feature" PRIMARY KEY (id),
  CONSTRAINT "FK_bx_order" FOREIGN KEY ("bx_order_Номер")
      REFERENCES bx_order ("Номер") MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE bx_order_feature
  OWNER TO arc_energo;

-- Index: "FKI_bx_order_Номер_feature"

-- DROP INDEX "FKI_bx_order_Номер_feature";

CREATE INDEX "FKI_bx_order_Номер_feature"
  ON bx_order_feature
  USING btree
  ("bx_order_Номер");

