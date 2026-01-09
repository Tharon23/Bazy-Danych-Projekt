# ⚙️ Instrukcja Uruchomienia Bazy Danych

Dokument opisuje proces instalacji i konfiguracji bazy danych **"Warsztat"**.

---

## 📋 Wymagania

1. **PostgreSQL** (serwer bazy danych)
2. **Visual Studio Code** (zalecane)
4. **Rozszerzenie do VS Code:** Dtabase Client (do obsługi SQL)

---

## 🚀 Uruchomienie Projektu

### Krok 1: Utworzenie bazy

1. Połącz się ze swoim serwerem PostgreSQL.
2. Otwórz nowe zapytanie i wykonaj:

```sql
CREATE DATABASE warsztat;
```

3. **Ważne**: Przełącz się na nowo utworzoną bazę `warsztat`.

---

### Krok 2: Wgranie struktury (Kolejność ma znaczenie!)

Uruchom pliki SQL jeden po drugim:

1. `01_schema.sql` - Tworzy tabele i nakłada ograniczenia walidacyjne
2. `02_constraints.sql` - Tworzy powiązania między tabelami - klucze obce
3. `03_views.sql` - Tworzy widoki analityczne
4. `04_logic.sql` - Wgrywa funkcje, procedury i triggery
5. `05_security.sql` - Tworzy role i nadaje uprawnienia
6. `06_seed_data.sql` - Wypełnia bazę danymi testowymi
7. `07_indexes.sql` - Dodaje indeksy dla wydajności
8. `08_archivization.sql` - Dodaje system archiwizacji

---

## 🎉 Gotowe!
