# 🚗 System Zarządzania Warsztatem Samochodowym

Projekt relacyjnej bazy danych stworzony w PostgreSQL, wspierający obsługę warsztatu samochodowego. System obsługuje procesy od przyjęcia klienta, przez naprawę, zarządzanie magazynem części, aż po fakturowanie.

## 📋 O projekcie

Celem projektu jest usprawnienie pracy warsztatu poprzez cyfryzację kluczowych procesów. Baza danych pozwala na:
* Zarządzanie bazą klientów i historią ich pojazdów.
* Monitorowanie zleceń naprawy i statusów pracy mechaników.
* **Automatyczne zarządzanie stanem magazynowym** (Triggery).
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
* **Język:** SQL (PL/pgSQL)
* **Narzędzia:** Visual Studio Code, Git

## 🚀 Jak uruchomić projekt?

Kod SQL został podzielony na moduły dla łatwiejszego wdrożenia. Uruchom pliki w następującej kolejności:

1.  `01_schema.sql` - Tworzy strukturę tabel (Klienci, Pojazdy, Zlecenia, itd.).
2.  `02_constraints.sql` - Dodaje klucze obce i relacje między tabelami.
3.  `03_views.sql` - Tworzy widoki analityczne (np. ranking mechaników).
4.  `04_functions_triggers.sql` - Wgrywa logikę biznesową (automatyzacja magazynu).
5.  `05_roles.sql` - Konfiguruje uprawnienia użytkowników.
6.  `06_seed_data.sql` - Wypełnia bazę przykładowymi danymi testowymi.

## 💡 Kluczowe funkcjonalności (SQL)

### 1. Automatyzacja Magazynu (Trigger)
System posiada trigger `aktualizuj_stan_magazynu`, który automatycznie zdejmuje części ze stanu magazynowego w momencie przypisania ich do zlecenia. Zapobiega to sprzedaży części, których fizycznie nie ma.

### 2. Widoki Analityczne
* **`widok_aktywne_zlecenia`**: Łączy dane z 4 tabel, aby pokazać recepcji czytelny status naprawy.
* **`widok_ranking_mechanikow`**: Raport pokazujący, który pracownik generuje największy przychód dla firmy.

### 3. Procedury Składowane
Zaimplementowano procedury takie jak `zakoncz_zlecenie`, która automatycznie zamyka zlecenie i ustawia datę finalizacji.

---
*Projekt wykonany w ramach przedmiotu Bazy Danych.*
