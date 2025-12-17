# ⚙️ Instrukcja Instalacji i Uruchomienia Systemu

Ten dokument opisuje krok po kroku, jak uruchomić pełny system **„Warsztat”** (Baza Danych + Aplikacja Webowa) na czystym systemie Windows.

---

## 📋 Wymagania wstępne

Zanim zaczniesz, upewnij się, że masz zainstalowane:

1. **PostgreSQL** (serwer bazy danych)
   - Pobierz: https://www.postgresql.org/download/windows/
   - 🛑 **WAŻNE:** Zapamiętaj hasło do użytkownika `postgres` ustawione przy instalacji
2. **Node.js** (wersja LTS)
   - Pobierz: https://nodejs.org/en/download/
3. **Visual Studio Code**
   - Pobierz: https://code.visualstudio.com/
4. **Git**
   - Pobierz: https://git-scm.com/download/win

---

## 🚀 Część 1: Baza Danych (SQL)

### Krok 1: Pobranie projektu

1. Otwórz terminal w folderze docelowym.
2. Wpisz komendę:

```bash
git clone https://github.com/Tharon23/Baza-Danych-Projekt-Warsztat-Samochodowy.git
```

3. Otwórz pobrany folder w Visual Studio Code.

---

### Krok 2: Utworzenie bazy danych

1. W VS Code połącz się z lokalnym serwerem PostgreSQL (np. przy użyciu wtyczki **Database Client**).
2. Otwórz **New Query** i wykonaj:

```sql
CREATE DATABASE warsztat;
```

---

### Krok 3: Wgranie struktury bazy

Pliki SQL muszą być uruchamiane w **ściśle określonej kolejności**.

⚠️ **UWAGA:** Przed uruchomieniem każdego pliku upewnij się, że na dolnym pasku VS Code wybrana jest baza **`warsztat`**.

Uruchom pliki jeden po drugim (**PPM → Run Query**):

1. `01_schema.sql`
2. `02_constraints.sql`
3. `03_views.sql`
4. `04_functions_triggers.sql`
5. `05_roles.sql`
6. `06_seed_data.sql`
7. `07_indexes.sql`
8. `08_advanced_logic.sql`
9. `09_security.sql`

---

## 💻 Część 2: Aplikacja (Backend & Frontend)

System składa się z dwóch części: **Backend (serwer)** oraz **Frontend (strona)**. Obie muszą działać jednocześnie.

---

### Krok 1: Konfiguracja połączenia z bazą (.env)

1. Wejdź do folderu:

```text
app/backend
```

2. Utwórz plik **`.env`**.
3. Wklej poniższą treść, podmieniając `twoje_tajne_haslo` na hasło do PostgreSQL:

```env
DB_USER=postgres
DB_PASSWORD=twoje_tajne_haslo
DB_HOST=localhost
DB_PORT=5432
DB_NAME=warsztat
PORT=3000
```

_(Plik `.env` jest ignorowany przez Gita i nie trafi do repozytorium.)_

---

### Krok 2: Instalacja i uruchomienie

W Visual Studio Code otwórz **dwa osobne terminale** (kliknij `+` w panelu terminala).

---

#### TERMINAL 1 — Backend (Serwer)

```bash
cd app/backend
npm install
npm start
```

✅ **Oczekiwany komunikat:**

```text
Connected to PostgreSQL database: warsztat
```

---

#### TERMINAL 2 — Frontend (Strona)

```bash
cd app/frontend
npm install
npm run dev
```

✅ **Oczekiwany komunikat:**

```text
Local: http://localhost:5173/
```

---

## 🎉 Gotowe!

Kliknij z wciśniętym **Ctrl** w link:

```
http://localhost:5173/
```

Powinieneś zobaczyć ekran wyboru roli:
- Kierownik
- Recepcja
- Mechanik

