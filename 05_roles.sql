-- Tworzenie ról (jeśli baza na to pozwala, lokalnie tak)
-- UWAGA: Jeśli uruchamiasz to na hostingu, możesz nie mieć praw do CREATE ROLE.
-- Wtedy użyj tylko sekcji GRANT.

-- 1. Rola: Mechanik (widzi zlecenia, nie widzi faktur)
CREATE ROLE rola_mechanik;
GRANT CONNECT ON DATABASE "warsztat" TO rola_mechanik; -- Podmień nazwę
GRANT USAGE ON SCHEMA public TO rola_mechanik;

-- Uprawnienia mechanika
GRANT SELECT, UPDATE ON zlecenia TO rola_mechanik;
GRANT SELECT ON pojazdy, czesci TO rola_mechanik;
GRANT INSERT ON czesci_zlecenia TO rola_mechanik; -- Może pobierać części
-- Mechanik NIE MA dostępu do tabeli 'faktury' ani 'stawka_godzinowa' kolegów

-- 2. Rola: Recepcja (może dodawać klientów i zlecenia)
CREATE ROLE rola_recepcja;
GRANT ALL ON klienci, pojazdy, zlecenia TO rola_recepcja;
GRANT SELECT ON widok_aktywne_zlecenia TO rola_recepcja;

-- Przykładowy użytkownik
-- CREATE USER jan_mechanik WITH PASSWORD 'haslo123';
-- GRANT rola_mechanik TO jan_mechanik;