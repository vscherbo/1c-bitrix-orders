-- Table: bx_order

DROP TABLE bx_order CASCADE;

CREATE TABLE bx_order
(
  id serial NOT NULL,
  dt_insert timestamp without time zone DEFAULT now(),
  bx_buyer_id integer,
  "Ид" numeric,
  "Номер" integer, -- bx_order_id
  "Дата" timestamp without time zone,
  "ХозОперация" character varying,
  "Роль" character varying,
  "Валюта" character varying,
  "Курс" numeric(19,4),
  "Сумма" numeric(19,4),
  "Время" character varying,
  "Комментарий" character varying,
  "Счет" integer,
  billcreated integer DEFAULT 0, -- 0 - новый загруженный заказ...
  "НомерВерсии" character varying(10),
  CONSTRAINT "PK_bx_order" PRIMARY KEY (id),
  CONSTRAINT "UX_bx_order_id" UNIQUE ("Номер")
)
WITH (
  OIDS=FALSE
);
ALTER TABLE bx_order
  OWNER TO arc_energo;
COMMENT ON COLUMN bx_order."Номер" IS 'bx_order_id';
COMMENT ON COLUMN bx_order.billcreated IS '0 - новый загруженный заказ
1 - счёт создан
2 - счёт не создан, не все позиции синхронизированы
3 - счёт не создан, отсутствуют позиции заказа (ошибка импорта)';

