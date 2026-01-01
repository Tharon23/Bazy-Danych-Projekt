-- Klienci
INSERT INTO klienci (imie, nazwisko, telefon, email, adres) VALUES
('Adam', 'Nowak', '500100101', 'adam.n@gmail.com', 'ul. Prosta 10, Warszawa'),
('Beata', 'Kowalska', '500100102', 'b.kowalska@yahoo.com', 'ul. Krzywa 5, Krakow'),
('Cezary', 'Pazura', '500100103', 'czarek@film.pl', 'ul. Filmowa 3, Lodz');

-- Pojazdy
INSERT INTO pojazdy (id_klienta, marka, model, rok, nr_rejestracyjny, vin) VALUES
(1, 'Toyota', 'Corolla', 2015, 'WA 11111', 'VIN11111111110000'),
(1, 'Fiat', 'Panda', 2010, 'WA 22222', 'VIN22222222220000'),
(2, 'Honda', 'Civic', 2018, 'KR 33333', 'VIN33333333330000'),
(3, 'BMW', 'X5', 2020, 'EL 44444', 'VIN44444444440000');

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
('Klocki hamulcowe Brembo', 180.00, 20);

-- Uslugi
INSERT INTO uslugi (nazwa, opis, cena) VALUES
('Wymiana oleju', 'Pelny serwis olejowy', 100.00),
('Wymiana opon (kpl)', 'Demontaz, wywazenie, montaz', 120.00),
('Diagnostyka komputerowa', 'Podlaczenie OBD', 150.00);

-- Zlecenia (Przykładowe)
INSERT INTO zlecenia (id_pojazdu, id_mechanika, status, opis, koszt_robocizny) VALUES
(1, 1, 'Zakonczone', 'Standardowy serwis', 220.00),
(3, 2, 'W trakcie', 'Slaba wydajnosc klimatyzacji', 200.00);

-- Części użyte w zleceniach (Tu zadziała trigger i zdejmie ze stanu!)
INSERT INTO czesci_zlecenia (id_zlecenia, id_czesci, ilosc) VALUES
(1, 1, 1), -- Olej do zlecenia 1
(1, 2, 1); -- Filtr do zlecenia 1