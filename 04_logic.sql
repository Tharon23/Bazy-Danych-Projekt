-- Logika biznesowa: Funkcje, Triggery, Procedury Składowane

-- 1. Weryfikacja dostępności mechanika
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
        RETURN FALSE;
    ELSE
        RETURN TRUE;
    END IF;
END;
$$;

-- 2. Automatyzacja gospodarki magazynowej
CREATE OR REPLACE FUNCTION aktualizuj_stan_magazynu() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF (SELECT ilosc_na_stanie FROM czesci WHERE id_czesci = NEW.id_czesci) < NEW.ilosc THEN
        RAISE EXCEPTION 'Brak wystarczajacej ilosci towaru w magazynie (ID: %)', NEW.id_czesci;
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

-- 3. Audyt zmian w cenniku
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

-- 4. Procedura zamknięcia zlecenia
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

-- 5. Kalkulacja kosztów
CREATE OR REPLACE FUNCTION oblicz_koszt_zlecenia(p_id_zlecenia integer) RETURNS numeric
LANGUAGE plpgsql AS $$
DECLARE
    v_koszt_czesci numeric DEFAULT 0;
    v_koszt_uslug numeric DEFAULT 0;
    v_koszt_robocizny numeric DEFAULT 0;
BEGIN
    SELECT COALESCE(SUM(c.cena * cz.ilosc), 0) INTO v_koszt_czesci
    FROM czesci_zlecenia cz
    JOIN czesci c ON cz.id_czesci = c.id_czesci
    WHERE cz.id_zlecenia = p_id_zlecenia;

    SELECT COALESCE(SUM(u.cena * uz.ilosc * (1 - uz.rabat / 100.0)), 0) INTO v_koszt_uslug
    FROM uslugi_zlecenia uz
    JOIN uslugi u ON uz.id_uslugi = u.id_uslugi
    WHERE uz.id_zlecenia = p_id_zlecenia;

    SELECT COALESCE(koszt_robocizny, 0) INTO v_koszt_robocizny
    FROM zlecenia
    WHERE id_zlecenia = p_id_zlecenia;

    RETURN v_koszt_czesci + v_koszt_uslug + v_koszt_robocizny;
END;
$$;

-- 6. Blokada edycji zakończonych zleceń
CREATE OR REPLACE FUNCTION zablokuj_modyfikacje_zakonczonych() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
    v_status varchar;
BEGIN
    IF (TG_OP = 'DELETE') THEN
        SELECT status INTO v_status FROM zlecenia WHERE id_zlecenia = OLD.id_zlecenia;
    ELSE
        SELECT status INTO v_status FROM zlecenia WHERE id_zlecenia = NEW.id_zlecenia;
    END IF;

    IF v_status IN ('Zakonczone', 'Anulowane') THEN
        RAISE EXCEPTION 'Operacja zabroniona: Zlecenie posiada status %', v_status;
    END IF;

    IF (TG_OP = 'DELETE') THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_blokada_czesci
BEFORE INSERT OR UPDATE OR DELETE ON czesci_zlecenia
FOR EACH ROW EXECUTE FUNCTION zablokuj_modyfikacje_zakonczonych();

CREATE TRIGGER trigger_blokada_uslug
BEFORE INSERT OR UPDATE OR DELETE ON uslugi_zlecenia
FOR EACH ROW EXECUTE FUNCTION zablokuj_modyfikacje_zakonczonych();

-- 7. Procedura transakcyjna (Dodanie klienta i pojazdu)
CREATE OR REPLACE PROCEDURE dodaj_klienta_z_pojazdem(
    IN p_imie varchar, 
    IN p_nazwisko varchar, 
    IN p_telefon varchar, 
    IN p_email varchar,
    IN p_marka varchar,
    IN p_model varchar,
    IN p_rok int,
    IN p_nr_rejestracyjny varchar,
    IN p_vin varchar
)
LANGUAGE plpgsql AS $$
DECLARE
    v_nowe_id_klienta int;
BEGIN
    INSERT INTO klienci (imie, nazwisko, telefon, email)
    VALUES (p_imie, p_nazwisko, p_telefon, p_email)
    RETURNING id_klienta INTO v_nowe_id_klienta;

    INSERT INTO pojazdy (id_klienta, marka, model, rok, nr_rejestracyjny, vin)
    VALUES (v_nowe_id_klienta, p_marka, p_model, p_rok, p_nr_rejestracyjny, p_vin);

    RAISE NOTICE 'Transakcja zakończona: Dodano klienta (ID: %) oraz pojazd (VIN: %).', v_nowe_id_klienta, p_vin;
END;
$$;