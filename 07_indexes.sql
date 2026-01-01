-- Indeksy przyspieszające wyszukiwanie

-- 1. Szybkie szukanie klienta po nazwisku (częsta operacja w recepcji)
CREATE INDEX idx_klienci_nazwisko ON klienci(nazwisko);

-- 2. Szybkie szukanie klienta po telefonie
CREATE INDEX idx_klienci_telefon ON klienci(telefon);

-- 3. Szybkie szukanie pojazdu po numerze rejestracyjnym
CREATE INDEX idx_pojazdy_rejestracja ON pojazdy(nr_rejestracyjny);

-- 4. Szybkie szukanie pojazdu po VIN
CREATE INDEX idx_pojazdy_vin ON pojazdy(vin);

-- 5. Szybkie filtrowanie zleceń po statusie (np. "pokaż wszystkie w trakcie")
CREATE INDEX idx_zlecenia_status ON zlecenia(status);

-- 6. Indeks dla kluczy obcych (dobra praktyka dla wydajności złączeń JOIN)
CREATE INDEX idx_zlecenia_id_pojazdu ON zlecenia(id_pojazdu);
CREATE INDEX idx_zlecenia_id_mechanika ON zlecenia(id_mechanika);

-- Nowe indeksy (Brakujące relacje)
CREATE INDEX idx_pojazdy_id_klienta ON pojazdy(id_klienta);
CREATE INDEX idx_uz_id_zlecenia ON uslugi_zlecenia(id_zlecenia);
CREATE INDEX idx_uz_id_uslugi ON uslugi_zlecenia(id_uslugi);
CREATE INDEX idx_cz_id_zlecenia ON czesci_zlecenia(id_zlecenia);
CREATE INDEX idx_cz_id_czesci ON czesci_zlecenia(id_czesci);
CREATE INDEX idx_platnosci_id_zlecenia ON platnosci(id_zlecenia);
CREATE INDEX idx_faktury_id_platnosci ON faktury(id_platnosci);
CREATE INDEX idx_przeglady_id_pojazdu ON przeglady(id_pojazdu);