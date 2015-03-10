-- Table: bx_order_item

-- DROP TABLE bx_order_item;

CREATE TABLE bx_order_item
(
  id serial NOT NULL,
  dt_insert timestamp without time zone DEFAULT now(),
  "bx_order_Номер" integer,
  "Ид" character varying,
  "Наименование" character varying,
  "БазоваяЕдиница" character varying,
  "ЦенаЗаЕдиницу" numeric(19,4),
  "Количество" numeric(19,4),
  "Сумма" numeric(19,4),
  "ИдКаталога" integer,
  "Код" integer,
  "НаименованиеПолное" character varying,
  "Коэффициент" numeric,
  CONSTRAINT "PK_bx_order_item" PRIMARY KEY (id),
  CONSTRAINT "FK_bx_order" FOREIGN KEY ("bx_order_Номер")
      REFERENCES bx_order ("Номер") MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE bx_order_item
  OWNER TO arc_energo;

-- Index: "FKI_bx_order_Номер_item"

-- DROP INDEX "FKI_bx_order_Номер_item";

CREATE INDEX "FKI_bx_order_Номер_item"
  ON bx_order_item
  USING btree
  ("bx_order_Номер");

