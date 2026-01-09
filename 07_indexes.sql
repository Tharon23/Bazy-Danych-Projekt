-- Optymalizacja: Indeksy

-- Przyspieszenie wyszukiwania w panelu klienta
CREATE INDEX idx_klienci_nazwisko ON klienci(nazwisko);
CREATE INDEX idx_klienci_telefon ON klienci(telefon);

-- Przyspieszenie identyfikacji pojazdów
CREATE INDEX idx_pojazdy_rejestracja ON pojazdy(nr_rejestracyjny);
CREATE INDEX idx_pojazdy_vin ON pojazdy(vin);

-- Optymalizacja filtrów statusów zleceń
CREATE INDEX idx_zlecenia_status ON zlecenia(status);

-- Indeksy dla kluczy obcych (JOIN performance)
CREATE INDEX idx_zlecenia_id_pojazdu ON zlecenia(id_pojazdu);
CREATE INDEX idx_zlecenia_id_mechanika ON zlecenia(id_mechanika);