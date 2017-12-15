CREATE TABLE arc_energo.autobill_reason (
	ab_result varchar NOT NULL,
	ab_code int4 NOT NULL,
	ab_reason text NOT NULL,
	bill_status int4 NOT NULL DEFAULT 0,
	CONSTRAINT autobill_reason_pk PRIMARY KEY (ab_result,ab_code,ab_reason)
)
WITH (
	OIDS=FALSE
) ;
