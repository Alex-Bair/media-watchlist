--
-- PostgreSQL database dump
--

-- Dumped from database version 9.2.24
-- Dumped by pg_dump version 9.6.24

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: media; Type: TABLE; Schema: public; Owner: ec2-user
--

CREATE TABLE public.media (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    platform character varying(60) NOT NULL,
    url text,
    watchlist_id integer NOT NULL
);


ALTER TABLE public.media OWNER TO "ec2-user";

--
-- Name: media_id_seq; Type: SEQUENCE; Schema: public; Owner: ec2-user
--

CREATE SEQUENCE public.media_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.media_id_seq OWNER TO "ec2-user";

--
-- Name: media_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ec2-user
--

ALTER SEQUENCE public.media_id_seq OWNED BY public.media.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: ec2-user
--

CREATE TABLE public.users (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    password text NOT NULL
);


ALTER TABLE public.users OWNER TO "ec2-user";

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: ec2-user
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO "ec2-user";

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ec2-user
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: watchlists; Type: TABLE; Schema: public; Owner: ec2-user
--

CREATE TABLE public.watchlists (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE public.watchlists OWNER TO "ec2-user";

--
-- Name: watchlists_id_seq; Type: SEQUENCE; Schema: public; Owner: ec2-user
--

CREATE SEQUENCE public.watchlists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.watchlists_id_seq OWNER TO "ec2-user";

--
-- Name: watchlists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ec2-user
--

ALTER SEQUENCE public.watchlists_id_seq OWNED BY public.watchlists.id;


--
-- Name: media id; Type: DEFAULT; Schema: public; Owner: ec2-user
--

ALTER TABLE ONLY public.media ALTER COLUMN id SET DEFAULT nextval('public.media_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: ec2-user
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: watchlists id; Type: DEFAULT; Schema: public; Owner: ec2-user
--

ALTER TABLE ONLY public.watchlists ALTER COLUMN id SET DEFAULT nextval('public.watchlists_id_seq'::regclass);


--
-- Data for Name: media; Type: TABLE DATA; Schema: public; Owner: ec2-user
--

COPY public.media (id, name, platform, url, watchlist_id) FROM stdin;
1	3 Fitness Tips that are NOT So Helpful - PictureFit	YouTube	https://www.youtube.com/watch?v=l93XQBRlOL4&ab_channel=PictureFit	1
2	Protein Bar Review - LBP	Youtube	https://www.youtube.com/watch?v=tluGFwwAgfs&ab_channel=LeanBeefPatty	1
3	Progressive Overload - PictureFit	Youtube	https://www.youtube.com/watch?v=HiJ1uLuTNxo&ab_channel=PictureFit	1
4	FFXIV OST - Athena, The Tireless One	YouTube	https://www.youtube.com/watch?v=pKt0Gpx6NFo&ab_channel=dudewhereismyspoon	2
5	Pokemon TCG OST	YouTube	https://www.youtube.com/watch?v=YP4uFEmNQTw&ab_channel=RareOSTs	2
6	Sada/Turo Battle - Retro Remix	YouTube	https://www.youtube.com/watch?v=U92u5E2xZWs&ab_channel=MissCardiac	2
7	Famitracker G/S/C Rival Battle	YouTube	https://www.youtube.com/watch?v=mdruJyio-fw&ab_channel=AtomicJosuke	2
8	Arnold Palmer Tournament Golf - BGM 4	YouTube	https://www.youtube.com/watch?v=B0k-plfOBxw&ab_channel=DendyLegend-RetroGameMusicandSoundtrack	2
9	I Really Want to Stay at Your House - SilvaGunner	YouTube	https://www.youtube.com/watch?v=k0MY6MDrkgY&ab_channel=SiIvaGunner	2
10	Japanese Denim	YouTube	https://www.youtube.com/watch?v=FG2PgVl0Nlc&ab_channel=Beautiful.co.il	2
11	the end - KFAD - SilvaGunner	YouTube	https://www.youtube.com/watch?v=GydXuedDTnQ&ab_channel=SiIvaGunner	2
12	Moonlight Serendipity - SilvaGunner	YouTube	https://www.youtube.com/watch?v=9jq0X2CF-vA&ab_channel=SiIvaGunner	2
13	Finally Speedrunning - SilvaGunner	YouTube	https://www.youtube.com/watch?v=XRr5GMdZsZM&ab_channel=SiIvaGunner	2
14	Those Who Fight	YouTube	https://www.youtube.com/watch?v=n_1Bb-4aGq8&ab_channel=Cateen%E3%81%8B%E3%81%A6%E3%81%83%E3%82%93	2
15	FE3H - God Shattering Star	YouTube	https://www.youtube.com/watch?v=fhWhTbe3MWk&ab_channel=FamilyJules	2
16	Pop Culture	YouTube	https://www.youtube.com/watch?v=lTx3G6h2xyA&ab_channel=Madeon	2
17	Shelter	YouTube	https://www.youtube.com/watch?v=fzQ6gRAEoy0&ab_channel=PorterRobinson	2
18	dullscythe	YouTube	https://www.youtube.com/watch?v=oKMNj8v2gKE&ab_channel=PorterRobinson	2
19	Revolving	YouTube	https://www.youtube.com/watch?v=f6fmuegxGO0&ab_channel=YUNGBAE	2
20	It just is	YouTube	https://www.youtube.com/watch?v=oBpaB2YzX8s&ab_channel=eaJ	2
21	snow-fi hip hop beats to halate to - SilvaGunner	YouTube	https://www.youtube.com/watch?v=LXQAMOd3Kww&ab_channel=SiIvaGunner	2
22	Appalachian Snow - SilvaGunner	YouTube	https://www.youtube.com/watch?v=OTu6FaJAy9g&ab_channel=SiIvaGunner	2
23	Neath Dark Waters & Rain	YouTube	https://www.youtube.com/watch?v=EcRubiF1TvI&ab_channel=JaxomNautilus	2
24	Neath Dark Waters Lo-fi	YouTube	https://www.youtube.com/watch?v=qyupzA-JacA&ab_channel=Dutyyaknow	2
25	Smile Bomb/Gurenge/Giorno's Theme	YouTube	https://www.youtube.com/watch?v=UN4m-UgmxtM&ab_channel=J-MUSICEnsemble	2
26	Tortilla Chip Sombrero - Babish	YouTube	https://www.youtube.com/watch?v=D_Y18GEjfNY&ab_channel=BabishCulinaryUniverse	3
27	BBQ Showdown	Netflix	https://www.netflix.com/watch/81496341	3
28	Great British Bakeoff	Netflix	https://www.netflix.com/watch/81608912	3
29	Dr. Seuess Baking Challenge	Amazon Prime Video	https://www.amazon.com/gp/video/detail/B0B6RD7QCN	3
\.


--
-- Name: media_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ec2-user
--

SELECT pg_catalog.setval('public.media_id_seq', 29, true);


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: ec2-user
--

COPY public.users (id, name, password) FROM stdin;
1	admin	$2a$12$Bc/jfIa6Hu7xBhHerpUp7enJS446Y5KM7yXxixOjwwczip3IvpeJC
\.


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ec2-user
--

SELECT pg_catalog.setval('public.users_id_seq', 1, true);


--
-- Data for Name: watchlists; Type: TABLE DATA; Schema: public; Owner: ec2-user
--

COPY public.watchlists (id, name, user_id) FROM stdin;
1	Fitness	1
2	Music	1
3	Cooking	1
4	Rewatch	1
5	Watch with Family	1
6	Watch with Friends	1
7	Anime	1
8	Documentaries	1
9	Horror	1
10	Romance	1
11	Comedy	1
\.


--
-- Name: watchlists_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ec2-user
--

SELECT pg_catalog.setval('public.watchlists_id_seq', 11, true);


--
-- Name: media media_pkey; Type: CONSTRAINT; Schema: public; Owner: ec2-user
--

ALTER TABLE ONLY public.media
    ADD CONSTRAINT media_pkey PRIMARY KEY (id);


--
-- Name: users users_name_key; Type: CONSTRAINT; Schema: public; Owner: ec2-user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_name_key UNIQUE (name);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: ec2-user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: watchlists watchlists_name_key; Type: CONSTRAINT; Schema: public; Owner: ec2-user
--

ALTER TABLE ONLY public.watchlists
    ADD CONSTRAINT watchlists_name_key UNIQUE (name);


--
-- Name: watchlists watchlists_pkey; Type: CONSTRAINT; Schema: public; Owner: ec2-user
--

ALTER TABLE ONLY public.watchlists
    ADD CONSTRAINT watchlists_pkey PRIMARY KEY (id);


--
-- Name: media media_watchlist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ec2-user
--

ALTER TABLE ONLY public.media
    ADD CONSTRAINT media_watchlist_id_fkey FOREIGN KEY (watchlist_id) REFERENCES public.watchlists(id) ON DELETE CASCADE;


--
-- Name: watchlists watchlists_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ec2-user
--

ALTER TABLE ONLY public.watchlists
    ADD CONSTRAINT watchlists_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

