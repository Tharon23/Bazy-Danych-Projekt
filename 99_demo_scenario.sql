-- SCENARIUSZ PREZENTACJI PROJEKTU "WARSZTAT"
-- Historia: Przyjeżdża nowy klient (Janusz) ze swoim Passatem.

-- KROK 1: Recepcja dodaje nowego klienta i jego auto
INSERT INTO klienci (imie, nazwisko, telefon) 
VALUES ('Janusz', 'Tracz', '600-100-999');

-- Sprawdzamy jakie ID dostał (np. 4)
SELECT * FROM klienci ORDER BY id_klienta DESC LIMIT 1;

INSERT INTO pojazdy (id_klienta, marka, model, rok, nr_rejestracyjny, vin)
VALUES (4, 'Volkswagen', 'Passat', 2010, 'W1 PSTAT', 'VIN_PASSAT_123');


-- KROK 2: Tworzymy zlecenie naprawy (Status: Przyjęte)
-- Mechanik nr 1 (Wiesław) zajmie się autem nr 5 (Passat)
INSERT INTO zlecenia (id_pojazdu, id_mechanika, status, opis, koszt_robocizny)
VALUES (5, 1, 'Przyjete', 'Dziwne stuki w silniku', 0);

-- KROK 3: Mechanik diagnozuje i pobiera części (Tu zadziała TRIGGER!)
-- Sprawdźmy stan oleju przed pobraniem (ID czesci 1)
SELECT nazwa, ilosc_na_stanie FROM czesci WHERE id_czesci = 1;

-- Dodajemy olej do zlecenia (ID zlecenia np. 8 - sprawdź jakie powstało)
INSERT INTO czesci_zlecenia (id_zlecenia, id_czesci, ilosc) 
VALUES (3, 1, 5); -- Pobieramy 5 litrów

-- Sprawdzamy stan po pobraniu (Powinno ubyć 5 sztuk)
SELECT nazwa, ilosc_na_stanie FROM czesci WHERE id_czesci = 1;


-- KROK 4: Raport dla kierownika
-- Kto jest najbardziej dochodowym mechanikiem?
SELECT * FROM widok_ranking_mechanikow;


-- KROK 5: Zakończenie zlecenia i płatność
-- Używamy procedury do zamknięcia zlecenia
CALL zakoncz_zlecenie(3);

-- Sprawdzamy czy status się zmienił i data ustawiła
SELECT * FROM zlecenia WHERE id_zlecenia = 3;