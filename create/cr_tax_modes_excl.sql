-- Drop table

-- DROP TABLE arc_energo.tax_modes_excl;

CREATE TABLE arc_energo.tax_modes_excl (
        inn text NOT NULL,
        CONSTRAINT tax_modes_excl_pkey PRIMARY KEY (inn)
);
