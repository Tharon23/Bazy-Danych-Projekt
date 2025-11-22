-- Relacje dla Pojazdów
ALTER TABLE pojazdy
    ADD CONSTRAINT fk_pojazdy_klienci FOREIGN KEY (id_klienta) REFERENCES klienci(id_klienta);

-- Relacje dla Zleceń
ALTER TABLE zlecenia
    ADD CONSTRAINT fk_zlecenia_pojazdy FOREIGN KEY (id_pojazdu) REFERENCES pojazdy(id_pojazdu),
    ADD CONSTRAINT fk_zlecenia_mechanicy FOREIGN KEY (id_mechanika) REFERENCES mechanicy(id_mechanika);

-- Relacje dla Usług w Zleceniu
ALTER TABLE uslugi_zlecenia
    ADD CONSTRAINT fk_uz_zlecenia FOREIGN KEY (id_zlecenia) REFERENCES zlecenia(id_zlecenia),
    ADD CONSTRAINT fk_uz_uslugi FOREIGN KEY (id_uslugi) REFERENCES uslugi(id_uslugi);

-- Relacje dla Części w Zleceniu
ALTER TABLE czesci_zlecenia
    ADD CONSTRAINT fk_cz_zlecenia FOREIGN KEY (id_zlecenia) REFERENCES zlecenia(id_zlecenia),
    ADD CONSTRAINT fk_cz_czesci FOREIGN KEY (id_czesci) REFERENCES czesci(id_czesci);

-- Relacje dla Płatności i Faktur
ALTER TABLE platnosci
    ADD CONSTRAINT fk_platnosci_zlecenia FOREIGN KEY (id_zlecenia) REFERENCES zlecenia(id_zlecenia);

ALTER TABLE faktury
    ADD CONSTRAINT fk_faktury_platnosci FOREIGN KEY (id_platnosci) REFERENCES platnosci(id_platnosci);

-- Relacje dla Przeglądów
ALTER TABLE przeglady
    ADD CONSTRAINT fk_przeglady_pojazdy FOREIGN KEY (id_pojazdu) REFERENCES pojazdy(id_pojazdu);