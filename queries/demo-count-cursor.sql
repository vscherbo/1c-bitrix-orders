DO $$
DECLARE 
  INN VARCHAR;
  Rec RECORD;
  -- curs CURSOR FOR select * from "Предприятия" where "ИНН" = INN;
  curs CURSOR FOR select * from "Предприятия" ;
  Cnt INTEGER;
BEGIN
    INN := '7107086941';
    OPEN curs;
    Cnt := 0;
    LOOP 
      FETCH curs INTO Rec; 
      EXIT WHEN NOT FOUND; 
      Cnt := Cnt + 1;
    END LOOP;
    RAISE NOTICE 'Cnt=%', Cnt;
END;
$$