# 🚗 System Zarządzania Warsztatem Samochodowym

Projekt relacyjnej bazy danych wspierający obsługę warsztatu samochodowego. Projekt skupia się na logice biznesowej zaimplementowanej bezpośrednio po stronie serwera bazy danych

## 📋 O projekcie

Celem projektu jest usprawnienie pracy warsztatu poprzez cyfryzację kluczowych procesów. Baza danych realizuje:
* **Automatyzację magazynu:** Trigger `aktualizuj_stan_magazynu` pilnuje stanów części.
* **Logikę transakcyjną:** Procedury składowane zapewniają spójność danych (np. przy dodawaniu klienta z autem).
* **System bezpieczeństwa:** Role bazodanowe (`Kierownik`, `Recepcja`, `Mechanik`) z odpowiednimi uprawnieniami.
* **Audyt i Archiwizację:** Śledzenie zmian cen oraz archiwizacja usuwanych zleceń (Soft Delete).
* **Raportowanie:** Widoki analityczne (Ranking mechaników, Raporty finansowe).

## 📊 Schemat Bazy Danych (ERD)
```mermaid
erDiagram
    klienci {
        int id_klienta PK "Serial ID"
        varchar imie
        varchar nazwisko
        varchar telefon "Walidacja: 9 cyfr"
        varchar email "Unique, Walidacja formatu"
        text adres
    }

    pojazdy {
        int id_pojazdu PK "Serial ID"
        int id_klienta FK "Właściciel"
        varchar marka
        varchar model
        int rok "Walidacja: 1900-obecny+1"
        varchar nr_rejestracyjny "Unique, min 4 znaki"
        varchar vin "Unique, dokładnie 17 znaków"
    }

    mechanicy {
        int id_mechanika PK "Serial ID"
        varchar imie
        varchar nazwisko
        varchar specjalizacja
        varchar telefon "Walidacja: 9 cyfr"
        numeric stawka_godzinowa "> 0"
    }

    zlecenia {
        int id_zlecenia PK "Serial ID"
        int id_pojazdu FK
        int id_mechanika FK "Mechanik prowadzący"
        timestamp data_przyjecia
        timestamp data_zakonczenia ">= data_przyjecia"
        varchar status "Enum: Przyjete, W trakcie..."
        text opis
        numeric koszt_robocizny ">= 0"
    }

    uslugi {
        int id_uslugi PK "Serial ID"
        varchar nazwa
        text opis
        numeric cena ">= 0"
    }

    czesci {
        int id_czesci PK "Serial ID"
        varchar nazwa
        numeric cena ">= 0"
        numeric ilosc_na_stanie ">= 0"
    }

    uslugi_zlecenia {
        int id_uslugi_zlecenia PK
        int id_zlecenia FK
        int id_uslugi FK
        int ilosc "> 0, Default: 1"
        numeric rabat "0-100%"
    }

    czesci_zlecenia {
        int id_czesci_zlecenia PK
        int id_zlecenia FK
        int id_czesci FK
        int ilosc "> 0"
    }

    platnosci {
        int id_platnosci PK "Serial ID"
        int id_zlecenia FK
        timestamp data_platnosci
        varchar sposob_platnosci "Enum: Gotowka, Karta..."
        numeric kwota "> 0"
    }

    faktury {
        int id_faktury PK "Serial ID"
        int id_platnosci FK
        date data_wystawienia
        numeric kwota_brutto "> 0"
        varchar status_platnosci
    }

    przeglady {
        int id_przegladu PK "Serial ID"
        int id_pojazdu FK
        date data_przegladu
        varchar wynik "Enum: Pozytywny, Negatywny"
        text opis_usterek
    }

    logi_zmian_cen {
        int id_logu PK "Serial ID - Tabela Audytowa"
        varchar nazwa_uslugi
        numeric stara_cena
        numeric nowa_cena
        timestamp data_zmiany
        varchar uzytkownik
    }

    klienci ||--|{ pojazdy : "posiada (1:N)"
    pojazdy ||--|{ zlecenia : "ma historię (1:N)"
    pojazdy ||--|{ przeglady : "przechodzi (1:N)"
    mechanicy ||--|{ zlecenia : "realizuje (1:N)"

    zlecenia ||--|{ uslugi_zlecenia : "zawiera (M:N)"
    uslugi ||--|{ uslugi_zlecenia : "jest w (M:N)"

    zlecenia ||--|{ czesci_zlecenia : "zawiera (M:N)"
    czesci ||--|{ czesci_zlecenia : "jest w (M:N)"

    zlecenia ||--|| platnosci : "jest opłacane (1:1)"
    platnosci ||--|| faktury : "jest dokumentowane (1:1)"
```

## 🛠 Technologie
* **Baza danych:** PostgreSQL 16/17
* **Język:** SQL (PL/pgSQL)
* **Narzędzia:** Visual Studio Code (z wtyczką Database Client), Git

## 🚀 Instalacja i Uruchomienie

Pełna instrukcja instalacji środowiska znajduje się w pliku: 👉 **[INSTALL.md](./INSTALL.md)**

Skrypty SQL zostały podzielone na moduły. Należy je uruchomić w następującej kolejności:

1. `01_schema.sql` - Struktura tabel i walidacja danych (CHECK, REGEX).
2. `02_constraints.sql` - Relacje (klucze obce)
3. `03_views.sql` - Widoki
4. `04_logic.sql` - Triggery i Procedury Składowane
5. `05_security.sql` - Role i uprawnienia
6. `06_seed_data.sql` - Dane testowe
7. `07_indexes.sql` - Optymalizacja wydajności
8. `08_archivization.sql` - Mechanizmy archiwizacji

## 💡 Kluczowe funkcjonalności:

### 1. Automatyzacja Magazynu
System automatycznie zdejmuje części ze stanu w momencie przypisania ich do zlecenia. Próba pobrania większej ilości niż dostępna kończy się błędem `RAISE EXCEPTION`.

### 2. Bezpieczeństwo Danych
* **Walidacja**: Numery VIN (17 znaków), telefony (format), daty i ceny są sprawdzane na poziomie tabeli.
* **Role**:
- `rola_kierownik`: Pełny dostęp
- `rola_mechanik`: Widzi zlecenia, nie widzi danych finansowych ani klientów
- `rola_recepcja`: Zarządza klientami i fakturami

### 3. Audyt (logi)
Każda zmiana w cenniku usług jest odnotowywana w tabeli `logi_zmian_cen` wraz z informacją, kto i kiedy dokonał zmiany.

---
*Projekt wykonany w ramach przedmiotu Bazy Danych. Autorzy: Kamil Szkarłat, Maciej Popławski*
