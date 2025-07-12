--
-- PostgreSQL database dump
--

-- Dumped from database version 14.13 (Ubuntu 14.13-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 16.8 (Ubuntu 16.8-0ubuntu0.24.04.1)

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
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: buses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.buses (
    id bigint NOT NULL,
    number character varying(255),
    capacity integer,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    route_id bigint,
    CONSTRAINT capacity_must_be_positive CHECK ((capacity > 0))
);


--
-- Name: buses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.buses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: buses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.buses_id_seq OWNED BY public.buses.id;


--
-- Name: cashing_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cashing_reports (
    id bigint NOT NULL,
    days_worked integer,
    expected_cashing numeric,
    received_cashing numeric,
    airtel_id character varying(255),
    debt_balance numeric,
    expenditure numeric,
    description text,
    report_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    CONSTRAINT expected_cashing_must_be_positive CHECK ((expected_cashing >= (0)::numeric)),
    CONSTRAINT expenditure_must_be_positive CHECK ((expenditure >= (0)::numeric)),
    CONSTRAINT received_cashing_must_be_positive CHECK ((received_cashing >= (0)::numeric))
);


--
-- Name: cashing_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cashing_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cashing_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cashing_reports_id_seq OWNED BY public.cashing_reports.id;


--
-- Name: expenditures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.expenditures (
    id bigint NOT NULL,
    amount numeric,
    description text,
    cashing_report_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    date timestamp(0) without time zone,
    CONSTRAINT amount_must_be_positive CHECK ((amount >= (0)::numeric))
);


--
-- Name: expenditures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.expenditures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: expenditures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.expenditures_id_seq OWNED BY public.expenditures.id;


--
-- Name: routes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.routes (
    id bigint NOT NULL,
    name character varying(255),
    start_point character varying(255),
    end_point character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: routes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.routes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: routes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.routes_id_seq OWNED BY public.routes.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transactions (
    id bigint NOT NULL,
    amount numeric,
    type character varying(255),
    user_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    CONSTRAINT amount_must_be_positive CHECK ((amount > (0)::numeric))
);


--
-- Name: transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transactions_id_seq OWNED BY public.transactions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    name character varying(255),
    email character varying(255),
    role character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: weekly_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.weekly_reports (
    id bigint NOT NULL,
    start_date date,
    end_date date,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: weekly_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.weekly_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: weekly_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.weekly_reports_id_seq OWNED BY public.weekly_reports.id;


--
-- Name: buses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.buses ALTER COLUMN id SET DEFAULT nextval('public.buses_id_seq'::regclass);


--
-- Name: cashing_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cashing_reports ALTER COLUMN id SET DEFAULT nextval('public.cashing_reports_id_seq'::regclass);


--
-- Name: expenditures id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenditures ALTER COLUMN id SET DEFAULT nextval('public.expenditures_id_seq'::regclass);


--
-- Name: routes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.routes ALTER COLUMN id SET DEFAULT nextval('public.routes_id_seq'::regclass);


--
-- Name: transactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions ALTER COLUMN id SET DEFAULT nextval('public.transactions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: weekly_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weekly_reports ALTER COLUMN id SET DEFAULT nextval('public.weekly_reports_id_seq'::regclass);


--
-- Name: buses buses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.buses
    ADD CONSTRAINT buses_pkey PRIMARY KEY (id);


--
-- Name: cashing_reports cashing_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cashing_reports
    ADD CONSTRAINT cashing_reports_pkey PRIMARY KEY (id);


--
-- Name: expenditures expenditures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenditures
    ADD CONSTRAINT expenditures_pkey PRIMARY KEY (id);


--
-- Name: routes routes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.routes
    ADD CONSTRAINT routes_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: weekly_reports weekly_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weekly_reports
    ADD CONSTRAINT weekly_reports_pkey PRIMARY KEY (id);


--
-- Name: buses_number_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX buses_number_index ON public.buses USING btree (number);


--
-- Name: buses_route_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX buses_route_id_index ON public.buses USING btree (route_id);


--
-- Name: cashing_reports_airtel_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cashing_reports_airtel_id_index ON public.cashing_reports USING btree (airtel_id);


--
-- Name: cashing_reports_report_id_days_worked_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cashing_reports_report_id_days_worked_index ON public.cashing_reports USING btree (report_id, days_worked);


--
-- Name: cashing_reports_report_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cashing_reports_report_id_index ON public.cashing_reports USING btree (report_id);


--
-- Name: expenditures_cashing_report_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX expenditures_cashing_report_id_index ON public.expenditures USING btree (cashing_report_id);


--
-- Name: expenditures_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX expenditures_date_index ON public.expenditures USING btree (date);


--
-- Name: routes_end_point_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX routes_end_point_index ON public.routes USING btree (end_point);


--
-- Name: routes_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX routes_name_index ON public.routes USING btree (name);


--
-- Name: routes_start_point_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX routes_start_point_index ON public.routes USING btree (start_point);


--
-- Name: transactions_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX transactions_user_id_index ON public.transactions USING btree (user_id);


--
-- Name: transactions_user_id_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX transactions_user_id_type_index ON public.transactions USING btree (user_id, type);


--
-- Name: users_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_email_index ON public.users USING btree (email);


--
-- Name: users_role_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_role_index ON public.users USING btree (role);


--
-- Name: buses buses_route_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.buses
    ADD CONSTRAINT buses_route_id_fkey FOREIGN KEY (route_id) REFERENCES public.routes(id) ON DELETE SET NULL;


--
-- Name: cashing_reports cashing_reports_report_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cashing_reports
    ADD CONSTRAINT cashing_reports_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.weekly_reports(id) ON DELETE CASCADE;


--
-- Name: expenditures expenditures_cashing_report_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenditures
    ADD CONSTRAINT expenditures_cashing_report_id_fkey FOREIGN KEY (cashing_report_id) REFERENCES public.cashing_reports(id) ON DELETE CASCADE;


--
-- Name: transactions transactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

INSERT INTO public."schema_migrations" (version) VALUES (20250304090359);
INSERT INTO public."schema_migrations" (version) VALUES (20250304090400);
INSERT INTO public."schema_migrations" (version) VALUES (20250304090402);
INSERT INTO public."schema_migrations" (version) VALUES (20250304090403);
INSERT INTO public."schema_migrations" (version) VALUES (20250304100202);
INSERT INTO public."schema_migrations" (version) VALUES (20250304100235);
INSERT INTO public."schema_migrations" (version) VALUES (20250304100256);
INSERT INTO public."schema_migrations" (version) VALUES (20250406041551);
INSERT INTO public."schema_migrations" (version) VALUES (20250412030506);
INSERT INTO public."schema_migrations" (version) VALUES (20250412030720);
