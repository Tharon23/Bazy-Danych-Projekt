-- Definicje kluczy obcych

ALTER TABLE pojazdy
    ADD CONSTRAINT fk_pojazdy_klienci FOREIGN KEY (id_klienta) REFERENCES klienci(id_klienta);

ALTER TABLE zlecenia
    ADD CONSTRAINT fk_zlecenia_pojazdy FOREIGN KEY (id_pojazdu) REFERENCES pojazdy(id_pojazdu),
    ADD CONSTRAINT fk_zlecenia_mechanicy FOREIGN KEY (id_mechanika) REFERENCES mechanicy(id_mechanika);

ALTER TABLE uslugi_zlecenia
    ADD CONSTRAINT fk_uz_zlecenia FOREIGN KEY (id_zlecenia) REFERENCES zlecenia(id_zlecenia),
    ADD CONSTRAINT fk_uz_uslugi FOREIGN KEY (id_uslugi) REFERENCES uslugi(id_uslugi);

ALTER TABLE czesci_zlecenia
    ADD CONSTRAINT fk_cz_zlecenia FOREIGN KEY (id_zlecenia) REFERENCES zlecenia(id_zlecenia),
    ADD CONSTRAINT fk_cz_czesci FOREIGN KEY (id_czesci) REFERENCES czesci(id_czesci);

ALTER TABLE platnosci
    ADD CONSTRAINT fk_platnosci_zlecenia FOREIGN KEY (id_zlecenia) REFERENCES zlecenia(id_zlecenia);

ALTER TABLE faktury
    ADD CONSTRAINT fk_faktury_platnosci FOREIGN KEY (id_platnosci) REFERENCES platnosci(id_platnosci);

ALTER TABLE przeglady
    ADD CONSTRAINT fk_przeglady_pojazdy FOREIGN KEY (id_pojazdu) REFERENCES pojazdy(id_pojazdu);