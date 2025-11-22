-- 1. TABELA HISTORYCZNA (ARCHIWUM)
-- Tutaj trafią usunięte zlecenia. Ma te same kolumny co 'zlecenia' + data usunięcia.
CREATE TABLE zlecenia_archiwum (
    id_archiwum SERIAL PRIMARY KEY,
    id_zlecenia_org INTEGER,
    id_pojazdu INTEGER,
    id_mechanika INTEGER,
    data_przyjecia TIMESTAMP,
    data_zakonczenia TIMESTAMP,
    status VARCHAR(50),
    opis TEXT,
    koszt_robocizny NUMERIC(10,2),
    data_usuniecia TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    kto_usunal VARCHAR(100)
);

-- 2. FUNKCJA DO TRIGGERA ARCHIWIZUJĄCEGO
CREATE OR REPLACE FUNCTION archiwizuj_zlecenie()
RETURNS TRIGGER AS $$
BEGIN
    -- Przepisujemy dane usuwanego wiersza (OLD) do archiwum
    INSERT INTO zlecenia_archiwum (
        id_zlecenia_org, id_pojazdu, id_mechanika, data_przyjecia, 
        data_zakonczenia, status, opis, koszt_robocizny, kto_usunal
    )
    VALUES (
        OLD.id_zlecenia, OLD.id_pojazdu, OLD.id_mechanika, OLD.data_przyjecia, 
        OLD.data_zakonczenia, OLD.status, OLD.opis, OLD.koszt_robocizny, current_user
    );
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- 3. TRIGGER (URUCHAMIA SIĘ PRZED USUNIĘCIEM)
CREATE TRIGGER trigger_archiwizacja_zlecenia
BEFORE DELETE ON zlecenia
FOR EACH ROW EXECUTE FUNCTION archiwizuj_zlecenie();


-- 4. FUNKCJA RAPORTOWA: MIESIĘCZNE ZYSKI
-- Oblicza sumę z robocizny + zysk z części (zakładamy, że sprzedajemy je drożej niż kupujemy, ale tu policzymy sam obrót)
CREATE OR REPLACE FUNCTION raport_miesieczny(p_miesiac INT, p_rok INT)
RETURNS TABLE (
    miesiac INT,
    rok INT,
    liczba_zakonczonych_zlecen BIGINT,
    laczny_przychod NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p_miesiac,
        p_rok,
        COUNT(*),
        COALESCE(SUM(koszt_robocizny), 0) + 
        COALESCE((SELECT SUM(cz.ilosc * c.cena) 
                  FROM czesci_zlecenia cz 
                  JOIN czesci c ON cz.id_czesci = c.id_czesci 
                  WHERE cz.id_zlecenia IN (SELECT id_zlecenia FROM zlecenia WHERE EXTRACT(MONTH FROM data_zakonczenia) = p_miesiac AND EXTRACT(YEAR FROM data_zakonczenia) = p_rok)), 0)
    FROM zlecenia
    WHERE status = 'Zakonczone'
      AND EXTRACT(MONTH FROM data_zakonczenia) = p_miesiac
      AND EXTRACT(YEAR FROM data_zakonczenia) = p_rok;
END;
$$ LANGUAGE plpgsql;