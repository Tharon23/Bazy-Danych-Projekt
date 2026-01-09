-- Konfiguracja ról i uprawnień bazodanowych

-- 0. Czyszczenie starych ról

DROP ROLE IF EXISTS rola_kierownik;
DROP ROLE IF EXISTS rola_mechanik;
DROP ROLE IF EXISTS rola_recepcja;

-- 1. Rola: KIEROWNIK (Pełny dostęp do danych)
CREATE ROLE rola_kierownik;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rola_kierownik;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO rola_kierownik;

-- 2. Rola: MECHANIK (Ograniczony dostęp operacyjny)
CREATE ROLE rola_mechanik;
GRANT CONNECT ON DATABASE "warsztat" TO rola_mechanik;
GRANT USAGE ON SCHEMA public TO rola_mechanik;

-- Uprawnienia odczytu (Pojazdy, Części, Zlecenia)
GRANT SELECT ON pojazdy, czesci, zlecenia TO rola_mechanik;

-- Uprawnienia edycji (Status i opis zlecenia)
GRANT UPDATE(status, opis, data_zakonczenia) ON zlecenia TO rola_mechanik;

-- Uprawnienia do pobierania części (INSERT do tabeli łączącej)
GRANT INSERT, SELECT ON czesci_zlecenia TO rola_mechanik;
GRANT USAGE ON SEQUENCE czesci_zlecenia_id_czesci_zlecenia_seq TO rola_mechanik;

-- 3. Rola: RECEPCJA (Obsługa klienta i fakturowanie)
CREATE ROLE rola_recepcja;
GRANT CONNECT ON DATABASE "warsztat" TO rola_recepcja;
GRANT USAGE ON SCHEMA public TO rola_recepcja;

-- Zarządzanie klientami i pojazdami
GRANT ALL ON klienci, pojazdy TO rola_recepcja;
GRANT USAGE, SELECT ON SEQUENCE klienci_id_klienta_seq, pojazdy_id_pojazdu_seq TO rola_recepcja;

-- Tworzenie zleceń
GRANT INSERT, SELECT, UPDATE ON zlecenia TO rola_recepcja;
GRANT USAGE, SELECT ON SEQUENCE zlecenia_id_zlecenia_seq TO rola_recepcja;

-- Fakturowanie i płatności
GRANT ALL ON faktury, platnosci TO rola_recepcja;
GRANT USAGE, SELECT ON SEQUENCE faktury_id_faktury_seq, platnosci_id_platnosci_seq TO rola_recepcja;

-- Dostęp do widoków
GRANT SELECT ON widok_aktywne_zlecenia TO rola_recepcja;