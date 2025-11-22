--
-- PostgreSQL database dump
--

\restrict Tnvdto6HaYtw2Hd6SvsAeuf263IlRXfQNLl0wMF1B9DwLBj89PgpWcKiOi6Psxa

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: aktualizuj_stan_magazynu(); Type: FUNCTION; Schema: public; Owner: maciek
--

CREATE FUNCTION public.aktualizuj_stan_magazynu() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    IF (SELECT ilosc_na_stanie FROM Czesci WHERE id_czesci = NEW.id_czesci) < NEW.ilosc THEN
        RAISE EXCEPTION 'Brak wystarczajacej ilosci towaru w magazynie!';
    END IF;

    -- Zmniejsz stan
    UPDATE Czesci
    SET ilosc_na_stanie = ilosc_na_stanie - NEW.ilosc
    WHERE id_czesci = NEW.id_czesci;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.aktualizuj_stan_magazynu() OWNER TO maciek;

--
-- Name: czy_mechanik_dostepny(integer); Type: FUNCTION; Schema: public; Owner: maciek
--

CREATE FUNCTION public.czy_mechanik_dostepny(p_id_mechanika integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_liczba_zlecen INT;
BEGIN
    SELECT COUNT(*) INTO v_liczba_zlecen
    FROM Zlecenia
    WHERE id_mechanika = p_id_mechanika 
      AND status IN ('W trakcie', 'Przyjete', 'Oczekuje na czesci');
      
    IF v_liczba_zlecen > 0 THEN
        RETURN FALSE; -- Zajety
    ELSE
        RETURN TRUE; -- Wolny
    END IF;
END;
$$;


ALTER FUNCTION public.czy_mechanik_dostepny(p_id_mechanika integer) OWNER TO maciek;

--
-- Name: dodaj_klienta_i_auto(character varying, character varying, character varying, character varying, character varying, character varying); Type: PROCEDURE; Schema: public; Owner: maciek
--

CREATE PROCEDURE public.dodaj_klienta_i_auto(IN p_imie character varying, IN p_nazwisko character varying, IN p_telefon character varying, IN p_marka character varying, IN p_model character varying, IN p_vin character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_nowe_id_klienta INT;
BEGIN
    -- 1. Dodaj klienta i od razu pobierz jego nowe ID
    INSERT INTO Klienci (imie, nazwisko, telefon) 
    VALUES (p_imie, p_nazwisko, p_telefon)
    RETURNING id_klienta INTO v_nowe_id_klienta;

    -- 2. Dodaj auto przypisane do tego nowego ID
    INSERT INTO Pojazdy (id_klienta, marka, model, vin, rok) 
    VALUES (v_nowe_id_klienta, p_marka, p_model, p_vin, 2023); 
    -- rok wpisuje domyslnie, mozna dodac jako parametr

    RAISE NOTICE 'Dodano klienta ID: % oraz pojazd % %', v_nowe_id_klienta, p_marka, p_model;
    
    -- Tutaj nastepuje automatyczny COMMIT, jesli nie bylo bledu
END;
$$;


ALTER PROCEDURE public.dodaj_klienta_i_auto(IN p_imie character varying, IN p_nazwisko character varying, IN p_telefon character varying, IN p_marka character varying, IN p_model character varying, IN p_vin character varying) OWNER TO maciek;

--
-- Name: loguj_zmiane_ceny(); Type: FUNCTION; Schema: public; Owner: maciek
--

CREATE FUNCTION public.loguj_zmiane_ceny() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Dzialaj tylko jesli cena faktycznie sie zmienila
    IF NEW.cena <> OLD.cena THEN
        INSERT INTO Logi_Zmian_Cen (nazwa_uslugi, stara_cena, nowa_cena, uzytkownik)
        VALUES (OLD.nazwa, OLD.cena, NEW.cena, current_user);
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.loguj_zmiane_ceny() OWNER TO maciek;

--
-- Name: oblicz_pelny_koszt(integer); Type: FUNCTION; Schema: public; Owner: maciek
--

CREATE FUNCTION public.oblicz_pelny_koszt(p_id_zlecenia integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_koszt_robocizny NUMERIC;
    v_koszt_czesci NUMERIC;
    v_koszt_uslug NUMERIC; 
BEGIN

    SELECT COALESCE(koszt_robocizny, 0) INTO v_koszt_robocizny
    FROM Zlecenia 
    WHERE id_zlecenia = p_id_zlecenia;


    SELECT COALESCE(SUM(cz.ilosc * c.cena), 0) INTO v_koszt_czesci
    FROM Czesci_Zlecenia cz
    JOIN Czesci c ON cz.id_czesci = c.id_czesci
    WHERE cz.id_zlecenia = p_id_zlecenia;


    RETURN v_koszt_robocizny + v_koszt_czesci;
END;
$$;


ALTER FUNCTION public.oblicz_pelny_koszt(p_id_zlecenia integer) OWNER TO maciek;

--
-- Name: zakoncz_zlecenie(integer); Type: PROCEDURE; Schema: public; Owner: maciek
--

CREATE PROCEDURE public.zakoncz_zlecenie(IN p_id_zlecenia integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Sprawdzamy czy zlecenie istnieje i nie jest juz zakonczone
    IF NOT EXISTS (SELECT 1 FROM Zlecenia WHERE id_zlecenia = p_id_zlecenia) THEN
        RAISE EXCEPTION 'Zlecenie o ID % nie istnieje', p_id_zlecenia;
    END IF;

    UPDATE Zlecenia
    SET status = 'Zakonczone',
        data_zakonczenia = CURRENT_TIMESTAMP
    WHERE id_zlecenia = p_id_zlecenia;
    
    RAISE NOTICE 'Zlecenie % zostalo pomyslnie zakonczone.', p_id_zlecenia;
END;
$$;


ALTER PROCEDURE public.zakoncz_zlecenie(IN p_id_zlecenia integer) OWNER TO maciek;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: czesci; Type: TABLE; Schema: public; Owner: maciek
--

CREATE TABLE public.czesci (
    id_czesci integer NOT NULL,
    nazwa character varying(200),
    cena numeric(10,2),
    ilosc_na_stanie numeric(10,2),
    CONSTRAINT check_cena_czesci_positive CHECK ((cena >= (0)::numeric)),
    CONSTRAINT check_ilosc_czesci CHECK ((ilosc_na_stanie >= (0)::numeric))
);


ALTER TABLE public.czesci OWNER TO maciek;

--
-- Name: czesci_id_czesci_seq; Type: SEQUENCE; Schema: public; Owner: maciek
--

CREATE SEQUENCE public.czesci_id_czesci_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.czesci_id_czesci_seq OWNER TO maciek;

--
-- Name: czesci_id_czesci_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maciek
--

ALTER SEQUENCE public.czesci_id_czesci_seq OWNED BY public.czesci.id_czesci;


--
-- Name: czesci_zlecenia; Type: TABLE; Schema: public; Owner: maciek
--

CREATE TABLE public.czesci_zlecenia (
    id_czesci_zlecenia integer NOT NULL,
    id_zlecenia integer,
    id_czesci integer,
    ilosc integer,
    CONSTRAINT check_ilosc_w_zleceniu_positive CHECK ((ilosc > 0))
);


ALTER TABLE public.czesci_zlecenia OWNER TO maciek;

--
-- Name: czesci_zlecenia_id_czesci_zlecenia_seq; Type: SEQUENCE; Schema: public; Owner: maciek
--

CREATE SEQUENCE public.czesci_zlecenia_id_czesci_zlecenia_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.czesci_zlecenia_id_czesci_zlecenia_seq OWNER TO maciek;

--
-- Name: czesci_zlecenia_id_czesci_zlecenia_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maciek
--

ALTER SEQUENCE public.czesci_zlecenia_id_czesci_zlecenia_seq OWNED BY public.czesci_zlecenia.id_czesci_zlecenia;


--
-- Name: faktury; Type: TABLE; Schema: public; Owner: maciek
--

CREATE TABLE public.faktury (
    id_faktury integer NOT NULL,
    id_platnosci integer,
    data_wystawienia date DEFAULT CURRENT_DATE,
    kwota_brutto numeric(10,2),
    status_platnosci character varying(50)
);


ALTER TABLE public.faktury OWNER TO maciek;

--
-- Name: faktury_id_faktury_seq; Type: SEQUENCE; Schema: public; Owner: maciek
--

CREATE SEQUENCE public.faktury_id_faktury_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.faktury_id_faktury_seq OWNER TO maciek;

--
-- Name: faktury_id_faktury_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maciek
--

ALTER SEQUENCE public.faktury_id_faktury_seq OWNED BY public.faktury.id_faktury;


--
-- Name: klienci; Type: TABLE; Schema: public; Owner: maciek
--

CREATE TABLE public.klienci (
    id_klienta integer NOT NULL,
    imie character varying(100),
    nazwisko character varying(100),
    telefon character varying(20),
    email character varying(100),
    adres text,
    CONSTRAINT check_dlugosc_telefonu CHECK ((length((telefon)::text) >= 9))
);


ALTER TABLE public.klienci OWNER TO maciek;

--
-- Name: klienci_id_klienta_seq; Type: SEQUENCE; Schema: public; Owner: maciek
--

CREATE SEQUENCE public.klienci_id_klienta_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.klienci_id_klienta_seq OWNER TO maciek;

--
-- Name: klienci_id_klienta_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maciek
--

ALTER SEQUENCE public.klienci_id_klienta_seq OWNED BY public.klienci.id_klienta;


--
-- Name: logi_zmian_cen; Type: TABLE; Schema: public; Owner: maciek
--

CREATE TABLE public.logi_zmian_cen (
    id_logu integer NOT NULL,
    nazwa_uslugi character varying(200),
    stara_cena numeric(10,2),
    nowa_cena numeric(10,2),
    data_zmiany timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    uzytkownik character varying(100)
);


ALTER TABLE public.logi_zmian_cen OWNER TO maciek;

--
-- Name: logi_zmian_cen_id_logu_seq; Type: SEQUENCE; Schema: public; Owner: maciek
--

CREATE SEQUENCE public.logi_zmian_cen_id_logu_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.logi_zmian_cen_id_logu_seq OWNER TO maciek;

--
-- Name: logi_zmian_cen_id_logu_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maciek
--

ALTER SEQUENCE public.logi_zmian_cen_id_logu_seq OWNED BY public.logi_zmian_cen.id_logu;


--
-- Name: mechanicy; Type: TABLE; Schema: public; Owner: maciek
--

CREATE TABLE public.mechanicy (
    id_mechanika integer NOT NULL,
    imie character varying(100),
    nazwisko character varying(100),
    specjalizacja character varying(100),
    telefon character varying(20),
    stawka_godzinowa numeric(10,2),
    CONSTRAINT check_stawka_mechanika CHECK ((stawka_godzinowa > (0)::numeric))
);


ALTER TABLE public.mechanicy OWNER TO maciek;

--
-- Name: mechanicy_id_mechanika_seq; Type: SEQUENCE; Schema: public; Owner: maciek
--

CREATE SEQUENCE public.mechanicy_id_mechanika_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mechanicy_id_mechanika_seq OWNER TO maciek;

--
-- Name: mechanicy_id_mechanika_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maciek
--

ALTER SEQUENCE public.mechanicy_id_mechanika_seq OWNED BY public.mechanicy.id_mechanika;


--
-- Name: platnosci; Type: TABLE; Schema: public; Owner: maciek
--

CREATE TABLE public.platnosci (
    id_platnosci integer NOT NULL,
    id_zlecenia integer,
    data_platnosci timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    sposob_platnosci character varying(50),
    kwota numeric(10,2)
);


ALTER TABLE public.platnosci OWNER TO maciek;

--
-- Name: platnosci_id_platnosci_seq; Type: SEQUENCE; Schema: public; Owner: maciek
--

CREATE SEQUENCE public.platnosci_id_platnosci_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.platnosci_id_platnosci_seq OWNER TO maciek;

--
-- Name: platnosci_id_platnosci_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maciek
--

ALTER SEQUENCE public.platnosci_id_platnosci_seq OWNED BY public.platnosci.id_platnosci;


--
-- Name: pojazdy; Type: TABLE; Schema: public; Owner: maciek
--

CREATE TABLE public.pojazdy (
    id_pojazdu integer NOT NULL,
    id_klienta integer,
    marka character varying(50),
    model character varying(50),
    rok integer,
    nr_rejestracyjny character varying(20),
    vin character varying(20),
    CONSTRAINT check_rok_pojazdu CHECK (((rok >= 1900) AND ((rok)::numeric <= (EXTRACT(year FROM CURRENT_DATE) + (1)::numeric))))
);


ALTER TABLE public.pojazdy OWNER TO maciek;

--
-- Name: pojazdy_id_pojazdu_seq; Type: SEQUENCE; Schema: public; Owner: maciek
--

CREATE SEQUENCE public.pojazdy_id_pojazdu_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pojazdy_id_pojazdu_seq OWNER TO maciek;

--
-- Name: pojazdy_id_pojazdu_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maciek
--

ALTER SEQUENCE public.pojazdy_id_pojazdu_seq OWNED BY public.pojazdy.id_pojazdu;


--
-- Name: uslugi; Type: TABLE; Schema: public; Owner: maciek
--

CREATE TABLE public.uslugi (
    id_uslugi integer NOT NULL,
    nazwa character varying(200),
    opis text,
    cena numeric(10,2),
    CONSTRAINT check_cena_uslugi_positive CHECK ((cena >= (0)::numeric))
);


ALTER TABLE public.uslugi OWNER TO maciek;

--
-- Name: uslugi_id_uslugi_seq; Type: SEQUENCE; Schema: public; Owner: maciek
--

CREATE SEQUENCE public.uslugi_id_uslugi_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.uslugi_id_uslugi_seq OWNER TO maciek;

--
-- Name: uslugi_id_uslugi_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maciek
--

ALTER SEQUENCE public.uslugi_id_uslugi_seq OWNED BY public.uslugi.id_uslugi;


--
-- Name: uslugi_zlecenia; Type: TABLE; Schema: public; Owner: maciek
--

CREATE TABLE public.uslugi_zlecenia (
    id_uslugi_zlecenia integer NOT NULL,
    id_zlecenia integer,
    id_uslugi integer,
    ilosc integer DEFAULT 1,
    rabat numeric(5,2) DEFAULT 0,
    CONSTRAINT check_ilosc_uslug_positive CHECK ((ilosc > 0)),
    CONSTRAINT check_rabat_procent CHECK (((rabat >= (0)::numeric) AND (rabat <= (100)::numeric)))
);


ALTER TABLE public.uslugi_zlecenia OWNER TO maciek;

--
-- Name: uslugi_zlecenia_id_uslugi_zlecenia_seq; Type: SEQUENCE; Schema: public; Owner: maciek
--

CREATE SEQUENCE public.uslugi_zlecenia_id_uslugi_zlecenia_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.uslugi_zlecenia_id_uslugi_zlecenia_seq OWNER TO maciek;

--
-- Name: uslugi_zlecenia_id_uslugi_zlecenia_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maciek
--

ALTER SEQUENCE public.uslugi_zlecenia_id_uslugi_zlecenia_seq OWNED BY public.uslugi_zlecenia.id_uslugi_zlecenia;


--
-- Name: zlecenia; Type: TABLE; Schema: public; Owner: maciek
--

CREATE TABLE public.zlecenia (
    id_zlecenia integer NOT NULL,
    id_pojazdu integer,
    id_mechanika integer,
    data_przyjecia timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    data_zakonczenia timestamp without time zone,
    status character varying(50),
    opis text,
    koszt_robocizny numeric(10,2),
    CONSTRAINT check_kolejnosc_dat CHECK ((data_zakonczenia >= data_przyjecia)),
    CONSTRAINT check_status_zlecenia CHECK (((status)::text = ANY ((ARRAY['Przyjete'::character varying, 'W trakcie'::character varying, 'Oczekuje na czesci'::character varying, 'Zakonczone'::character varying, 'Anulowane'::character varying])::text[])))
);


ALTER TABLE public.zlecenia OWNER TO maciek;

--
-- Name: widok_aktywne_zlecenia; Type: VIEW; Schema: public; Owner: maciek
--

CREATE VIEW public.widok_aktywne_zlecenia AS
 SELECT z.id_zlecenia,
    ((((((p.marka)::text || ' '::text) || (p.model)::text) || ' ('::text) || (p.nr_rejestracyjny)::text) || ')'::text) AS samochod,
    (((k.imie)::text || ' '::text) || (k.nazwisko)::text) AS wlasciciel,
    (((m.imie)::text || ' '::text) || (m.nazwisko)::text) AS mechanik,
    z.data_przyjecia,
    z.status,
    z.opis
   FROM (((public.zlecenia z
     JOIN public.pojazdy p ON ((z.id_pojazdu = p.id_pojazdu)))
     JOIN public.klienci k ON ((p.id_klienta = k.id_klienta)))
     JOIN public.mechanicy m ON ((z.id_mechanika = m.id_mechanika)))
  WHERE ((z.status)::text <> ALL ((ARRAY['Zakonczone'::character varying, 'Anulowane'::character varying])::text[]));


ALTER VIEW public.widok_aktywne_zlecenia OWNER TO maciek;

--
-- Name: widok_do_zamowienia; Type: VIEW; Schema: public; Owner: maciek
--

CREATE VIEW public.widok_do_zamowienia AS
 SELECT id_czesci,
    nazwa,
    ilosc_na_stanie,
    cena AS cena_zakupu
   FROM public.czesci
  WHERE (ilosc_na_stanie < (10)::numeric)
  ORDER BY ilosc_na_stanie;


ALTER VIEW public.widok_do_zamowienia OWNER TO maciek;

--
-- Name: widok_historia_pojazdu; Type: VIEW; Schema: public; Owner: maciek
--

CREATE VIEW public.widok_historia_pojazdu AS
 SELECT p.vin,
    (((p.marka)::text || ' '::text) || (p.model)::text) AS auto,
    z.data_zakonczenia,
    z.opis AS wykonane_prace,
    (((m.imie)::text || ' '::text) || (m.nazwisko)::text) AS mechanik,
    (z.koszt_robocizny + COALESCE(( SELECT sum(((cz.ilosc)::numeric * c.cena)) AS sum
           FROM (public.czesci_zlecenia cz
             JOIN public.czesci c ON ((cz.id_czesci = c.id_czesci)))
          WHERE (cz.id_zlecenia = z.id_zlecenia)), (0)::numeric)) AS koszt_laczny
   FROM ((public.zlecenia z
     JOIN public.pojazdy p ON ((z.id_pojazdu = p.id_pojazdu)))
     JOIN public.mechanicy m ON ((z.id_mechanika = m.id_mechanika)))
  WHERE ((z.status)::text = 'Zakonczone'::text)
  ORDER BY z.data_zakonczenia DESC;


ALTER VIEW public.widok_historia_pojazdu OWNER TO maciek;

--
-- Name: widok_ranking_mechanikow; Type: VIEW; Schema: public; Owner: maciek
--

CREATE VIEW public.widok_ranking_mechanikow AS
 SELECT (((m.imie)::text || ' '::text) || (m.nazwisko)::text) AS mechanik,
    count(z.id_zlecenia) AS liczba_zlecen,
    sum(z.koszt_robocizny) AS laczny_przychod_z_robocizny,
    round(avg(z.koszt_robocizny), 2) AS srednia_na_zlecenie
   FROM (public.mechanicy m
     JOIN public.zlecenia z ON ((m.id_mechanika = z.id_mechanika)))
  WHERE ((z.status)::text = 'Zakonczone'::text)
  GROUP BY m.id_mechanika, m.imie, m.nazwisko
  ORDER BY (sum(z.koszt_robocizny)) DESC;


ALTER VIEW public.widok_ranking_mechanikow OWNER TO maciek;

--
-- Name: zlecenia_id_zlecenia_seq; Type: SEQUENCE; Schema: public; Owner: maciek
--

CREATE SEQUENCE public.zlecenia_id_zlecenia_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.zlecenia_id_zlecenia_seq OWNER TO maciek;

--
-- Name: zlecenia_id_zlecenia_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maciek
--

ALTER SEQUENCE public.zlecenia_id_zlecenia_seq OWNED BY public.zlecenia.id_zlecenia;


--
-- Name: czesci id_czesci; Type: DEFAULT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.czesci ALTER COLUMN id_czesci SET DEFAULT nextval('public.czesci_id_czesci_seq'::regclass);


--
-- Name: czesci_zlecenia id_czesci_zlecenia; Type: DEFAULT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.czesci_zlecenia ALTER COLUMN id_czesci_zlecenia SET DEFAULT nextval('public.czesci_zlecenia_id_czesci_zlecenia_seq'::regclass);


--
-- Name: faktury id_faktury; Type: DEFAULT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.faktury ALTER COLUMN id_faktury SET DEFAULT nextval('public.faktury_id_faktury_seq'::regclass);


--
-- Name: klienci id_klienta; Type: DEFAULT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.klienci ALTER COLUMN id_klienta SET DEFAULT nextval('public.klienci_id_klienta_seq'::regclass);


--
-- Name: logi_zmian_cen id_logu; Type: DEFAULT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.logi_zmian_cen ALTER COLUMN id_logu SET DEFAULT nextval('public.logi_zmian_cen_id_logu_seq'::regclass);


--
-- Name: mechanicy id_mechanika; Type: DEFAULT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.mechanicy ALTER COLUMN id_mechanika SET DEFAULT nextval('public.mechanicy_id_mechanika_seq'::regclass);


--
-- Name: platnosci id_platnosci; Type: DEFAULT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.platnosci ALTER COLUMN id_platnosci SET DEFAULT nextval('public.platnosci_id_platnosci_seq'::regclass);


--
-- Name: pojazdy id_pojazdu; Type: DEFAULT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.pojazdy ALTER COLUMN id_pojazdu SET DEFAULT nextval('public.pojazdy_id_pojazdu_seq'::regclass);


--
-- Name: uslugi id_uslugi; Type: DEFAULT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.uslugi ALTER COLUMN id_uslugi SET DEFAULT nextval('public.uslugi_id_uslugi_seq'::regclass);


--
-- Name: uslugi_zlecenia id_uslugi_zlecenia; Type: DEFAULT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.uslugi_zlecenia ALTER COLUMN id_uslugi_zlecenia SET DEFAULT nextval('public.uslugi_zlecenia_id_uslugi_zlecenia_seq'::regclass);


--
-- Name: zlecenia id_zlecenia; Type: DEFAULT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.zlecenia ALTER COLUMN id_zlecenia SET DEFAULT nextval('public.zlecenia_id_zlecenia_seq'::regclass);


--
-- Data for Name: czesci; Type: TABLE DATA; Schema: public; Owner: maciek
--

COPY public.czesci (id_czesci, nazwa, cena, ilosc_na_stanie) FROM stdin;
1	Olej 5W30 Castrol 4L	150.00	50.00
2	Filtr oleju Filtron	30.00	100.00
3	Opony Zimowe Debica R16 (szt)	250.00	40.00
4	Czynnik klimatyzacji 100g	20.00	500.00
5	Zestaw paska rozrzadu	450.00	5.00
6	Sprzeglo kompletne Valeo	700.00	3.00
7	Klocki hamulcowe Brembo	180.00	20.00
8	Tarcze hamulcowe Brembo	300.00	10.00
9	Akumulator 74Ah	400.00	8.00
10	Zarowka H7	15.00	200.00
11	Wycieraczki Bosch	80.00	15.00
12	Plyn do spryskiwaczy 5L	20.00	60.00
\.


--
-- Data for Name: czesci_zlecenia; Type: TABLE DATA; Schema: public; Owner: maciek
--

COPY public.czesci_zlecenia (id_czesci_zlecenia, id_zlecenia, id_czesci, ilosc) FROM stdin;
1	1	1	1
2	1	2	1
3	1	3	4
4	2	5	1
5	3	4	5
6	4	6	1
7	6	7	1
8	6	8	2
9	7	1	2
10	7	2	1
11	7	11	1
\.


--
-- Data for Name: faktury; Type: TABLE DATA; Schema: public; Owner: maciek
--

COPY public.faktury (id_faktury, id_platnosci, data_wystawienia, kwota_brutto, status_platnosci) FROM stdin;
1	1	2025-11-19	1400.00	Oplacona
2	2	2025-11-19	1050.00	Oplacona
3	3	2025-11-19	150.00	Oplacona
\.


--
-- Data for Name: klienci; Type: TABLE DATA; Schema: public; Owner: maciek
--

COPY public.klienci (id_klienta, imie, nazwisko, telefon, email, adres) FROM stdin;
1	Adam	Nowak	500100101	adam.n@gmail.com	ul. Prosta 10, Warszawa
2	Beata	Kowalska	500100102	b.kowalska@yahoo.com	ul. Krzywa 5, Krakow
3	Cezary	Pazura	500100103	czarek@film.pl	ul. Filmowa 3, Lodz
4	Dariusz	Michalczewski	500100104	tiger@boks.pl	ul. Ringowa 1, Gdansk
5	Ewa	Farna	500100105	ewa@muzyka.cz	ul. Spiewana 7, Cieszyn
6	Filip	Chajzer	500100106	filip@tv.pl	ul. Wizyjna 99, Warszawa
7	Grazyna	Zukowska	500100107	grazka@poczta.onet.pl	ul. Ogrodowa 2, Poznan
8	Henryk	Sienkiewicz	500100108	henryk@pisarz.pl	ul. Literacka 4, Lublin
9	Iga	Swiatek	500100109	iga@tenis.pl	ul. Kortowa 1, Raszyn
10	Jan	Blachowicz	500100110	jan@ufc.com	ul. Mocna 55, Cieszyn
\.


--
-- Data for Name: logi_zmian_cen; Type: TABLE DATA; Schema: public; Owner: maciek
--

COPY public.logi_zmian_cen (id_logu, nazwa_uslugi, stara_cena, nowa_cena, data_zmiany, uzytkownik) FROM stdin;
\.


--
-- Data for Name: mechanicy; Type: TABLE DATA; Schema: public; Owner: maciek
--

COPY public.mechanicy (id_mechanika, imie, nazwisko, specjalizacja, telefon, stawka_godzinowa) FROM stdin;
1	Wieslaw	Szybki	Silniki Diesla	600100100	180.00
2	Marian	Dokladny	Elektryka	600100101	150.00
3	Zbigniew	Spawacz	Blacharstwo i wydechy	600100102	130.00
4	Patryk	Mlody	Wulkanizacja i serwis	600100103	90.00
5	Robert	Szef	Diagnostyka glowna	600100104	250.00
\.


--
-- Data for Name: platnosci; Type: TABLE DATA; Schema: public; Owner: maciek
--

COPY public.platnosci (id_platnosci, id_zlecenia, data_platnosci, sposob_platnosci, kwota) FROM stdin;
1	1	2025-11-19 22:19:39.237579	Karta	1400.00
2	2	2025-11-19 22:19:39.247098	Gotowka	1050.00
3	5	2025-11-19 22:19:39.262379	Blik	150.00
4	6	2025-11-19 22:19:39.27707	Przelew	930.00
\.


--
-- Data for Name: pojazdy; Type: TABLE DATA; Schema: public; Owner: maciek
--

COPY public.pojazdy (id_pojazdu, id_klienta, marka, model, rok, nr_rejestracyjny, vin) FROM stdin;
1	1	Toyota	Corolla	2015	WA 11111	VIN1111111111
2	1	Fiat	Panda	2010	WA 22222	VIN2222222222
3	2	Honda	Civic	2018	KR 33333	VIN3333333333
4	3	BMW	X5	2020	EL 44444	VIN4444444444
5	4	Mercedes	S-Class	2019	GD 55555	VIN5555555555
6	5	Skoda	Octavia	2016	SCI 66666	VIN6666666666
7	6	Volvo	XC90	2021	WA 77777	VIN7777777777
8	7	Opel	Astra	2005	PO 88888	VIN8888888888
9	8	Ford	Mustang	1969	LU 99999	VIN9999999999
10	9	Porsche	Panamera	2022	WA 00001	VIN0000000001
11	10	Jeep	Wrangler	2017	SCI 00002	VIN0000000002
12	2	Audi	A3	2012	KR 12345	VIN1234567890
\.


--
-- Data for Name: uslugi; Type: TABLE DATA; Schema: public; Owner: maciek
--

COPY public.uslugi (id_uslugi, nazwa, opis, cena) FROM stdin;
1	Wymiana oleju	Pelny serwis olejowy z filtrem	100.00
2	Wymiana opon (kpl)	Demontaz, wywazenie, montaz	120.00
3	Serwis klimatyzacji	Odgrzybianie i nabijanie czynnika	200.00
4	Wymiana rozrzadu	Robocizna przy wymianie paska/lancucha	600.00
5	Diagnostyka komputerowa	Podlaczenie OBD i analiza bledow	150.00
6	Wymiana sprzegla	Demontaz skrzyni i wymiana kompletu	800.00
7	Polerowanie reflektorow	Renowacja kloszy lamp przednich	100.00
8	Przeglad przedsprzedazowy	Pelne sprawdzenie stanu technicznego	300.00
\.


--
-- Data for Name: uslugi_zlecenia; Type: TABLE DATA; Schema: public; Owner: maciek
--

COPY public.uslugi_zlecenia (id_uslugi_zlecenia, id_zlecenia, id_uslugi, ilosc, rabat) FROM stdin;
1	1	1	1	0.00
2	1	2	1	0.00
3	2	4	1	0.00
4	3	3	1	0.00
5	5	5	1	0.00
6	6	8	1	0.00
7	7	8	1	0.00
8	7	7	1	0.00
\.


--
-- Data for Name: zlecenia; Type: TABLE DATA; Schema: public; Owner: maciek
--

COPY public.zlecenia (id_zlecenia, id_pojazdu, id_mechanika, data_przyjecia, data_zakonczenia, status, opis, koszt_robocizny) FROM stdin;
1	1	4	2023-09-01 08:00:00	2023-09-01 12:00:00	Zakonczone	Standardowy serwis	220.00
2	6	1	2023-09-05 08:00:00	2023-09-06 16:00:00	Zakonczone	Silnik glosno pracowal	600.00
3	4	2	2023-10-01 09:00:00	\N	W trakcie	Slaba wydajnosc chlodzenia	200.00
4	11	3	2023-10-03 10:00:00	\N	Przyjete	Slizga sie sprzeglo na 4 biegu	800.00
5	10	5	2023-09-15 11:00:00	2023-09-15 11:30:00	Zakonczone	Kontrolka silnika	150.00
6	2	3	2023-09-20 08:00:00	2023-09-20 14:00:00	Zakonczone	Szuranie przy hamowaniu	150.00
7	9	5	2023-09-25 09:00:00	2023-09-25 15:00:00	Zakonczone	Auto na zlot, musi byc idealne	300.00
\.


--
-- Name: czesci_id_czesci_seq; Type: SEQUENCE SET; Schema: public; Owner: maciek
--

SELECT pg_catalog.setval('public.czesci_id_czesci_seq', 12, true);


--
-- Name: czesci_zlecenia_id_czesci_zlecenia_seq; Type: SEQUENCE SET; Schema: public; Owner: maciek
--

SELECT pg_catalog.setval('public.czesci_zlecenia_id_czesci_zlecenia_seq', 11, true);


--
-- Name: faktury_id_faktury_seq; Type: SEQUENCE SET; Schema: public; Owner: maciek
--

SELECT pg_catalog.setval('public.faktury_id_faktury_seq', 3, true);


--
-- Name: klienci_id_klienta_seq; Type: SEQUENCE SET; Schema: public; Owner: maciek
--

SELECT pg_catalog.setval('public.klienci_id_klienta_seq', 10, true);


--
-- Name: logi_zmian_cen_id_logu_seq; Type: SEQUENCE SET; Schema: public; Owner: maciek
--

SELECT pg_catalog.setval('public.logi_zmian_cen_id_logu_seq', 1, false);


--
-- Name: mechanicy_id_mechanika_seq; Type: SEQUENCE SET; Schema: public; Owner: maciek
--

SELECT pg_catalog.setval('public.mechanicy_id_mechanika_seq', 5, true);


--
-- Name: platnosci_id_platnosci_seq; Type: SEQUENCE SET; Schema: public; Owner: maciek
--

SELECT pg_catalog.setval('public.platnosci_id_platnosci_seq', 4, true);


--
-- Name: pojazdy_id_pojazdu_seq; Type: SEQUENCE SET; Schema: public; Owner: maciek
--

SELECT pg_catalog.setval('public.pojazdy_id_pojazdu_seq', 12, true);


--
-- Name: uslugi_id_uslugi_seq; Type: SEQUENCE SET; Schema: public; Owner: maciek
--

SELECT pg_catalog.setval('public.uslugi_id_uslugi_seq', 8, true);


--
-- Name: uslugi_zlecenia_id_uslugi_zlecenia_seq; Type: SEQUENCE SET; Schema: public; Owner: maciek
--

SELECT pg_catalog.setval('public.uslugi_zlecenia_id_uslugi_zlecenia_seq', 8, true);


--
-- Name: zlecenia_id_zlecenia_seq; Type: SEQUENCE SET; Schema: public; Owner: maciek
--

SELECT pg_catalog.setval('public.zlecenia_id_zlecenia_seq', 7, true);


--
-- Name: czesci czesci_pkey; Type: CONSTRAINT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.czesci
    ADD CONSTRAINT czesci_pkey PRIMARY KEY (id_czesci);


--
-- Name: czesci_zlecenia czesci_zlecenia_pkey; Type: CONSTRAINT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.czesci_zlecenia
    ADD CONSTRAINT czesci_zlecenia_pkey PRIMARY KEY (id_czesci_zlecenia);


--
-- Name: faktury faktury_pkey; Type: CONSTRAINT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.faktury
    ADD CONSTRAINT faktury_pkey PRIMARY KEY (id_faktury);


--
-- Name: klienci klienci_pkey; Type: CONSTRAINT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.klienci
    ADD CONSTRAINT klienci_pkey PRIMARY KEY (id_klienta);


--
-- Name: logi_zmian_cen logi_zmian_cen_pkey; Type: CONSTRAINT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.logi_zmian_cen
    ADD CONSTRAINT logi_zmian_cen_pkey PRIMARY KEY (id_logu);


--
-- Name: mechanicy mechanicy_pkey; Type: CONSTRAINT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.mechanicy
    ADD CONSTRAINT mechanicy_pkey PRIMARY KEY (id_mechanika);


--
-- Name: platnosci platnosci_pkey; Type: CONSTRAINT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.platnosci
    ADD CONSTRAINT platnosci_pkey PRIMARY KEY (id_platnosci);


--
-- Name: pojazdy pojazdy_pkey; Type: CONSTRAINT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.pojazdy
    ADD CONSTRAINT pojazdy_pkey PRIMARY KEY (id_pojazdu);


--
-- Name: klienci unique_email; Type: CONSTRAINT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.klienci
    ADD CONSTRAINT unique_email UNIQUE (email);


--
-- Name: pojazdy unique_rejestracja; Type: CONSTRAINT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.pojazdy
    ADD CONSTRAINT unique_rejestracja UNIQUE (nr_rejestracyjny);


--
-- Name: pojazdy unique_vin; Type: CONSTRAINT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.pojazdy
    ADD CONSTRAINT unique_vin UNIQUE (vin);


--
-- Name: uslugi uslugi_pkey; Type: CONSTRAINT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.uslugi
    ADD CONSTRAINT uslugi_pkey PRIMARY KEY (id_uslugi);


--
-- Name: uslugi_zlecenia uslugi_zlecenia_pkey; Type: CONSTRAINT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.uslugi_zlecenia
    ADD CONSTRAINT uslugi_zlecenia_pkey PRIMARY KEY (id_uslugi_zlecenia);


--
-- Name: zlecenia zlecenia_pkey; Type: CONSTRAINT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.zlecenia
    ADD CONSTRAINT zlecenia_pkey PRIMARY KEY (id_zlecenia);


--
-- Name: uslugi trigger_audit_ceny; Type: TRIGGER; Schema: public; Owner: maciek
--

CREATE TRIGGER trigger_audit_ceny AFTER UPDATE ON public.uslugi FOR EACH ROW EXECUTE FUNCTION public.loguj_zmiane_ceny();


--
-- Name: czesci_zlecenia trigger_zdejmij_czesci; Type: TRIGGER; Schema: public; Owner: maciek
--

CREATE TRIGGER trigger_zdejmij_czesci AFTER INSERT ON public.czesci_zlecenia FOR EACH ROW EXECUTE FUNCTION public.aktualizuj_stan_magazynu();


--
-- Name: czesci_zlecenia czesci_zlecenia_id_czesci_fkey; Type: FK CONSTRAINT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.czesci_zlecenia
    ADD CONSTRAINT czesci_zlecenia_id_czesci_fkey FOREIGN KEY (id_czesci) REFERENCES public.czesci(id_czesci);


--
-- Name: czesci_zlecenia czesci_zlecenia_id_zlecenia_fkey; Type: FK CONSTRAINT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.czesci_zlecenia
    ADD CONSTRAINT czesci_zlecenia_id_zlecenia_fkey FOREIGN KEY (id_zlecenia) REFERENCES public.zlecenia(id_zlecenia);


--
-- Name: faktury faktury_id_platnosci_fkey; Type: FK CONSTRAINT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.faktury
    ADD CONSTRAINT faktury_id_platnosci_fkey FOREIGN KEY (id_platnosci) REFERENCES public.platnosci(id_platnosci);


--
-- Name: platnosci platnosci_id_zlecenia_fkey; Type: FK CONSTRAINT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.platnosci
    ADD CONSTRAINT platnosci_id_zlecenia_fkey FOREIGN KEY (id_zlecenia) REFERENCES public.zlecenia(id_zlecenia);


--
-- Name: pojazdy pojazdy_id_klienta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.pojazdy
    ADD CONSTRAINT pojazdy_id_klienta_fkey FOREIGN KEY (id_klienta) REFERENCES public.klienci(id_klienta);


--
-- Name: uslugi_zlecenia uslugi_zlecenia_id_uslugi_fkey; Type: FK CONSTRAINT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.uslugi_zlecenia
    ADD CONSTRAINT uslugi_zlecenia_id_uslugi_fkey FOREIGN KEY (id_uslugi) REFERENCES public.uslugi(id_uslugi);


--
-- Name: uslugi_zlecenia uslugi_zlecenia_id_zlecenia_fkey; Type: FK CONSTRAINT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.uslugi_zlecenia
    ADD CONSTRAINT uslugi_zlecenia_id_zlecenia_fkey FOREIGN KEY (id_zlecenia) REFERENCES public.zlecenia(id_zlecenia);


--
-- Name: zlecenia zlecenia_id_mechanika_fkey; Type: FK CONSTRAINT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.zlecenia
    ADD CONSTRAINT zlecenia_id_mechanika_fkey FOREIGN KEY (id_mechanika) REFERENCES public.mechanicy(id_mechanika);


--
-- Name: zlecenia zlecenia_id_pojazdu_fkey; Type: FK CONSTRAINT; Schema: public; Owner: maciek
--

ALTER TABLE ONLY public.zlecenia
    ADD CONSTRAINT zlecenia_id_pojazdu_fkey FOREIGN KEY (id_pojazdu) REFERENCES public.pojazdy(id_pojazdu);


--
-- PostgreSQL database dump complete
--

\unrestrict Tnvdto6HaYtw2Hd6SvsAeuf263IlRXfQNLl0wMF1B9DwLBj89PgpWcKiOi6Psxa

