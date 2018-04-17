-- Drop table

-- DROP TABLE arc_energo.bx_order_missed

CREATE TABLE arc_energo.bx_order_missed (
	bx_order_id int4 NOT NULL,
	dt_insert timestamptz NULL DEFAULT clock_timestamp(),
	status int4 NULL DEFAULT 0,
	dt_sent timestamptz NULL,
	CONSTRAINT pk_bx_order_missed PRIMARY KEY (bx_order_id)
)
WITH (
	OIDS=FALSE
) ;

-- Permissions

GRANT ALL ON TABLE arc_energo.bx_order_missed TO arc_energo;
