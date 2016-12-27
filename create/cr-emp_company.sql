-- Table: emp_company

-- DROP TABLE emp_company;

CREATE TABLE emp_company
(
  "Код" integer NOT NULL, -- Предприятия.Код
  "КодРаботника" integer NOT NULL,
  bx_buyer_id INTEGER,
  CONSTRAINT "emp_company_PK" PRIMARY KEY ("Код", "КодРаботника")
)
WITH (
  OIDS=FALSE
);
ALTER TABLE emp_company
  OWNER TO arc_energo;
COMMENT ON TABLE emp_company
  IS 'Отношение многие-ко-многим между Преприятия и Работники';
COMMENT ON COLUMN emp_company."Код" IS 'Предприятия.Код';

