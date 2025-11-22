-- Tabela: Klienci
CREATE TABLE klienci (
    id_klienta SERIAL PRIMARY KEY,
    imie VARCHAR(100) NOT NULL,
    nazwisko VARCHAR(100) NOT NULL,
    telefon VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    adres TEXT,
    CONSTRAINT check_dlugosc_telefonu CHECK (length(telefon) >= 9)
);

-- Tabela: Pojazdy
CREATE TABLE pojazdy (
    id_pojazdu SERIAL PRIMARY KEY,
    id_klienta INTEGER, -- FK dodamy w pliku 02
    marka VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    rok INTEGER CHECK (rok >= 1900 AND rok <= EXTRACT(YEAR FROM CURRENT_DATE) + 1),
    nr_rejestracyjny VARCHAR(20) UNIQUE,
    vin VARCHAR(20) UNIQUE
);

-- Tabela: Mechanicy
CREATE TABLE mechanicy (
    id_mechanika SERIAL PRIMARY KEY,
    imie VARCHAR(100) NOT NULL,
    nazwisko VARCHAR(100) NOT NULL,
    specjalizacja VARCHAR(100),
    telefon VARCHAR(20),
    stawka_godzinowa NUMERIC(10,2) CHECK (stawka_godzinowa > 0)
);

-- Tabela: Uslugi
CREATE TABLE uslugi (
    id_uslugi SERIAL PRIMARY KEY,
    nazwa VARCHAR(200) NOT NULL,
    opis TEXT,
    cena NUMERIC(10,2) CHECK (cena >= 0)
);

-- Tabela: Czesci
CREATE TABLE czesci (
    id_czesci SERIAL PRIMARY KEY,
    nazwa VARCHAR(200) NOT NULL,
    cena NUMERIC(10,2) CHECK (cena >= 0),
    ilosc_na_stanie NUMERIC(10,2) CHECK (ilosc_na_stanie >= 0)
);

-- Tabela: Zlecenia
CREATE TABLE zlecenia (
    id_zlecenia SERIAL PRIMARY KEY,
    id_pojazdu INTEGER, -- FK
    id_mechanika INTEGER, -- FK
    data_przyjecia TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_zakonczenia TIMESTAMP,
    status VARCHAR(50) CHECK (status IN ('Przyjete', 'W trakcie', 'Oczekuje na czesci', 'Zakonczone', 'Anulowane')),
    opis TEXT,
    koszt_robocizny NUMERIC(10,2),
    CONSTRAINT check_kolejnosc_dat CHECK (data_zakonczenia >= data_przyjecia)
);

-- Tabele łączące (Relacje wiele-do-wielu)
CREATE TABLE uslugi_zlecenia (
    id_uslugi_zlecenia SERIAL PRIMARY KEY,
    id_zlecenia INTEGER, -- FK
    id_uslugi INTEGER, -- FK
    ilosc INTEGER DEFAULT 1 CHECK (ilosc > 0),
    rabat NUMERIC(5,2) DEFAULT 0 CHECK (rabat >= 0 AND rabat <= 100)
);

CREATE TABLE czesci_zlecenia (
    id_czesci_zlecenia SERIAL PRIMARY KEY,
    id_zlecenia INTEGER, -- FK
    id_czesci INTEGER, -- FK
    ilosc INTEGER CHECK (ilosc > 0)
);

-- Tabela: Platnosci
CREATE TABLE platnosci (
    id_platnosci SERIAL PRIMARY KEY,
    id_zlecenia INTEGER, -- FK
    data_platnosci TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sposob_platnosci VARCHAR(50),
    kwota NUMERIC(10,2)
);

-- Tabela: Faktury
CREATE TABLE faktury (
    id_faktury SERIAL PRIMARY KEY,
    id_platnosci INTEGER, -- FK
    data_wystawienia DATE DEFAULT CURRENT_DATE,
    kwota_brutto NUMERIC(10,2),
    status_platnosci VARCHAR(50)
);

-- Tabela: Logi (do triggerów)
CREATE TABLE logi_zmian_cen (
    id_logu SERIAL PRIMARY KEY,
    nazwa_uslugi VARCHAR(200),
    stara_cena NUMERIC(10,2),
    nowa_cena NUMERIC(10,2),
    data_zmiany TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    uzytkownik VARCHAR(100)
);

-- Tabela: Przeglady (Przywrócona z dokumentacji)
CREATE TABLE przeglady (
    id_przegladu SERIAL PRIMARY KEY,
    id_pojazdu INTEGER NOT NULL, -- FK
    data_przegladu DATE DEFAULT CURRENT_DATE,
    wynik VARCHAR(50), -- np. Pozytywny/Negatywny
    opis_usterek TEXT
);