CREATE
    TRIGGER "tr_mods_BU" BEFORE UPDATE
        -- OF "КодСодержания"
        ON modifications FOR EACH ROW
        WHEN(
            (
               old.version_num > 1
            )
        ) EXECUTE PROCEDURE fntr_protect_mods_arch()