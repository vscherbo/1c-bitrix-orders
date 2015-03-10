-- Table: bx_buyer

-- DROP TABLE bx_buyer;

CREATE TABLE bx_buyer
(
  bx_buyer_id integer NOT NULL,
  dt_insert timestamp without time zone DEFAULT now(),
  bx_logname character varying,
  bx_name character varying,
  CONSTRAINT "PK_bx_buyer" PRIMARY KEY (bx_buyer_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE bx_buyer
  OWNER TO arc_energo;
