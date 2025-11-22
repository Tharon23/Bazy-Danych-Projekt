-- ZARZĄDZANIE BEZPIECZEŃSTWEM
-- Uwaga: W prawdziwym życiu tworzymy użytkowników z hasłami.
-- Tutaj tworzymy GRUPY (ROLE), do których potem przypisuje się pracowników.

-- 1. Rola: KIEROWNIK (Ma pełną władzę nad danymi)
CREATE ROLE rola_kierownik;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rola_kierownik;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO rola_kierownik;

-- -- 2. Rola: MECHANIK (Widzi zlecenia, auta i części. Nie widzi faktur i klientów)
-- CREATE ROLE rola_mechanik;

-- Mechanik może czytać o autach i częściach
GRANT SELECT ON pojazdy, czesci TO rola_mechanik;

-- Mechanik widzi swoje zlecenia i może zmieniać ich status oraz opis
GRANT SELECT, UPDATE(status, opis, data_zakonczenia) ON zlecenia TO rola_mechanik;

-- Mechanik może pobierać części (dodawać wpisy do tabeli łączącej)
GRANT INSERT, SELECT ON czesci_zlecenia TO rola_mechanik;
GRANT USAGE, SELECT ON SEQUENCE czesci_zlecenia_id_czesci_zlecenia_seq TO rola_mechanik;

-- WAŻNE: Odbieramy dostęp do faktur (dla pewności, choć domyślnie i tak nie ma)
REVOKE ALL ON faktury, platnosci FROM rola_mechanik;


-- 3. Rola: RECEPCJA (Obsługa klienta, tworzenie zleceń, fakturowanie)
-- CREATE ROLE rola_recepcja;

-- Recepcja widzi i edytuje klientów oraz auta
GRANT ALL ON klienci, pojazdy TO rola_recepcja;
GRANT USAGE, SELECT ON SEQUENCE klienci_id_klienta_seq, pojazdy_id_pojazdu_seq TO rola_recepcja;

-- Recepcja tworzy zlecenia
GRANT INSERT, SELECT, UPDATE ON zlecenia TO rola_recepcja;
GRANT USAGE, SELECT ON SEQUENCE zlecenia_id_zlecenia_seq TO rola_recepcja;

-- Recepcja wystawia faktury
GRANT ALL ON faktury, platnosci TO rola_recepcja;
GRANT USAGE, SELECT ON SEQUENCE faktury_id_faktury_seq, platnosci_id_platnosci_seq TO rola_recepcja;

-- PRZYKŁAD UTWORZENIA KONKRETNEGO UŻYTKOWNIKA (Login: janek, Hasło: tajne)
-- CREATE USER janek WITH PASSWORD 'tajne';
-- GRANT rola_mechanik TO janek;