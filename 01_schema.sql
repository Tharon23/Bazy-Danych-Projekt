-- Tabela: Klienci
CREATE TABLE klienci (
    id_klienta SERIAL PRIMARY KEY,
    imie VARCHAR(100) NOT NULL,
    nazwisko VARCHAR(100) NOT NULL,
    telefon VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    adres TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_poprawny_telefon CHECK (telefon ~ '^[0-9]{9}$'),
    CONSTRAINT check_poprawny_email CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Tabela: Pojazdy
CREATE TABLE pojazdy (
    id_pojazdu SERIAL PRIMARY KEY,
    id_klienta INTEGER, -- FK dodamy w pliku 02
    marka VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    rok INTEGER CHECK (rok >= 1900 AND rok <= EXTRACT(YEAR FROM CURRENT_DATE) + 1),
    nr_rejestracyjny VARCHAR(20) UNIQUE,
    vin VARCHAR(20) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_poprawny_vin CHECK (vin ~ '^[A-HJ-NPR-Z0-9]{17}$'),
    CONSTRAINT check_poprawna_rejestracja CHECK (nr_rejestracyjny ~ '^[A-Z0-9 ]+$')
);

-- Tabela: Mechanicy
CREATE TABLE mechanicy (
    id_mechanika SERIAL PRIMARY KEY,
    imie VARCHAR(100) NOT NULL,
    nazwisko VARCHAR(100) NOT NULL,
    specjalizacja VARCHAR(100),
    telefon VARCHAR(20),
    stawka_godzinowa NUMERIC(10,2) CHECK (stawka_godzinowa > 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_poprawny_telefon_mechanika CHECK (telefon ~ '^[0-9]{9}$')
);

-- Tabela: Uslugi
CREATE TABLE uslugi (
    id_uslugi SERIAL PRIMARY KEY,
    nazwa VARCHAR(200) NOT NULL,
    opis TEXT,
    cena NUMERIC(10,2) CHECK (cena >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela: Czesci
CREATE TABLE czesci (
    id_czesci SERIAL PRIMARY KEY,
    nazwa VARCHAR(200) NOT NULL,
    cena NUMERIC(10,2) CHECK (cena >= 0),
    ilosc_na_stanie NUMERIC(10,2) CHECK (ilosc_na_stanie >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
    koszt_robocizny NUMERIC(10,2) CHECK (koszt_robocizny >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
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
    kwota NUMERIC(10,2) CHECK (kwota > 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela: Faktury
CREATE TABLE faktury (
    id_faktury SERIAL PRIMARY KEY,
    id_platnosci INTEGER, -- FK
    data_wystawienia DATE DEFAULT CURRENT_DATE,
    kwota_brutto NUMERIC(10,2) CHECK (kwota_brutto >= 0),
    status_platnosci VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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