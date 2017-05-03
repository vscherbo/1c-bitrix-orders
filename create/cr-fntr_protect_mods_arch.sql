CREATE OR REPLACE FUNCTION fntr_protect_mods_arch()
  RETURNS trigger AS
$BODY$
BEGIN
   RAISE EXCEPTION E'Попытка обновить архивную версию: dev_id=[%], mod_id=[%], version_num=[%]',  OLD.dev_id, OLD.mod_id, OLD.version_num;
   RETURN NEW;   
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
COMMENT ON FUNCTION fntr_protect_mods_arch() IS 'Предотвращает редактирование архивной версии';
