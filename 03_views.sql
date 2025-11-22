-- Widok 1: Aktywne zlecenia (dla recepcji/mechaników)
CREATE OR REPLACE VIEW widok_aktywne_zlecenia AS
SELECT 
    z.id_zlecenia,
    p.marka || ' ' || p.model || ' (' || p.nr_rejestracyjny || ')' AS samochod,
    k.imie || ' ' || k.nazwisko AS wlasciciel,
    m.imie || ' ' || m.nazwisko AS mechanik,
    z.data_przyjecia,
    z.status,
    z.opis
FROM zlecenia z
JOIN pojazdy p ON z.id_pojazdu = p.id_pojazdu
JOIN klienci k ON p.id_klienta = k.id_klienta
JOIN mechanicy m ON z.id_mechanika = m.id_mechanika
WHERE z.status NOT IN ('Zakonczone', 'Anulowane');

-- Widok 2: Części do zamówienia (mała ilość na stanie)
CREATE OR REPLACE VIEW widok_do_zamowienia AS
SELECT id_czesci, nazwa, ilosc_na_stanie, cena AS cena_zakupu
FROM czesci
WHERE ilosc_na_stanie < 10
ORDER BY ilosc_na_stanie;

-- Widok 3: Ranking mechaników (kto zarabia najwięcej dla firmy)
CREATE OR REPLACE VIEW widok_ranking_mechanikow AS
SELECT 
    m.imie || ' ' || m.nazwisko AS mechanik,
    COUNT(z.id_zlecenia) AS liczba_zlecen,
    SUM(z.koszt_robocizny) AS laczny_przychod_z_robocizny,
    ROUND(AVG(z.koszt_robocizny), 2) AS srednia_na_zlecenie
FROM mechanicy m
JOIN zlecenia z ON m.id_mechanika = z.id_mechanika
WHERE z.status = 'Zakonczone'
GROUP BY m.id_mechanika, m.imie, m.nazwisko
ORDER BY laczny_przychod_z_robocizny DESC;