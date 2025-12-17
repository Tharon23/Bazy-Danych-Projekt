# 🚗 System Zarządzania Warsztatem Samochodowym

Projekt relacyjnej bazy danych wspierający obsługę warsztatu samochodowego. Projekt łączy zaawansowaną logikę w bazie danych PostgreSQL (Triggery, Procedury) z aplikacją webową (React + Node.js).

## 📋 O projekcie

Celem projektu jest usprawnienie pracy warsztatu poprzez cyfryzację kluczowych procesów. Baza danych pozwala na:
* Zarządzanie bazą klientów i historią ich pojazdów.
* Monitorowanie zleceń naprawy i statusów pracy mechaników.
* **Automatyczne zarządzanie stanem magazynowym** (Triggery).
* **Symulację ról użytkowników** (Kierownik, Recepcja, Mechanik) w aplikacji.
* Generowanie raportów finansowych i rankingów efektywności.

## 📊 Schemat Bazy Danych (ERD)
```mermaid
erDiagram
    KLIENCI ||--|{ POJAZDY : posiada
    POJAZDY ||--|{ ZLECENIA : ma
    POJAZDY ||--|{ PRZEGLADY : przechodzi
    MECHANICY ||--|{ ZLECENIA : realizuje

    ZLECENIA ||--|{ USLUGI_ZLECENIA : zawiera
    ZLECENIA ||--|{ CZESCI_ZLECENIA : zawiera
    USLUGI ||--|{ USLUGI_ZLECENIA : jest_w
    CZESCI ||--|{ CZESCI_ZLECENIA : jest_w

    ZLECENIA ||--|| PLATNOSCI : generuje
    PLATNOSCI ||--|| FAKTURY : dokumentuje

    %% Tabela KLIENCI
    KLIENCI {
        int id_klienta PK
        string imie
        string nazwisko
        string telefon
        string email
    }

    %% Tabela POJAZDY
    POJAZDY {
        int id_pojazdu PK
        int id_klienta FK
        string marka
        string model
        string vin
    }

    %% Tabela ZLECENIA
    ZLECENIA {
        int id_zlecenia PK
        int id_pojazdu FK
        int id_mechanika FK
        string status
        date data_przyjecia
    }

    %% Tabela MECHANICY
    MECHANICY {
        int id_mechanika PK
        string imie
        string nazwisko
        string specjalizacja
    }

    %% Tabela CZESCI (Magazyn)
    CZESCI {
        int id_czesci PK
        string nazwa
        numeric cena
        numeric ilosc_na_stanie
    }

    %% Tabela USLUGI (Cennik)
    USLUGI {
        int id_uslugi PK
        string nazwa
        numeric cena
    }

    %% Tabela PRZEGLADY (Przywrocona)
    PRZEGLADY {
        int id_przegladu PK
        int id_pojazdu FK
        date data_przegladu
        string wynik
    }

    %% Tabela PLATNOSCI
    PLATNOSCI {
        int id_platnosci PK
        int id_zlecenia FK
        numeric kwota
        string sposob
    }

    %% Tabela FAKTURY
    FAKTURY {
        int id_faktury PK
        int id_platnosci FK
        numeric kwota_brutto
    }

    %% TABELE LACZACE
    USLUGI_ZLECENIA {
        int id_zlecenia FK
        int id_uslugi FK
        int ilosc
    }

    CZESCI_ZLECENIA {
        int id_zlecenia FK
        int id_czesci FK
        int ilosc
    }

    %% NOWA TABELA (Logi) - stoi obok, bez relacji
    LOGI_ZMIAN_CEN {
        int id_logu PK
        string nazwa_uslugi
        numeric stara_cena
        numeric nowa_cena
        timestamp data_zmiany
    }
```

## 🛠 Technologie
* **Baza danych:** PostgreSQL 16/17
* **Backend:** Node.js + Express
* **Frontend:** React + Vite
* **Komunikacja:** Axios + pg (node-postgres)
* **Narzędzia:** Visual Studio Code, Git

## 🚀 Instalacja i Uruchomienie

Pełna instrukcja instalacji środowiska znajduje się w pliku: 👉 **[INSTALL.md](./INSTALL.md)**

## 💡 Kluczowe funkcjonalności (SQL)

### 1. Automatyzacja Magazynu (Trigger)
System posiada trigger `aktualizuj_stan_magazynu`, który automatycznie zdejmuje części ze stanu magazynowego w momencie przypisania ich do zlecenia. Zapobiega to sprzedaży części, których fizycznie nie ma.

### 2. Widoki Analityczne
* **`widok_aktywne_zlecenia`**: Łączy dane z 4 tabel, aby pokazać recepcji czytelny status naprawy.
* **`widok_ranking_mechanikow`**: Raport pokazujący, który pracownik generuje największy przychód dla firmy.

### 3. Procedury Składowane
Zaimplementowano procedury takie jak `zakoncz_zlecenie`, która automatycznie zamyka zlecenie i ustawia datę finalizacji.

---
*Projekt wykonany w ramach przedmiotu Bazy Danych. Autorzy: Tharon23, ultimus12*
