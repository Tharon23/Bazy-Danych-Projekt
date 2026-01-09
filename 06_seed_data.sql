-- Inicjalizacja danych testowych (zgodnych z walidacją)

-- Klienci
INSERT INTO klienci (imie, nazwisko, telefon, email, adres) VALUES
('Adam', 'Nowak', '500100101', 'adam.n@gmail.com', 'ul. Prosta 10, Warszawa'),
('Beata', 'Kowalska', '500100102', 'b.kowalska@yahoo.com', 'ul. Krzywa 5, Krakow'),
('Cezary', 'Pazura', '500100103', 'czarek@film.pl', 'ul. Filmowa 3, Lodz'),
('Janusz', 'Tracz', '601602603', 'janusz@tracz.pl', 'Tulczyn, Plebania 1'),
('Dariusz', 'Wasiak', '500500500', 'daro@kierowca.com', 'Warszawa, Mokotow'),
('Anna', 'Nowakowska', '700800900', 'anna.n@poczta.fm', 'Krakow, Rynek 5'),
('Robert', 'Kubica', '900900900', 'robert@f1.com', 'Monaco, Monte Carlo');

-- Pojazdy
INSERT INTO pojazdy (id_klienta, marka, model, rok, nr_rejestracyjny, vin) VALUES
((SELECT id_klienta FROM klienci WHERE email='adam.n@gmail.com'), 'Toyota', 'Corolla', 2015, 'WA11111', 'VINTOYOTA20150001'),
((SELECT id_klienta FROM klienci WHERE email='adam.n@gmail.com'), 'Fiat', 'Panda', 2010, 'WA22222', 'VINFIATPANDA00002'),
((SELECT id_klienta FROM klienci WHERE email='b.kowalska@yahoo.com'), 'Honda', 'Civic', 2018, 'KR33333', 'VINHONDACIVIC0003'),
((SELECT id_klienta FROM klienci WHERE email='janusz@tracz.pl'), 'Mercedes', 'S-Class', 2022, 'W0TRACZ', 'VINMERCEDESCLASS1'),
((SELECT id_klienta FROM klienci WHERE email='daro@kierowca.com'), 'Volkswagen', 'Passat B5', 2003, 'WPI12345', 'VINVWPASSATLEGEND'),
((SELECT id_klienta FROM klienci WHERE email='anna.n@poczta.fm'), 'Mini', 'Cooper', 2019, 'KRANNA1', 'VINMINICOOPER0006'),
((SELECT id_klienta FROM klienci WHERE email='robert@f1.com'), 'Alfa Romeo', 'Giulia', 2023, 'F1KUBICA', 'VINALFAGIULIA0007');

-- Mechanicy
INSERT INTO mechanicy (imie, nazwisko, specjalizacja, telefon, stawka_godzinowa) VALUES
('Wieslaw', 'Szybki', 'Silniki Diesla', '600100100', 180.00),
('Marian', 'Dokladny', 'Elektryka', '600100101', 150.00),
('Zbigniew', 'Spawacz', 'Blacharstwo', '600100102', 130.00);

-- Czesci
INSERT INTO czesci (nazwa, cena, ilosc_na_stanie) VALUES
('Olej 5W30 Castrol 4L', 150.00, 50),
('Filtr oleju Filtron', 30.00, 100),
('Opony Zimowe Debica R16 (szt)', 250.00, 40),
('Klocki hamulcowe Brembo', 180.00, 20),
('Zarowka H7 Premium', 45.00, 5),
('Plyn hamulcowy DOT4', 35.00, 8),
('Wycieraczki Bosch Aero', 120.00, 4),
('Swieca zaplonowa NGK', 25.00, 200);

-- Uslugi
INSERT INTO uslugi (nazwa, opis, cena) VALUES
('Wymiana oleju', 'Pelny serwis olejowy', 100.00),
('Wymiana opon (kpl)', 'Demontaz, wywazenie, montaz', 120.00),
('Diagnostyka komputerowa', 'Podlaczenie OBD', 150.00);

-- Zlecenia
INSERT INTO zlecenia (id_pojazdu, id_mechanika, status, opis, koszt_robocizny, data_przyjecia, data_zakonczenia) 
VALUES 
-- Zakończone
(
    (SELECT id_pojazdu FROM pojazdy WHERE nr_rejestracyjny='W0TRACZ'),
    1, 'Zakonczone', 'Kompleksowy serwis zawieszenia', 1500.00, CURRENT_TIMESTAMP - INTERVAL '10 days', CURRENT_TIMESTAMP - INTERVAL '8 days'
),
-- W trakcie
(
    (SELECT id_pojazdu FROM pojazdy WHERE nr_rejestracyjny='WPI12345'),
    2, 'W trakcie', 'Wymiana rozrzadu', 600.00, CURRENT_TIMESTAMP - INTERVAL '1 day', NULL
),
-- Oczekuje
(
    (SELECT id_pojazdu FROM pojazdy WHERE nr_rejestracyjny='KRANNA1'),
    3, 'Oczekuje na czesci', 'Wymiana sprzegla', 800.00, CURRENT_TIMESTAMP - INTERVAL '2 days', NULL
);

-- Przypisanie części do zleceń
INSERT INTO czesci_zlecenia (id_zlecenia, id_czesci, ilosc) VALUES
(
    (SELECT id_zlecenia FROM zlecenia WHERE opis LIKE 'Wymiana rozrzadu%'),
    (SELECT id_czesci FROM czesci WHERE nazwa LIKE 'Swieca%'),
    4
);