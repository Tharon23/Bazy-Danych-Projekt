-- NOWI KLIENCI
INSERT INTO klienci (imie, nazwisko, telefon, email, adres) VALUES
('Janusz', 'Tracz', '601602603', 'janusz@tracz.pl', 'Tulczyn, Plebania 1'),
('Dariusz', 'Wasiak', '500500500', 'daro@kierowca.com', 'Warszawa, Mokotow'),
('Anna', 'Nowakowska', '700800900', 'anna.n@poczta.fm', 'Krakow, Rynek 5'),
('Tomasz', 'Hajto', '600000000', 'tomek@truskawka.pl', 'Lódź, Sportowa 10'),
('Robert', 'Kubica', '900900900', 'robert@f1.com', 'Monaco, Monte Carlo');

-- NOWE POJAZDY
-- Janusz (ID: 4)
INSERT INTO pojazdy (id_klienta, marka, model, rok, nr_rejestracyjny, vin) VALUES
((SELECT id_klienta FROM klienci WHERE email='janusz@tracz.pl'), 'Mercedes', 'S-Class', 2022, 'W0 TRACZ', 'VIN_MERC_001');

-- Dariusz (ID: 5)
INSERT INTO pojazdy (id_klienta, marka, model, rok, nr_rejestracyjny, vin) VALUES
((SELECT id_klienta FROM klienci WHERE email='daro@kierowca.com'), 'Volkswagen', 'Passat B5', 2003, 'WPI 12345', 'VIN_PASSAT_LEGEND');

-- Anna (ID: 6)
INSERT INTO pojazdy (id_klienta, marka, model, rok, nr_rejestracyjny, vin) VALUES
((SELECT id_klienta FROM klienci WHERE email='anna.n@poczta.fm'), 'Mini', 'Cooper', 2019, 'KR ANNA1', 'VIN_MINI_002');

-- Tomasz (ID: 7)
INSERT INTO pojazdy (id_klienta, marka, model, rok, nr_rejestracyjny, vin) VALUES
((SELECT id_klienta FROM klienci WHERE email='tomek@truskawka.pl'), 'Fiat', '126p', 1990, 'EL MALUCH', 'VIN_MALUCH_003');

-- Robert (ID: 8)
INSERT INTO pojazdy (id_klienta, marka, model, rok, nr_rejestracyjny, vin) VALUES
((SELECT id_klienta FROM klienci WHERE email='robert@f1.com'), 'Alfa Romeo', 'Giulia', 2023, 'F1 KUBICA', 'VIN_ALFA_004');


-- CZEŚCI (W TYM NISKI STAN!)
INSERT INTO czesci (nazwa, cena, ilosc_na_stanie) VALUES
('Zarowka H7 Premium', 45.00, 5), -- NISKI STAN (<10)
('Plyn hamulcowy DOT4', 35.00, 8), -- NISKI STAN (<10)
('Wycieraczki Bosch Aero', 120.00, 4), -- NISKI STAN (<10)
('Swieca zaplonowa NGK', 25.00, 200),
('Filtr powietrza Mann', 60.00, 50);


-- ZLECENIA (HISTORIA I AKTYWNE)

-- 1. Janusz Tracz - Mercedes - Zakończone (Duży przychód dla warsztatu)
INSERT INTO zlecenia (id_pojazdu, id_mechanika, status, opis, koszt_robocizny, data_przyjecia, data_zakonczenia) 
VALUES (
    (SELECT id_pojazdu FROM pojazdy WHERE nr_rejestracyjny='W0 TRACZ'),
    1, -- Wiesław Szybki
    'Zakonczone',
    'Kompleksowy serwis zawieszenia',
    1500.00,
    CURRENT_TIMESTAMP - INTERVAL '10 days',
    CURRENT_TIMESTAMP - INTERVAL '8 days'
);

-- 2. Daro - Passat - W trakcie (Mechanik: Marian Dokładny)
INSERT INTO zlecenia (id_pojazdu, id_mechanika, status, opis, koszt_robocizny, data_przyjecia) 
VALUES (
    (SELECT id_pojazdu FROM pojazdy WHERE nr_rejestracyjny='WPI 12345'),
    2, -- Marian Dokładny
    'W trakcie',
    'Wymiana rozrzadu (legenda glosi ze to pierwszy raz)',
    600.00,
    CURRENT_TIMESTAMP - INTERVAL '1 day'
);

-- 3. Anna - Mini - Oczekuje na części (Mechanik: Zbigniew Spawacz)
INSERT INTO zlecenia (id_pojazdu, id_mechanika, status, opis, koszt_robocizny, data_przyjecia) 
VALUES (
    (SELECT id_pojazdu FROM pojazdy WHERE nr_rejestracyjny='KR ANNA1'),
    3, -- Zbigniew Spawacz
    'Oczekuje na czesci',
    'Wymiana sprzegla',
    800.00,
    CURRENT_TIMESTAMP - INTERVAL '2 days'
);

-- 4. Robert - Alfa Romeo - Przyjęte (Jeszcze nie przydzielone do końca, ale damy Wiesławowi bo skończył poprzednie)
-- Uwaga: Wiesław ma status 'Zakonczone' w poprzednim, więc jest wolny? Nie, sprawdźmy funkcję. 
-- Funkcja sprawdza 'W trakcie', 'Przyjete', 'Oczekuje'.
-- Wiesław jest wolny. Dajemy mu nowe.
INSERT INTO zlecenia (id_pojazdu, id_mechanika, status, opis, koszt_robocizny, data_przyjecia) 
VALUES (
    (SELECT id_pojazdu FROM pojazdy WHERE nr_rejestracyjny='F1 KUBICA'),
    1, -- Wiesław Szybki
    'Przyjete',
    'Przeglad przed sezonem',
    0.00,
    CURRENT_TIMESTAMP
);

-- 5. Tomek - Maluch - Zakonczone (Zbigniew Spawacz)
INSERT INTO zlecenia (id_pojazdu, id_mechanika, status, opis, koszt_robocizny, data_przyjecia, data_zakonczenia) 
VALUES (
    (SELECT id_pojazdu FROM pojazdy WHERE nr_rejestracyjny='EL MALUCH'),
    3, -- Zbigniew Spawacz
    'Zakonczone',
    'Spawanie podlogi',
    400.00,
    CURRENT_TIMESTAMP - INTERVAL '15 days',
    CURRENT_TIMESTAMP - INTERVAL '14 days'
);

-- Użycie części w nowych zleceniach
-- Daro (Passat) zużywa 4 świece (jest ich dużo, id=6 w tabeli ale dynamicznie pobierzemy)
INSERT INTO czesci_zlecenia (id_zlecenia, id_czesci, ilosc) VALUES
(
    (SELECT id_zlecenia FROM zlecenia WHERE opis LIKE 'Wymiana rozrzadu%'),
    (SELECT id_czesci FROM czesci WHERE nazwa LIKE 'Swieca%'),
    4
);
