-- Funkcja 1: Sprawdza dostępność mechanika
CREATE OR REPLACE FUNCTION czy_mechanik_dostepny(p_id_mechanika integer) RETURNS boolean
LANGUAGE plpgsql AS $$
DECLARE
    v_liczba_zlecen INT;
BEGIN
    SELECT COUNT(*) INTO v_liczba_zlecen
    FROM zlecenia
    WHERE id_mechanika = p_id_mechanika 
      AND status IN ('W trakcie', 'Przyjete', 'Oczekuje na czesci');
      
    IF v_liczba_zlecen > 0 THEN
        RETURN FALSE; -- Zajety
    ELSE
        RETURN TRUE; -- Wolny
    END IF;
END;
$$;

-- Funkcja 2: Trigger aktualizujący magazyn po wydaniu części
CREATE OR REPLACE FUNCTION aktualizuj_stan_magazynu() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF (SELECT ilosc_na_stanie FROM czesci WHERE id_czesci = NEW.id_czesci) < NEW.ilosc THEN
        RAISE EXCEPTION 'Brak wystarczajacej ilosci towaru w magazynie!';
    END IF;

    UPDATE czesci
    SET ilosc_na_stanie = ilosc_na_stanie - NEW.ilosc
    WHERE id_czesci = NEW.id_czesci;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_zdejmij_czesci
AFTER INSERT ON czesci_zlecenia
FOR EACH ROW EXECUTE FUNCTION aktualizuj_stan_magazynu();

-- Funkcja 3: Logowanie zmian cen usług (Audyt)
CREATE OR REPLACE FUNCTION loguj_zmiane_ceny() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.cena <> OLD.cena THEN
        INSERT INTO logi_zmian_cen (nazwa_uslugi, stara_cena, nowa_cena, uzytkownik)
        VALUES (OLD.nazwa, OLD.cena, NEW.cena, current_user);
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_audit_ceny
AFTER UPDATE ON uslugi
FOR EACH ROW EXECUTE FUNCTION loguj_zmiane_ceny();

-- Procedura: Zakończenie zlecenia (ustawia datę i status)
CREATE OR REPLACE PROCEDURE zakoncz_zlecenie(IN p_id_zlecenia integer)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM zlecenia WHERE id_zlecenia = p_id_zlecenia) THEN
        RAISE EXCEPTION 'Zlecenie o ID % nie istnieje', p_id_zlecenia;
    END IF;

    UPDATE zlecenia
    SET status = 'Zakonczone',
        data_zakonczenia = CURRENT_TIMESTAMP
    WHERE id_zlecenia = p_id_zlecenia;
    
    RAISE NOTICE 'Zlecenie % zostalo pomyslnie zakonczone.', p_id_zlecenia;
END;
$$;