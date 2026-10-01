--
-- PostgreSQL database dump
--

\restrict abWuOstBq298TvUnimqkyHtSd3ymdpm7pioZrHFkcs1NbNEVfeXVCMVotRLtId1

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

-- Started on 2026-05-10 17:39:30

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
-- TOC entry 2 (class 3079 OID 17023)
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- TOC entry 6049 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- TOC entry 766 (class 1255 OID 18376)
-- Name: f_kollektiivi_esinemised(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.f_kollektiivi_esinemised(kollektiivi_nimi character varying) RETURNS TABLE(festivali_nimi character varying, lava_nimi character varying, kollektiiv_nimi character varying, algusaeg timestamp without time zone, loppaeg timestamp without time zone, zanr character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
RETURN query
    select
		ve.festivali_nimi,
		ve.lava_nimi,
		ve.kollektiiv,
		ve.algusaeg,
		ve.loppaeg,
		ve.zanr
	from v_esinemised ve
	where kollektiiv = f_kollektiivi_esinemised.kollektiivi_nimi
	order by algusaeg;
END;
$$;


--
-- TOC entry 843 (class 1255 OID 18377)
-- Name: f_muugikohad(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.f_muugikohad(festival_id integer) RETURNS TABLE(muugikoha_nimi character varying, muuja character varying, peamine_kaubatuup character varying, asukoht public.geography, asukoha_kirjeldus text)
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN query
	SELECT
		mk.nimi,
		m.nimi,
		pk.nimetus,
		a.koordinaadid,
		a.kirjeldus
	from muugikohad mk
	join muujad m on mk.muuja_id = m.muuja_id
	join peamised_kaubatuubid pk on mk.kaubatuup_id = pk.kaubatuup_id
	join asukohad a on mk.asukoht_id = a.asukoht_id
	WHERE mk.festival_id = f_muugikohad.festival_id;
END;
$$;


--
-- TOC entry 738 (class 1255 OID 18378)
-- Name: p_lisa_esinemine(integer, integer, timestamp without time zone, timestamp without time zone, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.p_lisa_esinemine(IN p_lava_id integer, IN p_kollektiiv_id integer, IN p_algusaeg timestamp without time zone, IN p_loppaeg timestamp without time zone, IN p_tehnilised_nouded text)
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (p_loppaeg <= p_algusaeg) THEN
		RAISE EXCEPTION 'Lõppaeg peab olema algusajast hilisem!';
	END IF;

	IF (SELECT algus_kuupaev 
		FROM festivalid f 
		WHERE festival_id = (SELECT festival_id FROM lavad WHERE lava_id = p_lava_id)) > p_algusaeg THEN
		RAISE EXCEPTION 'Esinemise algusaeg peab olema hilisem kui festivali algusaeg!';
	END IF;

	IF (SELECT lopp_kuupaev + 1 
		FROM festivalid f 
		WHERE festival_id = (SELECT festival_id FROM lavad WHERE lava_id = p_lava_id)) < p_loppaeg THEN
		RAISE EXCEPTION 'Esinemise lõppaeg peab olema varasem kui festivali lõppaeg!';
	END IF;

	IF EXISTS (
		SELECT 1 
		FROM esinemised 
		WHERE lava_id = p_lava_id 
		  AND (p_algusaeg, p_loppaeg) OVERLAPS (algusaeg, loppaeg)
	) THEN
		RAISE EXCEPTION 'Sellel laval on sel ajavahemikul juba teine esinemine kirjas!';
	END IF;


	INSERT INTO esinemised (
		lava_id,
		kollektiiv_id,
		algusaeg,
		loppaeg,
		tehnilised_nouded
		)
		VALUES(
		p_lava_id,
		p_kollektiiv_id,
		p_algusaeg,
		p_loppaeg,
		p_tehnilised_nouded
		);
END;
$$;


--
-- TOC entry 536 (class 1255 OID 18379)
-- Name: p_muu_pilet(character varying, integer, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.p_muu_pilet(IN p_piletinumber character varying, IN p_piletituup_id integer, IN p_isik_id integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO piletid(
		piletinumber,
		piletituup_id,
		isik_id
		)
		
	VALUES (
		p_piletinumber,
		p_piletituup_id,
		p_isik_id
		);
	END;
$$;


--
-- TOC entry 795 (class 1255 OID 18437)
-- Name: p_muu_pilet(character varying, integer, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.p_muu_pilet(IN p_piletinumber character varying, IN p_piletituup_id integer, IN p_isik_meil character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO piletid(
		piletinumber,
		piletituup_id,
		isik_id
		) VALUES (
		p_piletinumber,
		p_piletituup_id,
		(SELECT i.isik_id FROM isikud i WHERE i.meil = p_isik_meil)
		);
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 236 (class 1259 OID 18106)
-- Name: asukohad; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asukohad (
    asukoht_id integer NOT NULL,
    koordinaadid public.geography(Point,4326) NOT NULL,
    kirjeldus text
);


--
-- TOC entry 235 (class 1259 OID 18105)
-- Name: asukohad_asukoht_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.asukohad_asukoht_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 6050 (class 0 OID 0)
-- Dependencies: 235
-- Name: asukohad_asukoht_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.asukohad_asukoht_id_seq OWNED BY public.asukohad.asukoht_id;


--
-- TOC entry 252 (class 1259 OID 18268)
-- Name: esinemised; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.esinemised (
    esinemine_id integer NOT NULL,
    lava_id integer NOT NULL,
    kollektiiv_id integer NOT NULL,
    algusaeg timestamp without time zone NOT NULL,
    loppaeg timestamp without time zone NOT NULL,
    tehnilised_nouded text
);


--
-- TOC entry 251 (class 1259 OID 18267)
-- Name: esinemised_esinemine_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.esinemised_esinemine_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 6051 (class 0 OID 0)
-- Dependencies: 251
-- Name: esinemised_esinemine_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.esinemised_esinemine_id_seq OWNED BY public.esinemised.esinemine_id;


--
-- TOC entry 242 (class 1259 OID 18146)
-- Name: festivalid; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.festivalid (
    festival_id integer NOT NULL,
    nimi character varying(100) NOT NULL,
    algus_kuupaev date NOT NULL,
    lopp_kuupaev date NOT NULL,
    mahutavus integer NOT NULL,
    staatus_id integer NOT NULL
);


--
-- TOC entry 241 (class 1259 OID 18145)
-- Name: festivalid_festival_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.festivalid_festival_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 6052 (class 0 OID 0)
-- Dependencies: 241
-- Name: festivalid_festival_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.festivalid_festival_id_seq OWNED BY public.festivalid.festival_id;


--
-- TOC entry 255 (class 1259 OID 18314)
-- Name: isik_kollektiiv; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.isik_kollektiiv (
    isik_id integer NOT NULL,
    kollektiiv_id integer NOT NULL
);


--
-- TOC entry 256 (class 1259 OID 18338)
-- Name: isik_roll_festival; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.isik_roll_festival (
    isik_id integer NOT NULL,
    roll_id integer NOT NULL,
    festival_id integer NOT NULL
);


--
-- TOC entry 238 (class 1259 OID 18119)
-- Name: isikud; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.isikud (
    isik_id integer NOT NULL,
    meil character varying(255) NOT NULL,
    eesnimi character varying(50) NOT NULL,
    perenimi character varying(50) NOT NULL,
    telefon character varying(20)
);


--
-- TOC entry 237 (class 1259 OID 18118)
-- Name: isikud_isik_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.isikud_isik_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 6053 (class 0 OID 0)
-- Dependencies: 237
-- Name: isikud_isik_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.isikud_isik_id_seq OWNED BY public.isikud.isik_id;


--
-- TOC entry 244 (class 1259 OID 18166)
-- Name: kollektiivid; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.kollektiivid (
    kollektiiv_id integer NOT NULL,
    nimi character varying(100) NOT NULL,
    riik_id integer NOT NULL,
    zanr_id integer NOT NULL
);


--
-- TOC entry 243 (class 1259 OID 18165)
-- Name: kollektiivid_kollektiiv_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.kollektiivid_kollektiiv_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 6054 (class 0 OID 0)
-- Dependencies: 243
-- Name: kollektiivid_kollektiiv_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.kollektiivid_kollektiiv_id_seq OWNED BY public.kollektiivid.kollektiiv_id;


--
-- TOC entry 246 (class 1259 OID 18189)
-- Name: lavad; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lavad (
    lava_id integer NOT NULL,
    festival_id integer NOT NULL,
    nimi character varying(50) NOT NULL,
    asukoht_id integer NOT NULL
);


--
-- TOC entry 245 (class 1259 OID 18188)
-- Name: lavad_lava_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lavad_lava_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 6055 (class 0 OID 0)
-- Dependencies: 245
-- Name: lavad_lava_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lavad_lava_id_seq OWNED BY public.lavad.lava_id;


--
-- TOC entry 250 (class 1259 OID 18233)
-- Name: muugikohad; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.muugikohad (
    muugikoht_id integer NOT NULL,
    festival_id integer NOT NULL,
    nimi character varying(50) NOT NULL,
    muuja_id integer NOT NULL,
    kaubatuup_id integer NOT NULL,
    asukoht_id integer NOT NULL
);


--
-- TOC entry 249 (class 1259 OID 18232)
-- Name: muugikohad_muugikoht_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.muugikohad_muugikoht_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 6056 (class 0 OID 0)
-- Dependencies: 249
-- Name: muugikohad_muugikoht_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.muugikohad_muugikoht_id_seq OWNED BY public.muugikohad.muugikoht_id;


--
-- TOC entry 240 (class 1259 OID 18132)
-- Name: muujad; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.muujad (
    muuja_id integer NOT NULL,
    reg_kood character varying(20) NOT NULL,
    nimi character varying(100) NOT NULL,
    kontaktinfo text
);


--
-- TOC entry 239 (class 1259 OID 18131)
-- Name: muujad_muuja_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.muujad_muuja_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 6057 (class 0 OID 0)
-- Dependencies: 239
-- Name: muujad_muuja_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.muujad_muuja_id_seq OWNED BY public.muujad.muuja_id;


--
-- TOC entry 227 (class 1259 OID 17002)
-- Name: peamised_kaubatuubid; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.peamised_kaubatuubid (
    kaubatuup_id integer NOT NULL,
    nimetus character varying(50) NOT NULL
);


--
-- TOC entry 226 (class 1259 OID 17001)
-- Name: peamised_kaubatuubid_kaubatuup_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.peamised_kaubatuubid_kaubatuup_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 6058 (class 0 OID 0)
-- Dependencies: 226
-- Name: peamised_kaubatuubid_kaubatuup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.peamised_kaubatuubid_kaubatuup_id_seq OWNED BY public.peamised_kaubatuubid.kaubatuup_id;


--
-- TOC entry 254 (class 1259 OID 18292)
-- Name: piletid; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.piletid (
    pilet_id integer NOT NULL,
    piletinumber character varying(50) NOT NULL,
    piletituup_id integer NOT NULL,
    isik_id integer NOT NULL
);


--
-- TOC entry 253 (class 1259 OID 18291)
-- Name: piletid_pilet_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.piletid_pilet_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 6059 (class 0 OID 0)
-- Dependencies: 253
-- Name: piletid_pilet_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.piletid_pilet_id_seq OWNED BY public.piletid.pilet_id;


--
-- TOC entry 248 (class 1259 OID 18212)
-- Name: piletituubid; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.piletituubid (
    piletituup_id integer NOT NULL,
    festival_id integer NOT NULL,
    nimetus character varying(50) NOT NULL,
    hind numeric(6,2) NOT NULL,
    kehtivus_algus timestamp without time zone NOT NULL,
    kehtivus_lopp timestamp without time zone,
    tingimused text
);


--
-- TOC entry 247 (class 1259 OID 18211)
-- Name: piletituubid_piletituup_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.piletituubid_piletituup_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 6060 (class 0 OID 0)
-- Dependencies: 247
-- Name: piletituubid_piletituup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.piletituubid_piletituup_id_seq OWNED BY public.piletituubid.piletituup_id;


--
-- TOC entry 221 (class 1259 OID 16969)
-- Name: riigid; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.riigid (
    riik_id integer NOT NULL,
    nimi character varying(50) NOT NULL
);


--
-- TOC entry 220 (class 1259 OID 16968)
-- Name: riigid_riik_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.riigid_riik_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 6061 (class 0 OID 0)
-- Dependencies: 220
-- Name: riigid_riik_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.riigid_riik_id_seq OWNED BY public.riigid.riik_id;


--
-- TOC entry 229 (class 1259 OID 17013)
-- Name: rollid; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rollid (
    roll_id integer NOT NULL,
    nimetus character varying(50) NOT NULL
);


--
-- TOC entry 228 (class 1259 OID 17012)
-- Name: rollid_roll_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rollid_roll_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 6062 (class 0 OID 0)
-- Dependencies: 228
-- Name: rollid_roll_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rollid_roll_id_seq OWNED BY public.rollid.roll_id;


--
-- TOC entry 225 (class 1259 OID 16991)
-- Name: staatused; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staatused (
    staatus_id integer NOT NULL,
    nimetus character varying(50) NOT NULL
);


--
-- TOC entry 224 (class 1259 OID 16990)
-- Name: staatused_staatus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.staatused_staatus_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 6063 (class 0 OID 0)
-- Dependencies: 224
-- Name: staatused_staatus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.staatused_staatus_id_seq OWNED BY public.staatused.staatus_id;


--
-- TOC entry 223 (class 1259 OID 16980)
-- Name: zanrid; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zanrid (
    zanr_id integer NOT NULL,
    nimetus character varying(50) NOT NULL
);


--
-- TOC entry 257 (class 1259 OID 18380)
-- Name: v_esinemised; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_esinemised AS
 SELECT festivalid.nimi AS festivali_nimi,
    lavad.nimi AS lava_nimi,
    kollektiivid.nimi AS kollektiiv,
    esinemised.algusaeg,
    esinemised.loppaeg,
    zanrid.nimetus AS zanr
   FROM ((((public.festivalid
     JOIN public.lavad ON ((lavad.festival_id = festivalid.festival_id)))
     JOIN public.esinemised ON ((esinemised.lava_id = lavad.lava_id)))
     JOIN public.kollektiivid ON ((esinemised.kollektiiv_id = kollektiivid.kollektiiv_id)))
     JOIN public.zanrid ON ((kollektiivid.zanr_id = zanrid.zanr_id)));


--
-- TOC entry 258 (class 1259 OID 18385)
-- Name: v_piletid; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_piletid AS
 SELECT piletituubid.nimetus AS pileti_tyyp,
    festivalid.nimi AS festivali_nimi,
    count(piletid.piletinumber) AS myydud_pileteid
   FROM ((public.piletituubid
     JOIN public.piletid ON ((piletid.piletituup_id = piletituubid.piletituup_id)))
     JOIN public.festivalid ON ((festivalid.festival_id = piletituubid.festival_id)))
  GROUP BY piletituubid.nimetus, festivalid.nimi;


--
-- TOC entry 222 (class 1259 OID 16979)
-- Name: zanrid_zanr_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.zanrid_zanr_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 6064 (class 0 OID 0)
-- Dependencies: 222
-- Name: zanrid_zanr_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.zanrid_zanr_id_seq OWNED BY public.zanrid.zanr_id;


--
-- TOC entry 5764 (class 2604 OID 18390)
-- Name: asukohad asukoht_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asukohad ALTER COLUMN asukoht_id SET DEFAULT nextval('public.asukohad_asukoht_id_seq'::regclass);


--
-- TOC entry 5772 (class 2604 OID 18391)
-- Name: esinemised esinemine_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.esinemised ALTER COLUMN esinemine_id SET DEFAULT nextval('public.esinemised_esinemine_id_seq'::regclass);


--
-- TOC entry 5767 (class 2604 OID 18392)
-- Name: festivalid festival_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.festivalid ALTER COLUMN festival_id SET DEFAULT nextval('public.festivalid_festival_id_seq'::regclass);


--
-- TOC entry 5765 (class 2604 OID 18393)
-- Name: isikud isik_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.isikud ALTER COLUMN isik_id SET DEFAULT nextval('public.isikud_isik_id_seq'::regclass);


--
-- TOC entry 5768 (class 2604 OID 18394)
-- Name: kollektiivid kollektiiv_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kollektiivid ALTER COLUMN kollektiiv_id SET DEFAULT nextval('public.kollektiivid_kollektiiv_id_seq'::regclass);


--
-- TOC entry 5769 (class 2604 OID 18395)
-- Name: lavad lava_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lavad ALTER COLUMN lava_id SET DEFAULT nextval('public.lavad_lava_id_seq'::regclass);


--
-- TOC entry 5771 (class 2604 OID 18396)
-- Name: muugikohad muugikoht_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.muugikohad ALTER COLUMN muugikoht_id SET DEFAULT nextval('public.muugikohad_muugikoht_id_seq'::regclass);


--
-- TOC entry 5766 (class 2604 OID 18397)
-- Name: muujad muuja_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.muujad ALTER COLUMN muuja_id SET DEFAULT nextval('public.muujad_muuja_id_seq'::regclass);


--
-- TOC entry 5762 (class 2604 OID 18398)
-- Name: peamised_kaubatuubid kaubatuup_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.peamised_kaubatuubid ALTER COLUMN kaubatuup_id SET DEFAULT nextval('public.peamised_kaubatuubid_kaubatuup_id_seq'::regclass);


--
-- TOC entry 5773 (class 2604 OID 18399)
-- Name: piletid pilet_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.piletid ALTER COLUMN pilet_id SET DEFAULT nextval('public.piletid_pilet_id_seq'::regclass);


--
-- TOC entry 5770 (class 2604 OID 18400)
-- Name: piletituubid piletituup_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.piletituubid ALTER COLUMN piletituup_id SET DEFAULT nextval('public.piletituubid_piletituup_id_seq'::regclass);


--
-- TOC entry 5759 (class 2604 OID 18401)
-- Name: riigid riik_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.riigid ALTER COLUMN riik_id SET DEFAULT nextval('public.riigid_riik_id_seq'::regclass);


--
-- TOC entry 5763 (class 2604 OID 18402)
-- Name: rollid roll_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rollid ALTER COLUMN roll_id SET DEFAULT nextval('public.rollid_roll_id_seq'::regclass);


--
-- TOC entry 5761 (class 2604 OID 18403)
-- Name: staatused staatus_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staatused ALTER COLUMN staatus_id SET DEFAULT nextval('public.staatused_staatus_id_seq'::regclass);


--
-- TOC entry 5760 (class 2604 OID 18404)
-- Name: zanrid zanr_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zanrid ALTER COLUMN zanr_id SET DEFAULT nextval('public.zanrid_zanr_id_seq'::regclass);


--
-- TOC entry 6023 (class 0 OID 18106)
-- Dependencies: 236
-- Data for Name: asukohad; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.asukohad VALUES (1, '0101000020E6100000B4C876BE9FBA3A40AAF1D24D62304D40', 'Pääväljak');
INSERT INTO public.asukohad VALUES (2, '0101000020E61000004260E5D022BB3A407F6ABC7493304D40', 'Põhilava ala');
INSERT INTO public.asukohad VALUES (3, '0101000020E61000000AD7A3703DBA3A40D578E92631304D40', 'Lõunalava ala');
INSERT INTO public.asukohad VALUES (4, '0101000020E6100000CFF753E3A5BB3A4054E3A59BC4304D40', 'Toiduala');
INSERT INTO public.asukohad VALUES (5, '0101000020E610000060E5D022DBB93A40F2D24D6210304D40', 'Kaubandusala');


--
-- TOC entry 6039 (class 0 OID 18268)
-- Dependencies: 252
-- Data for Name: esinemised; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.esinemised VALUES (1, 1, 1, '2025-07-10 18:00:00', '2025-07-10 19:30:00', '2x monitor, DI-box');
INSERT INTO public.esinemised VALUES (2, 1, 2, '2025-07-10 20:00:00', '2025-07-10 21:30:00', 'Akustiline seadistus');
INSERT INTO public.esinemised VALUES (3, 2, 3, '2025-07-11 15:00:00', '2025-07-11 16:00:00', 'DJ setup, 4x CDJ');
INSERT INTO public.esinemised VALUES (4, 4, 4, '2025-06-05 19:00:00', '2025-06-05 21:00:00', 'Jazzikomplekt, kontrabass mikk');
INSERT INTO public.esinemised VALUES (5, 5, 5, '2025-07-25 20:00:00', '2025-07-25 22:00:00', 'Full PA, LED riba');
INSERT INTO public.esinemised VALUES (6, 1, 2, '2025-07-12 18:00:00', '2025-07-12 19:30:00', '2 monitori, 6 DP kaablit');
INSERT INTO public.esinemised VALUES (7, 3, 4, '2025-08-01 12:00:00', '2025-08-01 13:00:00', 'Klaver');


--
-- TOC entry 6029 (class 0 OID 18146)
-- Dependencies: 242
-- Data for Name: festivalid; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.festivalid VALUES (1, 'Tartu Muusikafest 2025', '2025-07-10', '2025-07-13', 5000, 2);
INSERT INTO public.festivalid VALUES (2, 'Suvesound 2025', '2025-08-01', '2025-08-03', 3000, 1);
INSERT INTO public.festivalid VALUES (3, 'Jazzkaart 2025', '2025-06-05', '2025-06-08', 2000, 3);
INSERT INTO public.festivalid VALUES (4, 'RockRanda 2025', '2025-07-25', '2025-07-27', 8000, 1);
INSERT INTO public.festivalid VALUES (5, 'FolkFest 2025', '2025-09-12', '2025-09-14', 1500, 1);


--
-- TOC entry 6042 (class 0 OID 18314)
-- Dependencies: 255
-- Data for Name: isik_kollektiiv; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.isik_kollektiiv VALUES (1, 1);
INSERT INTO public.isik_kollektiiv VALUES (2, 1);
INSERT INTO public.isik_kollektiiv VALUES (3, 2);
INSERT INTO public.isik_kollektiiv VALUES (4, 3);
INSERT INTO public.isik_kollektiiv VALUES (5, 4);


--
-- TOC entry 6043 (class 0 OID 18338)
-- Dependencies: 256
-- Data for Name: isik_roll_festival; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.isik_roll_festival VALUES (1, 1, 1);
INSERT INTO public.isik_roll_festival VALUES (2, 2, 1);
INSERT INTO public.isik_roll_festival VALUES (3, 3, 2);
INSERT INTO public.isik_roll_festival VALUES (4, 4, 3);
INSERT INTO public.isik_roll_festival VALUES (5, 5, 4);


--
-- TOC entry 6025 (class 0 OID 18119)
-- Dependencies: 238
-- Data for Name: isikud; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.isikud VALUES (1, 'mari.tamm@email.ee', 'Mari', 'Tamm', '+372 5100 0001');
INSERT INTO public.isikud VALUES (2, 'jaan.sepp@email.ee', 'Jaan', 'Sepp', '+372 5100 0002');
INSERT INTO public.isikud VALUES (3, 'liis.kask@email.ee', 'Liis', 'Kask', '+372 5100 0003');
INSERT INTO public.isikud VALUES (4, 'peeter.magi@email.ee', 'Peeter', 'Mägi', '+372 5100 0004');
INSERT INTO public.isikud VALUES (5, 'anna.saar@email.ee', 'Anna', 'Saar', '+372 5100 0005');


--
-- TOC entry 6031 (class 0 OID 18166)
-- Dependencies: 244
-- Data for Name: kollektiivid; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.kollektiivid VALUES (1, 'Vanilla Sky', 1, 1);
INSERT INTO public.kollektiivid VALUES (2, 'Põhjanael', 1, 2);
INSERT INTO public.kollektiivid VALUES (3, 'Helsinki Beats', 2, 3);
INSERT INTO public.kollektiivid VALUES (4, 'Riga Jazz Quartet', 3, 4);
INSERT INTO public.kollektiivid VALUES (5, 'Stockholm Pop Co', 4, 5);


--
-- TOC entry 6033 (class 0 OID 18189)
-- Dependencies: 246
-- Data for Name: lavad; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.lavad VALUES (1, 1, 'Pealava', 2);
INSERT INTO public.lavad VALUES (2, 1, 'Kõrvallava', 3);
INSERT INTO public.lavad VALUES (3, 2, 'Pealava', 2);
INSERT INTO public.lavad VALUES (4, 3, 'Jazzilava', 3);
INSERT INTO public.lavad VALUES (5, 4, 'Rockilava', 2);


--
-- TOC entry 6037 (class 0 OID 18233)
-- Dependencies: 250
-- Data for Name: muugikohad; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.muugikohad VALUES (1, 1, 'Maitsev Nurk', 1, 1, 4);
INSERT INTO public.muugikohad VALUES (2, 1, 'Joogipunkt', 3, 2, 4);
INSERT INTO public.muugikohad VALUES (3, 2, 'FestFood lett', 4, 1, 4);
INSERT INTO public.muugikohad VALUES (4, 3, 'Suveniirilett', 5, 5, 5);
INSERT INTO public.muugikohad VALUES (5, 4, 'Käsitööturg', 2, 3, 5);


--
-- TOC entry 6027 (class 0 OID 18132)
-- Dependencies: 240
-- Data for Name: muujad; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.muujad VALUES (1, '10001001', 'Maitsev OÜ', 'tel: +372 600 1001');
INSERT INTO public.muujad VALUES (2, '10001002', 'Käsitöömaja AS', 'tel: +372 600 1002');
INSERT INTO public.muujad VALUES (3, '10001003', 'Joogi & Ko OÜ', 'tel: +372 600 1003');
INSERT INTO public.muujad VALUES (4, '10001004', 'FestFood OÜ', 'tel: +372 600 1004');
INSERT INTO public.muujad VALUES (5, '10001005', 'Souvenir Est OÜ', 'tel: +372 600 1005');


--
-- TOC entry 6019 (class 0 OID 17002)
-- Dependencies: 227
-- Data for Name: peamised_kaubatuubid; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.peamised_kaubatuubid VALUES (1, 'Toit');
INSERT INTO public.peamised_kaubatuubid VALUES (2, 'Jook');
INSERT INTO public.peamised_kaubatuubid VALUES (3, 'Käsitöö');
INSERT INTO public.peamised_kaubatuubid VALUES (4, 'Riided');
INSERT INTO public.peamised_kaubatuubid VALUES (5, 'Suveniirid');


--
-- TOC entry 6041 (class 0 OID 18292)
-- Dependencies: 254
-- Data for Name: piletid; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.piletid VALUES (1, 'TM2025-0001', 1, 1);
INSERT INTO public.piletid VALUES (2, 'TM2025-0002', 2, 2);
INSERT INTO public.piletid VALUES (3, 'SS2025-0001', 3, 3);
INSERT INTO public.piletid VALUES (4, 'JZ2025-0001', 4, 4);
INSERT INTO public.piletid VALUES (5, 'RR2025-0001', 5, 5);
INSERT INTO public.piletid VALUES (6, 'TM2025-0099', 1, 3);
INSERT INTO public.piletid VALUES (7, 'TM2025-0100', 1, 5);


--
-- TOC entry 6035 (class 0 OID 18212)
-- Dependencies: 248
-- Data for Name: piletituubid; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.piletituubid VALUES (1, 1, 'Päevapilet', 35.00, '2025-05-01 00:00:00', '2025-07-10 23:59:00', 'Kehtib 1 päev');
INSERT INTO public.piletituubid VALUES (2, 1, 'Festivalipass', 89.00, '2025-05-01 00:00:00', '2025-07-13 23:59:00', 'Kehtib kogu festival');
INSERT INTO public.piletituubid VALUES (3, 2, 'Päevapilet', 25.00, '2025-06-01 00:00:00', '2025-08-03 23:59:00', NULL);
INSERT INTO public.piletituubid VALUES (4, 3, 'VIP-pilet', 120.00, '2025-04-01 00:00:00', '2025-06-08 23:59:00', 'VIP ala ligipääs');
INSERT INTO public.piletituubid VALUES (5, 4, 'Noortepilet', 20.00, '2025-06-01 00:00:00', '2025-07-27 23:59:00', 'Kuni 18a');


--
-- TOC entry 6013 (class 0 OID 16969)
-- Dependencies: 221
-- Data for Name: riigid; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.riigid VALUES (1, 'Eesti');
INSERT INTO public.riigid VALUES (2, 'Soome');
INSERT INTO public.riigid VALUES (3, 'Läti');
INSERT INTO public.riigid VALUES (4, 'Rootsi');
INSERT INTO public.riigid VALUES (5, 'Saksamaa');


--
-- TOC entry 6021 (class 0 OID 17013)
-- Dependencies: 229
-- Data for Name: rollid; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.rollid VALUES (1, 'Korraldaja');
INSERT INTO public.rollid VALUES (2, 'Vabatahtlik');
INSERT INTO public.rollid VALUES (3, 'Turvapersonal');
INSERT INTO public.rollid VALUES (4, 'Tehnik');
INSERT INTO public.rollid VALUES (5, 'Meedia');


--
-- TOC entry 5758 (class 0 OID 17342)
-- Dependencies: 231
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 6017 (class 0 OID 16991)
-- Dependencies: 225
-- Data for Name: staatused; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.staatused VALUES (1, 'Planeeritud');
INSERT INTO public.staatused VALUES (2, 'Aktiivne');
INSERT INTO public.staatused VALUES (3, 'Lõppenud');
INSERT INTO public.staatused VALUES (4, 'Tühistatud');
INSERT INTO public.staatused VALUES (5, 'Ootel');


--
-- TOC entry 6015 (class 0 OID 16980)
-- Dependencies: 223
-- Data for Name: zanrid; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.zanrid VALUES (1, 'Rock');
INSERT INTO public.zanrid VALUES (2, 'Folk');
INSERT INTO public.zanrid VALUES (3, 'Elektrooniline');
INSERT INTO public.zanrid VALUES (4, 'Jazz');
INSERT INTO public.zanrid VALUES (5, 'Pop');


--
-- TOC entry 6065 (class 0 OID 0)
-- Dependencies: 235
-- Name: asukohad_asukoht_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.asukohad_asukoht_id_seq', 5, true);


--
-- TOC entry 6066 (class 0 OID 0)
-- Dependencies: 251
-- Name: esinemised_esinemine_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.esinemised_esinemine_id_seq', 7, true);


--
-- TOC entry 6067 (class 0 OID 0)
-- Dependencies: 241
-- Name: festivalid_festival_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.festivalid_festival_id_seq', 5, true);


--
-- TOC entry 6068 (class 0 OID 0)
-- Dependencies: 237
-- Name: isikud_isik_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.isikud_isik_id_seq', 5, true);


--
-- TOC entry 6069 (class 0 OID 0)
-- Dependencies: 243
-- Name: kollektiivid_kollektiiv_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.kollektiivid_kollektiiv_id_seq', 5, true);


--
-- TOC entry 6070 (class 0 OID 0)
-- Dependencies: 245
-- Name: lavad_lava_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.lavad_lava_id_seq', 5, true);


--
-- TOC entry 6071 (class 0 OID 0)
-- Dependencies: 249
-- Name: muugikohad_muugikoht_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.muugikohad_muugikoht_id_seq', 5, true);


--
-- TOC entry 6072 (class 0 OID 0)
-- Dependencies: 239
-- Name: muujad_muuja_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.muujad_muuja_id_seq', 5, true);


--
-- TOC entry 6073 (class 0 OID 0)
-- Dependencies: 226
-- Name: peamised_kaubatuubid_kaubatuup_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.peamised_kaubatuubid_kaubatuup_id_seq', 5, true);


--
-- TOC entry 6074 (class 0 OID 0)
-- Dependencies: 253
-- Name: piletid_pilet_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.piletid_pilet_id_seq', 7, true);


--
-- TOC entry 6075 (class 0 OID 0)
-- Dependencies: 247
-- Name: piletituubid_piletituup_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.piletituubid_piletituup_id_seq', 5, true);


--
-- TOC entry 6076 (class 0 OID 0)
-- Dependencies: 220
-- Name: riigid_riik_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.riigid_riik_id_seq', 5, true);


--
-- TOC entry 6077 (class 0 OID 0)
-- Dependencies: 228
-- Name: rollid_roll_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.rollid_roll_id_seq', 5, true);


--
-- TOC entry 6078 (class 0 OID 0)
-- Dependencies: 224
-- Name: staatused_staatus_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.staatused_staatus_id_seq', 5, true);


--
-- TOC entry 6079 (class 0 OID 0)
-- Dependencies: 222
-- Name: zanrid_zanr_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.zanrid_zanr_id_seq', 5, true);


--
-- TOC entry 5798 (class 2606 OID 18117)
-- Name: asukohad asukohad_koordinaadid_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asukohad
    ADD CONSTRAINT asukohad_koordinaadid_key UNIQUE (koordinaadid);


--
-- TOC entry 5800 (class 2606 OID 18115)
-- Name: asukohad asukohad_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asukohad
    ADD CONSTRAINT asukohad_pkey PRIMARY KEY (asukoht_id);


--
-- TOC entry 5830 (class 2606 OID 18280)
-- Name: esinemised esinemised_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.esinemised
    ADD CONSTRAINT esinemised_pkey PRIMARY KEY (esinemine_id);


--
-- TOC entry 5810 (class 2606 OID 18159)
-- Name: festivalid festivalid_nimi_algus_kuupaev_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.festivalid
    ADD CONSTRAINT festivalid_nimi_algus_kuupaev_key UNIQUE (nimi, algus_kuupaev);


--
-- TOC entry 5812 (class 2606 OID 18157)
-- Name: festivalid festivalid_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.festivalid
    ADD CONSTRAINT festivalid_pkey PRIMARY KEY (festival_id);


--
-- TOC entry 5836 (class 2606 OID 18320)
-- Name: isik_kollektiiv isik_kollektiiv_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.isik_kollektiiv
    ADD CONSTRAINT isik_kollektiiv_pkey PRIMARY KEY (isik_id, kollektiiv_id);


--
-- TOC entry 5838 (class 2606 OID 18345)
-- Name: isik_roll_festival isik_roll_festival_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.isik_roll_festival
    ADD CONSTRAINT isik_roll_festival_pkey PRIMARY KEY (isik_id, roll_id, festival_id);


--
-- TOC entry 5802 (class 2606 OID 18130)
-- Name: isikud isikud_meil_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.isikud
    ADD CONSTRAINT isikud_meil_key UNIQUE (meil);


--
-- TOC entry 5804 (class 2606 OID 18128)
-- Name: isikud isikud_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.isikud
    ADD CONSTRAINT isikud_pkey PRIMARY KEY (isik_id);


--
-- TOC entry 5814 (class 2606 OID 18177)
-- Name: kollektiivid kollektiivid_nimi_riik_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kollektiivid
    ADD CONSTRAINT kollektiivid_nimi_riik_id_key UNIQUE (nimi, riik_id);


--
-- TOC entry 5816 (class 2606 OID 18175)
-- Name: kollektiivid kollektiivid_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kollektiivid
    ADD CONSTRAINT kollektiivid_pkey PRIMARY KEY (kollektiiv_id);


--
-- TOC entry 5818 (class 2606 OID 18200)
-- Name: lavad lavad_festival_id_nimi_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lavad
    ADD CONSTRAINT lavad_festival_id_nimi_key UNIQUE (festival_id, nimi);


--
-- TOC entry 5820 (class 2606 OID 18198)
-- Name: lavad lavad_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lavad
    ADD CONSTRAINT lavad_pkey PRIMARY KEY (lava_id);


--
-- TOC entry 5826 (class 2606 OID 18246)
-- Name: muugikohad muugikohad_festival_id_nimi_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.muugikohad
    ADD CONSTRAINT muugikohad_festival_id_nimi_key UNIQUE (festival_id, nimi);


--
-- TOC entry 5828 (class 2606 OID 18244)
-- Name: muugikohad muugikohad_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.muugikohad
    ADD CONSTRAINT muugikohad_pkey PRIMARY KEY (muugikoht_id);


--
-- TOC entry 5806 (class 2606 OID 18142)
-- Name: muujad muujad_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.muujad
    ADD CONSTRAINT muujad_pkey PRIMARY KEY (muuja_id);


--
-- TOC entry 5808 (class 2606 OID 18144)
-- Name: muujad muujad_reg_kood_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.muujad
    ADD CONSTRAINT muujad_reg_kood_key UNIQUE (reg_kood);


--
-- TOC entry 5788 (class 2606 OID 17011)
-- Name: peamised_kaubatuubid peamised_kaubatuubid_nimetus_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.peamised_kaubatuubid
    ADD CONSTRAINT peamised_kaubatuubid_nimetus_key UNIQUE (nimetus);


--
-- TOC entry 5790 (class 2606 OID 17009)
-- Name: peamised_kaubatuubid peamised_kaubatuubid_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.peamised_kaubatuubid
    ADD CONSTRAINT peamised_kaubatuubid_pkey PRIMARY KEY (kaubatuup_id);


--
-- TOC entry 5832 (class 2606 OID 18303)
-- Name: piletid piletid_piletinumber_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.piletid
    ADD CONSTRAINT piletid_piletinumber_key UNIQUE (piletinumber);


--
-- TOC entry 5834 (class 2606 OID 18301)
-- Name: piletid piletid_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.piletid
    ADD CONSTRAINT piletid_pkey PRIMARY KEY (pilet_id);


--
-- TOC entry 5822 (class 2606 OID 18226)
-- Name: piletituubid piletituubid_festival_id_nimetus_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.piletituubid
    ADD CONSTRAINT piletituubid_festival_id_nimetus_key UNIQUE (festival_id, nimetus);


--
-- TOC entry 5824 (class 2606 OID 18224)
-- Name: piletituubid piletituubid_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.piletituubid
    ADD CONSTRAINT piletituubid_pkey PRIMARY KEY (piletituup_id);


--
-- TOC entry 5776 (class 2606 OID 16978)
-- Name: riigid riigid_nimi_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.riigid
    ADD CONSTRAINT riigid_nimi_key UNIQUE (nimi);


--
-- TOC entry 5778 (class 2606 OID 16976)
-- Name: riigid riigid_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.riigid
    ADD CONSTRAINT riigid_pkey PRIMARY KEY (riik_id);


--
-- TOC entry 5792 (class 2606 OID 17022)
-- Name: rollid rollid_nimetus_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rollid
    ADD CONSTRAINT rollid_nimetus_key UNIQUE (nimetus);


--
-- TOC entry 5794 (class 2606 OID 17020)
-- Name: rollid rollid_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rollid
    ADD CONSTRAINT rollid_pkey PRIMARY KEY (roll_id);


--
-- TOC entry 5784 (class 2606 OID 17000)
-- Name: staatused staatused_nimetus_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staatused
    ADD CONSTRAINT staatused_nimetus_key UNIQUE (nimetus);


--
-- TOC entry 5786 (class 2606 OID 16998)
-- Name: staatused staatused_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staatused
    ADD CONSTRAINT staatused_pkey PRIMARY KEY (staatus_id);


--
-- TOC entry 5780 (class 2606 OID 16989)
-- Name: zanrid zanrid_nimetus_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zanrid
    ADD CONSTRAINT zanrid_nimetus_key UNIQUE (nimetus);


--
-- TOC entry 5782 (class 2606 OID 16987)
-- Name: zanrid zanrid_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zanrid
    ADD CONSTRAINT zanrid_pkey PRIMARY KEY (zanr_id);


--
-- TOC entry 5849 (class 2606 OID 18286)
-- Name: esinemised esinemised_kollektiiv_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.esinemised
    ADD CONSTRAINT esinemised_kollektiiv_id_fkey FOREIGN KEY (kollektiiv_id) REFERENCES public.kollektiivid(kollektiiv_id);


--
-- TOC entry 5850 (class 2606 OID 18281)
-- Name: esinemised esinemised_lava_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.esinemised
    ADD CONSTRAINT esinemised_lava_id_fkey FOREIGN KEY (lava_id) REFERENCES public.lavad(lava_id);


--
-- TOC entry 5839 (class 2606 OID 18160)
-- Name: festivalid festivalid_staatus_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.festivalid
    ADD CONSTRAINT festivalid_staatus_id_fkey FOREIGN KEY (staatus_id) REFERENCES public.staatused(staatus_id);


--
-- TOC entry 5853 (class 2606 OID 18321)
-- Name: isik_kollektiiv isik_kollektiiv_isik_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.isik_kollektiiv
    ADD CONSTRAINT isik_kollektiiv_isik_id_fkey FOREIGN KEY (isik_id) REFERENCES public.isikud(isik_id);


--
-- TOC entry 5854 (class 2606 OID 18326)
-- Name: isik_kollektiiv isik_kollektiiv_kollektiiv_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.isik_kollektiiv
    ADD CONSTRAINT isik_kollektiiv_kollektiiv_id_fkey FOREIGN KEY (kollektiiv_id) REFERENCES public.kollektiivid(kollektiiv_id);


--
-- TOC entry 5855 (class 2606 OID 18356)
-- Name: isik_roll_festival isik_roll_festival_festival_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.isik_roll_festival
    ADD CONSTRAINT isik_roll_festival_festival_id_fkey FOREIGN KEY (festival_id) REFERENCES public.festivalid(festival_id);


--
-- TOC entry 5856 (class 2606 OID 18346)
-- Name: isik_roll_festival isik_roll_festival_isik_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.isik_roll_festival
    ADD CONSTRAINT isik_roll_festival_isik_id_fkey FOREIGN KEY (isik_id) REFERENCES public.isikud(isik_id);


--
-- TOC entry 5857 (class 2606 OID 18351)
-- Name: isik_roll_festival isik_roll_festival_roll_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.isik_roll_festival
    ADD CONSTRAINT isik_roll_festival_roll_id_fkey FOREIGN KEY (roll_id) REFERENCES public.rollid(roll_id);


--
-- TOC entry 5840 (class 2606 OID 18178)
-- Name: kollektiivid kollektiivid_riik_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kollektiivid
    ADD CONSTRAINT kollektiivid_riik_id_fkey FOREIGN KEY (riik_id) REFERENCES public.riigid(riik_id);


--
-- TOC entry 5841 (class 2606 OID 18183)
-- Name: kollektiivid kollektiivid_zanr_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kollektiivid
    ADD CONSTRAINT kollektiivid_zanr_id_fkey FOREIGN KEY (zanr_id) REFERENCES public.zanrid(zanr_id);


--
-- TOC entry 5842 (class 2606 OID 18206)
-- Name: lavad lavad_asukoht_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lavad
    ADD CONSTRAINT lavad_asukoht_id_fkey FOREIGN KEY (asukoht_id) REFERENCES public.asukohad(asukoht_id);


--
-- TOC entry 5843 (class 2606 OID 18201)
-- Name: lavad lavad_festival_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lavad
    ADD CONSTRAINT lavad_festival_id_fkey FOREIGN KEY (festival_id) REFERENCES public.festivalid(festival_id);


--
-- TOC entry 5845 (class 2606 OID 18262)
-- Name: muugikohad muugikohad_asukoht_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.muugikohad
    ADD CONSTRAINT muugikohad_asukoht_id_fkey FOREIGN KEY (asukoht_id) REFERENCES public.asukohad(asukoht_id);


--
-- TOC entry 5846 (class 2606 OID 18247)
-- Name: muugikohad muugikohad_festival_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.muugikohad
    ADD CONSTRAINT muugikohad_festival_id_fkey FOREIGN KEY (festival_id) REFERENCES public.festivalid(festival_id);


--
-- TOC entry 5847 (class 2606 OID 18257)
-- Name: muugikohad muugikohad_kaubatuup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.muugikohad
    ADD CONSTRAINT muugikohad_kaubatuup_id_fkey FOREIGN KEY (kaubatuup_id) REFERENCES public.peamised_kaubatuubid(kaubatuup_id);


--
-- TOC entry 5848 (class 2606 OID 18252)
-- Name: muugikohad muugikohad_muuja_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.muugikohad
    ADD CONSTRAINT muugikohad_muuja_id_fkey FOREIGN KEY (muuja_id) REFERENCES public.muujad(muuja_id);


--
-- TOC entry 5851 (class 2606 OID 18309)
-- Name: piletid piletid_isik_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.piletid
    ADD CONSTRAINT piletid_isik_id_fkey FOREIGN KEY (isik_id) REFERENCES public.isikud(isik_id);


--
-- TOC entry 5852 (class 2606 OID 18304)
-- Name: piletid piletid_piletituup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.piletid
    ADD CONSTRAINT piletid_piletituup_id_fkey FOREIGN KEY (piletituup_id) REFERENCES public.piletituubid(piletituup_id);


--
-- TOC entry 5844 (class 2606 OID 18227)
-- Name: piletituubid piletituubid_festival_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.piletituubid
    ADD CONSTRAINT piletituubid_festival_id_fkey FOREIGN KEY (festival_id) REFERENCES public.festivalid(festival_id);


-- Completed on 2026-05-10 17:39:31

--
-- PostgreSQL database dump complete
--

\unrestrict abWuOstBq298TvUnimqkyHtSd3ymdpm7pioZrHFkcs1NbNEVfeXVCMVotRLtId1

