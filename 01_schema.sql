-- Struktura tabel z walidacją danych
CREATE TABLE klienci (
    id_klienta SERIAL PRIMARY KEY,
    imie VARCHAR(100) NOT NULL,
    nazwisko VARCHAR(100) NOT NULL,
    telefon VARCHAR(9) CHECK (telefon ~ '^[0-9]{9}$'), 
    email VARCHAR(100) UNIQUE CHECK (email LIKE '%_@__%.__%'),
    adres TEXT
);

CREATE TABLE pojazdy (
    id_pojazdu SERIAL PRIMARY KEY,
    id_klienta INTEGER, 
    marka VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    rok INTEGER CHECK (rok BETWEEN 1900 AND EXTRACT(YEAR FROM CURRENT_DATE) + 1),
    nr_rejestracyjny VARCHAR(10) UNIQUE CHECK (length(nr_rejestracyjny) >= 4),
    vin VARCHAR(17) UNIQUE CHECK (length(vin) = 17)
);

CREATE TABLE mechanicy (
    id_mechanika SERIAL PRIMARY KEY,
    imie VARCHAR(100) NOT NULL,
    nazwisko VARCHAR(100) NOT NULL,
    specjalizacja VARCHAR(100),
    telefon VARCHAR(9) CHECK (telefon ~ '^[0-9]{9}$'),
    stawka_godzinowa NUMERIC(10,2) CHECK (stawka_godzinowa > 0)
);

CREATE TABLE uslugi (
    id_uslugi SERIAL PRIMARY KEY,
    nazwa VARCHAR(200) NOT NULL,
    opis TEXT,
    cena NUMERIC(10,2) CHECK (cena >= 0)
);

CREATE TABLE czesci (
    id_czesci SERIAL PRIMARY KEY,
    nazwa VARCHAR(200) NOT NULL,
    cena NUMERIC(10,2) CHECK (cena >= 0),
    ilosc_na_stanie NUMERIC(10,2) CHECK (ilosc_na_stanie >= 0)
);

CREATE TABLE zlecenia (
    id_zlecenia SERIAL PRIMARY KEY,
    id_pojazdu INTEGER, 
    id_mechanika INTEGER, 
    data_przyjecia TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_zakonczenia TIMESTAMP,
    status VARCHAR(50) CHECK (status IN ('Przyjete', 'W trakcie', 'Oczekuje na czesci', 'Zakonczone', 'Anulowane')),
    opis TEXT,
    koszt_robocizny NUMERIC(10,2) DEFAULT 0 CHECK (koszt_robocizny >= 0),
    CONSTRAINT check_kolejnosc_dat CHECK (data_zakonczenia >= data_przyjecia)
);

CREATE TABLE uslugi_zlecenia (
    id_uslugi_zlecenia SERIAL PRIMARY KEY,
    id_zlecenia INTEGER, 
    id_uslugi INTEGER, 
    ilosc INTEGER DEFAULT 1 CHECK (ilosc > 0),
    rabat NUMERIC(5,2) DEFAULT 0 CHECK (rabat >= 0 AND rabat <= 100)
);

CREATE TABLE czesci_zlecenia (
    id_czesci_zlecenia SERIAL PRIMARY KEY,
    id_zlecenia INTEGER, 
    id_czesci INTEGER, 
    ilosc INTEGER CHECK (ilosc > 0)
);

CREATE TABLE platnosci (
    id_platnosci SERIAL PRIMARY KEY,
    id_zlecenia INTEGER, 
    data_platnosci TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sposob_platnosci VARCHAR(50) CHECK (sposob_platnosci IN ('Gotowka', 'Karta', 'Przelew', 'Blik')),
    kwota NUMERIC(10,2) CHECK (kwota > 0)
);

CREATE TABLE faktury (
    id_faktury SERIAL PRIMARY KEY,
    id_platnosci INTEGER, 
    data_wystawienia DATE DEFAULT CURRENT_DATE,
    kwota_brutto NUMERIC(10,2) CHECK (kwota_brutto > 0),
    status_platnosci VARCHAR(50) DEFAULT 'Oplacona'
);

CREATE TABLE logi_zmian_cen (
    id_logu SERIAL PRIMARY KEY,
    nazwa_uslugi VARCHAR(200),
    stara_cena NUMERIC(10,2),
    nowa_cena NUMERIC(10,2),
    data_zmiany TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    uzytkownik VARCHAR(100)
);

CREATE TABLE przeglady (
    id_przegladu SERIAL PRIMARY KEY,
    id_pojazdu INTEGER NOT NULL, 
    data_przegladu DATE DEFAULT CURRENT_DATE,
    wynik VARCHAR(50) CHECK (wynik IN ('Pozytywny', 'Negatywny')), 
    opis_usterek TEXT
);