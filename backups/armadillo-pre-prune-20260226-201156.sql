--
-- PostgreSQL database dump
--

\restrict uxewfyAZLcE7B93bjVHpvZgbfu0ncVazG1PQgdKyyM7VN6W6r1BhPM6dOi3bQ7n

-- Dumped from database version 16.12
-- Dumped by pg_dump version 16.12

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
-- Name: ScanStatus; Type: TYPE; Schema: public; Owner: armadillo
--

CREATE TYPE public."ScanStatus" AS ENUM (
    'queued',
    'running',
    'completed',
    'failed'
);


ALTER TYPE public."ScanStatus" OWNER TO armadillo;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: _prisma_migrations; Type: TABLE; Schema: public; Owner: armadillo
--

CREATE TABLE public._prisma_migrations (
    id character varying(36) NOT NULL,
    checksum character varying(64) NOT NULL,
    finished_at timestamp with time zone,
    migration_name character varying(255) NOT NULL,
    logs text,
    rolled_back_at timestamp with time zone,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    applied_steps_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public._prisma_migrations OWNER TO armadillo;

--
-- Name: asset_vulnerabilities; Type: TABLE; Schema: public; Owner: armadillo
--

CREATE TABLE public.asset_vulnerabilities (
    id integer NOT NULL,
    "assetId" text NOT NULL,
    "importId" text NOT NULL,
    cve text NOT NULL,
    cpe text,
    severity text NOT NULL,
    cvss double precision,
    title text,
    description text,
    source text DEFAULT 'builtin-enricher'::text NOT NULL,
    "detectedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "exploitRefs" jsonb
);


ALTER TABLE public.asset_vulnerabilities OWNER TO armadillo;

--
-- Name: asset_vulnerabilities_id_seq; Type: SEQUENCE; Schema: public; Owner: armadillo
--

CREATE SEQUENCE public.asset_vulnerabilities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.asset_vulnerabilities_id_seq OWNER TO armadillo;

--
-- Name: asset_vulnerabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: armadillo
--

ALTER SEQUENCE public.asset_vulnerabilities_id_seq OWNED BY public.asset_vulnerabilities.id;


--
-- Name: assets; Type: TABLE; Schema: public; Owner: armadillo
--

CREATE TABLE public.assets (
    id text NOT NULL,
    "importId" text NOT NULL,
    ip text,
    hostname text,
    raw jsonb NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "firstSeenAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "identityKey" text NOT NULL,
    "lastSeenAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "seenCount" integer DEFAULT 1 NOT NULL,
    "updatedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    os text,
    ports integer[] DEFAULT ARRAY[]::integer[] NOT NULL,
    "serviceTags" text[] DEFAULT ARRAY[]::text[] NOT NULL,
    "sourceType" text DEFAULT 'xml'::text NOT NULL,
    annotations jsonb
);


ALTER TABLE public.assets OWNER TO armadillo;

--
-- Name: import_source_policies; Type: TABLE; Schema: public; Owner: armadillo
--

CREATE TABLE public.import_source_policies (
    source text NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    "defaultQualityMode" text DEFAULT 'strict'::text NOT NULL,
    "allowBypassToLenient" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.import_source_policies OWNER TO armadillo;

--
-- Name: scan_events; Type: TABLE; Schema: public; Owner: armadillo
--

CREATE TABLE public.scan_events (
    id integer NOT NULL,
    "scanId" text NOT NULL,
    status public."ScanStatus",
    stage text,
    message text,
    metadata jsonb,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.scan_events OWNER TO armadillo;

--
-- Name: scan_events_id_seq; Type: SEQUENCE; Schema: public; Owner: armadillo
--

CREATE SEQUENCE public.scan_events_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.scan_events_id_seq OWNER TO armadillo;

--
-- Name: scan_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: armadillo
--

ALTER SEQUENCE public.scan_events_id_seq OWNED BY public.scan_events.id;


--
-- Name: scan_schedules; Type: TABLE; Schema: public; Owner: armadillo
--

CREATE TABLE public.scan_schedules (
    id text NOT NULL,
    name text NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    "cronExpr" text NOT NULL,
    timezone text DEFAULT 'Australia/Melbourne'::text NOT NULL,
    "projectId" text NOT NULL,
    "requestedBy" text NOT NULL,
    targets jsonb NOT NULL,
    config jsonb,
    "nextRunAt" timestamp(3) without time zone,
    "lastRunAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "lastRunScanId" text,
    "lastRunStatus" text,
    "lastRunMessage" text
);


ALTER TABLE public.scan_schedules OWNER TO armadillo;

--
-- Name: scans; Type: TABLE; Schema: public; Owner: armadillo
--

CREATE TABLE public.scans (
    id text NOT NULL,
    "projectId" text NOT NULL,
    "requestedBy" text NOT NULL,
    status public."ScanStatus" DEFAULT 'queued'::public."ScanStatus" NOT NULL,
    request jsonb,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    annotations jsonb
);


ALTER TABLE public.scans OWNER TO armadillo;

--
-- Name: xml_imports; Type: TABLE; Schema: public; Owner: armadillo
--

CREATE TABLE public.xml_imports (
    id text NOT NULL,
    source text,
    "requestedBy" text NOT NULL,
    "rootNode" text,
    "itemCount" integer DEFAULT 0 NOT NULL,
    payload jsonb NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "normalizedAssetCount" integer DEFAULT 0 NOT NULL,
    "skippedAssetCount" integer DEFAULT 0 NOT NULL,
    "invalidAssetCount" integer DEFAULT 0 NOT NULL,
    "qualitySummary" jsonb,
    "qualityMode" text DEFAULT 'lenient'::text NOT NULL,
    "qualityStatus" text DEFAULT 'pass'::text NOT NULL,
    "alertTriggered" boolean DEFAULT false NOT NULL,
    "rejectArtifact" jsonb,
    annotations jsonb
);


ALTER TABLE public.xml_imports OWNER TO armadillo;

--
-- Name: asset_vulnerabilities id; Type: DEFAULT; Schema: public; Owner: armadillo
--

ALTER TABLE ONLY public.asset_vulnerabilities ALTER COLUMN id SET DEFAULT nextval('public.asset_vulnerabilities_id_seq'::regclass);


--
-- Name: scan_events id; Type: DEFAULT; Schema: public; Owner: armadillo
--

ALTER TABLE ONLY public.scan_events ALTER COLUMN id SET DEFAULT nextval('public.scan_events_id_seq'::regclass);


--
-- Data for Name: _prisma_migrations; Type: TABLE DATA; Schema: public; Owner: armadillo
--

COPY public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) FROM stdin;
a0463de1-984d-441c-baea-5c9461908028	660423ff474608c271cfc8d0390c7c47b8536f7a35755087b35dfd00db45bd44	2026-02-25 09:37:19.387125+00	20260225_step12_baseline		\N	2026-02-25 09:37:19.387125+00	0
9d78be59-9d18-4cf1-a5a9-7a1ab0f77ba6	6cfb2cb4f64e9eb94cd8eca2874ce688c96cdebd63fa5a77912d0fd6572fcd5c	2026-02-25 09:41:55.024596+00	20260225_step13_asset_quality	\N	\N	2026-02-25 09:41:55.016731+00	1
0dfd56ed-b3da-47b8-9f20-09ab44059005	512b141cd2e8ec1d019723d6f137d83d7273d7d0c9341554ede80604b627aff9	2026-02-25 09:58:37.11804+00	20260225_step17_quality_policy	\N	\N	2026-02-25 09:58:37.113877+00	1
1eb08a5a-7227-493d-9cab-9f6dc83d7229	12b9234ee6f994a35315019ebcdc56187149ce8c6374bde1b7194b2be7b728b3	2026-02-25 10:04:11.575989+00	20260225_step18_source_policy	\N	\N	2026-02-25 10:04:11.562752+00	1
dd15fe53-9371-4c3a-8d2d-430672add297	6d0c53a1f04a9f7beed4cc66cf9159471b081b027cf3ab5d481bade554c2900e	2026-02-26 00:37:30.605331+00	20260226_step21_annotations_diff	\N	\N	2026-02-26 00:37:30.59787+00	1
5180b604-2786-40cc-aca0-f3acc00155e6	32705136607d1c25e6015a5eed1caa4e682d1fe23a674033bd0c65f1850e21bd	2026-02-26 02:14:15.857837+00	20260226_step22_vuln_enrichment	\N	\N	2026-02-26 02:14:15.839894+00	1
8e0178eb-cc91-4686-93d2-921275a87f98	fab9fabf6207c185ae900f2676d364b0fe63033ecd1038eef19d9781aed3e332	2026-02-26 04:54:08.976099+00	20260226_step24_phase4_perf_indexes	\N	\N	2026-02-26 04:54:08.963991+00	1
c5a773de-5ef0-43dd-970f-4260d38ffedc	a0159c7d15b8e374140e2802ef053824c2452c376ef13feeb9df196dec188d86	2026-02-26 05:35:01.730678+00	20260226_step25_scan_schedules	\N	\N	2026-02-26 05:35:01.719619+00	1
f28646e0-9bb0-4969-ad0a-5185c4e92d58	92bb15dfe70ee2110a286f315a1d732834d431b3cf7f88ed0a74505051177114	2026-02-26 05:41:18.715657+00	20260226_step25_scan_schedules_phase2	\N	\N	2026-02-26 05:41:18.712947+00	1
d043e094-38ae-4739-9819-41a383d37cdb	6ad453490346ea9ca6279fd7d8e55b9dc93b545988a22f81108c2623ba97ac54	2026-02-26 07:48:36.45111+00	20260226_step27_exploit_refs	\N	\N	2026-02-26 07:48:36.447549+00	1
\.


--
-- Data for Name: asset_vulnerabilities; Type: TABLE DATA; Schema: public; Owner: armadillo
--

COPY public.asset_vulnerabilities (id, "assetId", "importId", cve, cpe, severity, cvss, title, description, source, "detectedAt", "exploitRefs") FROM stdin;
1	dd76a3e1-05a6-4f53-9041-f17681d77874	dc270ad9-361a-4dcf-988a-9ade80d0bf2d	CVE-2024-6387	cpe:2.3:a:openbsd:openssh:*	high	8.1	OpenSSH regreSSHion	Potential unauthenticated remote code execution risk in vulnerable OpenSSH versions.	builtin-enricher	2026-02-26 07:48:38.943	[{"id": "CVE-2024-6387", "url": "https://nvd.nist.gov/vuln/detail/CVE-2024-6387", "source": "nvd", "confidence": "high"}, {"id": "CVE-2024-6387", "url": "https://www.cisa.gov/known-exploited-vulnerabilities-catalog", "source": "cisa-kev", "confidence": "medium"}]
2	c9023d82-2279-46ff-a5ec-f084fd6c511e	dc270ad9-361a-4dcf-988a-9ade80d0bf2d	CVE-2023-44487	cpe:2.3:a:nginx:nginx:*	medium	7.5	HTTP/2 Rapid Reset	HTTP/2 request reset behavior can be abused for denial-of-service if not mitigated.	builtin-enricher	2026-02-26 07:48:38.946	[{"id": "CVE-2023-44487", "url": "https://nvd.nist.gov/vuln/detail/CVE-2023-44487", "source": "nvd", "confidence": "high"}]
3	c9023d82-2279-46ff-a5ec-f084fd6c511e	dc270ad9-361a-4dcf-988a-9ade80d0bf2d	CVE-2023-5678	cpe:2.3:a:openssl:openssl:*	medium	6.5	OpenSSL implementation weakness	Placeholder advisory mapping for OpenSSL exposure requiring version-specific validation.	builtin-enricher	2026-02-26 07:48:38.958	[]
\.


--
-- Data for Name: assets; Type: TABLE DATA; Schema: public; Owner: armadillo
--

COPY public.assets (id, "importId", ip, hostname, raw, "createdAt", "firstSeenAt", "identityKey", "lastSeenAt", "seenCount", "updatedAt", os, ports, "serviceTags", "sourceType", annotations) FROM stdin;
dd76a3e1-05a6-4f53-9041-f17681d77874	dc270ad9-361a-4dcf-988a-9ade80d0bf2d	10.0.0.2	\N	{"ip": "10.0.0.2", "port": 22, "tags": "ssh"}	2026-02-25 09:20:25.155	2026-02-25 09:20:22.797	ip:10.0.0.2	2026-02-25 10:13:51.911	15	2026-02-25 10:13:51.912	\N	{22}	{ssh}	xml	\N
b43724c8-a8f9-4b1f-ab72-5f3cb9f746b4	dc270ad9-361a-4dcf-988a-9ade80d0bf2d	\N	bad-port-host	{"port": "abc", "hostname": "bad-port-host"}	2026-02-25 09:41:56.32	2026-02-25 09:41:56.32	host:bad-port-host	2026-02-25 10:13:51.913	8	2026-02-25 10:13:51.913	\N	{}	{}	xml	\N
c9023d82-2279-46ff-a5ec-f084fd6c511e	dc270ad9-361a-4dcf-988a-9ade80d0bf2d	10.0.0.1	\N	{"ip": "10.0.0.1", "ports": "443,8443", "serviceTags": "web"}	2026-02-25 09:20:25.153	2026-02-25 09:20:22.797	ip:10.0.0.1	2026-02-25 10:13:51.908	15	2026-02-26 00:37:56.804	\N	{443,8443}	{web}	xml	{"notes": "Step21 verification note", "labels": ["priority", "demo"]}
\.


--
-- Data for Name: import_source_policies; Type: TABLE DATA; Schema: public; Owner: armadillo
--

COPY public.import_source_policies (source, enabled, "defaultQualityMode", "allowBypassToLenient", "createdAt", "updatedAt") FROM stdin;
smoke-test	t	lenient	t	2026-02-25 10:04:11.565	2026-02-25 10:04:11.565
manual	t	strict	f	2026-02-25 10:04:11.565	2026-02-25 10:04:11.565
\.


--
-- Data for Name: scan_events; Type: TABLE DATA; Schema: public; Owner: armadillo
--

COPY public.scan_events (id, "scanId", status, stage, message, metadata, "createdAt") FROM stdin;
1	50250b3a-ac3e-4f6a-8d69-b423618f417b	queued	\N	Scan created	\N	2026-02-25 08:12:10.415
2	342829f8-219a-4982-8f92-d689f0e8df99	queued	\N	Scan created	\N	2026-02-25 08:34:14.378
3	16e14b58-2b65-41ad-8f82-1b64a623bb40	queued	\N	Scan created	\N	2026-02-25 08:34:43.835
4	16e14b58-2b65-41ad-8f82-1b64a623bb40	running	\N	Scan updated	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "step2-test"}}	2026-02-25 08:34:43.863
5	16e14b58-2b65-41ad-8f82-1b64a623bb40	running	\N	Scan updated	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "step2-test"}}	2026-02-25 08:34:44.171
6	16e14b58-2b65-41ad-8f82-1b64a623bb40	running	\N	Scan updated	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "step2-test"}}	2026-02-25 08:34:44.479
7	16e14b58-2b65-41ad-8f82-1b64a623bb40	running	\N	Scan updated	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "step2-test"}}	2026-02-25 08:34:44.797
8	16e14b58-2b65-41ad-8f82-1b64a623bb40	completed	\N	Scan updated	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "step2-test"}}	2026-02-25 08:34:45.116
9	ceade3fb-d9ee-4635-b341-f60aaf0ad92a	queued	\N	Scan created	\N	2026-02-25 08:34:49.871
10	ceade3fb-d9ee-4635-b341-f60aaf0ad92a	running	\N	Scan updated	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "step2-test"}}	2026-02-25 08:34:49.878
11	ceade3fb-d9ee-4635-b341-f60aaf0ad92a	running	\N	Scan updated	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "step2-test"}}	2026-02-25 08:34:50.197
12	ceade3fb-d9ee-4635-b341-f60aaf0ad92a	running	\N	Scan updated	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "step2-test"}}	2026-02-25 08:34:50.522
13	ceade3fb-d9ee-4635-b341-f60aaf0ad92a	running	\N	Scan updated	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "step2-test"}}	2026-02-25 08:34:50.828
14	ceade3fb-d9ee-4635-b341-f60aaf0ad92a	completed	\N	Scan updated	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "step2-test"}}	2026-02-25 08:34:51.143
15	012f6b5b-8cbf-4788-b6b1-137705c2626f	queued	\N	Scan created	\N	2026-02-25 08:38:07.734
16	012f6b5b-8cbf-4788-b6b1-137705c2626f	running	\N	Scan updated	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:38:07.756
17	012f6b5b-8cbf-4788-b6b1-137705c2626f	running	\N	Scan updated	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:38:08.074
18	012f6b5b-8cbf-4788-b6b1-137705c2626f	running	\N	Scan updated	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:38:08.39
19	012f6b5b-8cbf-4788-b6b1-137705c2626f	running	\N	Scan updated	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:38:08.718
20	012f6b5b-8cbf-4788-b6b1-137705c2626f	completed	\N	Scan updated	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:38:09.033
21	cd8f0949-0cef-4b0b-b5f3-e8bf86b8dbfc	queued	\N	Scan created	\N	2026-02-25 08:41:35.812
22	cd8f0949-0cef-4b0b-b5f3-e8bf86b8dbfc	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:41:35.839
23	cd8f0949-0cef-4b0b-b5f3-e8bf86b8dbfc	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:41:36.153
24	cd8f0949-0cef-4b0b-b5f3-e8bf86b8dbfc	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:41:36.461
25	cd8f0949-0cef-4b0b-b5f3-e8bf86b8dbfc	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:41:36.788
26	cd8f0949-0cef-4b0b-b5f3-e8bf86b8dbfc	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:41:37.093
27	9f466d7a-217b-43ad-b416-ed78d4968ccb	queued	\N	Scan created	\N	2026-02-25 08:46:11.223
28	9f466d7a-217b-43ad-b416-ed78d4968ccb	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:46:11.252
29	9f466d7a-217b-43ad-b416-ed78d4968ccb	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:46:11.559
30	9f466d7a-217b-43ad-b416-ed78d4968ccb	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:46:11.873
31	9f466d7a-217b-43ad-b416-ed78d4968ccb	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:46:12.182
32	9f466d7a-217b-43ad-b416-ed78d4968ccb	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:46:12.487
33	d43bf8cd-8fe4-458f-b6f1-a6fc147dc264	queued	\N	Scan created	\N	2026-02-25 08:49:51.941
34	d43bf8cd-8fe4-458f-b6f1-a6fc147dc264	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:49:51.972
35	d43bf8cd-8fe4-458f-b6f1-a6fc147dc264	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:49:52.286
36	d43bf8cd-8fe4-458f-b6f1-a6fc147dc264	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:49:52.606
37	d43bf8cd-8fe4-458f-b6f1-a6fc147dc264	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:49:52.914
38	d43bf8cd-8fe4-458f-b6f1-a6fc147dc264	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:49:53.23
39	3320bbef-75c3-4e12-9e74-24a0502ad7c6	queued	\N	Scan created	\N	2026-02-25 08:57:01.686
40	3320bbef-75c3-4e12-9e74-24a0502ad7c6	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:57:01.709
41	3320bbef-75c3-4e12-9e74-24a0502ad7c6	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:57:02.02
42	3320bbef-75c3-4e12-9e74-24a0502ad7c6	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:57:02.326
43	3320bbef-75c3-4e12-9e74-24a0502ad7c6	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:57:02.635
44	3320bbef-75c3-4e12-9e74-24a0502ad7c6	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 08:57:02.94
45	e9eef081-839e-42ee-9aeb-c33970fe5ad5	queued	\N	Scan created	\N	2026-02-25 09:01:03.43
46	e9eef081-839e-42ee-9aeb-c33970fe5ad5	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:01:03.46
47	e9eef081-839e-42ee-9aeb-c33970fe5ad5	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:01:03.768
48	e9eef081-839e-42ee-9aeb-c33970fe5ad5	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:01:04.095
49	e9eef081-839e-42ee-9aeb-c33970fe5ad5	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:01:04.412
50	e9eef081-839e-42ee-9aeb-c33970fe5ad5	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:01:04.717
51	4d0119c6-7a12-449d-9c16-2eda09257747	queued	\N	Scan created	\N	2026-02-25 09:19:56.525
52	4d0119c6-7a12-449d-9c16-2eda09257747	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:19:56.551
53	4d0119c6-7a12-449d-9c16-2eda09257747	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:19:56.868
54	4d0119c6-7a12-449d-9c16-2eda09257747	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:19:57.175
55	4d0119c6-7a12-449d-9c16-2eda09257747	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:19:57.48
56	4d0119c6-7a12-449d-9c16-2eda09257747	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:19:57.795
57	32a04a16-8b68-4300-ab3f-f1f70a495634	queued	\N	Scan created	\N	2026-02-25 09:20:25.068
58	32a04a16-8b68-4300-ab3f-f1f70a495634	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:20:25.096
59	32a04a16-8b68-4300-ab3f-f1f70a495634	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:20:25.406
60	32a04a16-8b68-4300-ab3f-f1f70a495634	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:20:25.712
61	32a04a16-8b68-4300-ab3f-f1f70a495634	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:20:26.027
62	32a04a16-8b68-4300-ab3f-f1f70a495634	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:20:26.362
63	ccfefed5-c39f-4770-a644-32b8151a2824	queued	\N	Scan created	\N	2026-02-25 09:22:59.583
64	ccfefed5-c39f-4770-a644-32b8151a2824	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:22:59.619
65	ccfefed5-c39f-4770-a644-32b8151a2824	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:22:59.931
66	ccfefed5-c39f-4770-a644-32b8151a2824	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:23:00.235
67	ccfefed5-c39f-4770-a644-32b8151a2824	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:23:00.55
68	ccfefed5-c39f-4770-a644-32b8151a2824	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:23:00.857
69	2369d66e-c271-40c9-9d1d-5a05ce2ad5c6	queued	\N	Scan created	\N	2026-02-25 09:23:18.892
70	2369d66e-c271-40c9-9d1d-5a05ce2ad5c6	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:23:18.898
71	2369d66e-c271-40c9-9d1d-5a05ce2ad5c6	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:23:19.211
72	2369d66e-c271-40c9-9d1d-5a05ce2ad5c6	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:23:19.534
73	2369d66e-c271-40c9-9d1d-5a05ce2ad5c6	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:23:19.852
74	2369d66e-c271-40c9-9d1d-5a05ce2ad5c6	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:23:20.168
75	d5ea14c1-cb10-4270-973a-1b91657c268b	queued	\N	Scan created	\N	2026-02-25 09:33:31.783
76	d5ea14c1-cb10-4270-973a-1b91657c268b	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:33:31.804
77	d5ea14c1-cb10-4270-973a-1b91657c268b	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:33:32.116
78	d5ea14c1-cb10-4270-973a-1b91657c268b	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:33:32.436
79	d5ea14c1-cb10-4270-973a-1b91657c268b	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:33:32.76
80	d5ea14c1-cb10-4270-973a-1b91657c268b	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:33:33.066
81	9e2a546f-44b7-45a6-9b9d-34f7c283ca54	queued	\N	Scan created	\N	2026-02-25 09:37:21.122
82	9e2a546f-44b7-45a6-9b9d-34f7c283ca54	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:37:21.156
83	9e2a546f-44b7-45a6-9b9d-34f7c283ca54	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:37:21.467
84	9e2a546f-44b7-45a6-9b9d-34f7c283ca54	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:37:21.776
85	9e2a546f-44b7-45a6-9b9d-34f7c283ca54	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:37:22.102
177	7b17a4f4-93a1-4ccb-a4b3-3f56b46db97b	queued	\N	Scan created	\N	2026-02-26 05:44:20.15
86	9e2a546f-44b7-45a6-9b9d-34f7c283ca54	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:37:22.415
87	2ec68b31-1b3e-4f54-840a-229994dfb5c4	queued	\N	Scan created	\N	2026-02-25 09:41:56.22
88	2ec68b31-1b3e-4f54-840a-229994dfb5c4	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:41:56.243
89	2ec68b31-1b3e-4f54-840a-229994dfb5c4	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:41:56.551
90	2ec68b31-1b3e-4f54-840a-229994dfb5c4	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:41:56.864
91	2ec68b31-1b3e-4f54-840a-229994dfb5c4	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:41:57.173
92	2ec68b31-1b3e-4f54-840a-229994dfb5c4	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:41:57.482
93	7b4dbd9c-0daa-40eb-a71f-0f5b8c206d12	queued	\N	Scan created	\N	2026-02-25 09:45:06.213
94	7b4dbd9c-0daa-40eb-a71f-0f5b8c206d12	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:45:06.24
95	7b4dbd9c-0daa-40eb-a71f-0f5b8c206d12	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:45:06.547
96	7b4dbd9c-0daa-40eb-a71f-0f5b8c206d12	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:45:06.852
97	7b4dbd9c-0daa-40eb-a71f-0f5b8c206d12	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:45:07.184
98	7b4dbd9c-0daa-40eb-a71f-0f5b8c206d12	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:45:07.491
99	5584e06a-706e-46e6-9bc0-eab88435983f	queued	\N	Scan created	\N	2026-02-25 09:48:26.239
100	5584e06a-706e-46e6-9bc0-eab88435983f	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:48:26.262
101	5584e06a-706e-46e6-9bc0-eab88435983f	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:48:26.572
102	5584e06a-706e-46e6-9bc0-eab88435983f	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:48:26.879
103	5584e06a-706e-46e6-9bc0-eab88435983f	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:48:27.189
104	5584e06a-706e-46e6-9bc0-eab88435983f	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:48:27.495
105	be0ce310-f29c-4045-9439-380d15a7abe5	queued	\N	Scan created	\N	2026-02-25 09:51:26.386
106	be0ce310-f29c-4045-9439-380d15a7abe5	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:51:26.409
107	be0ce310-f29c-4045-9439-380d15a7abe5	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:51:26.716
108	be0ce310-f29c-4045-9439-380d15a7abe5	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:51:27.023
109	be0ce310-f29c-4045-9439-380d15a7abe5	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:51:27.348
110	be0ce310-f29c-4045-9439-380d15a7abe5	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:51:27.661
111	3eeb3511-4f4e-4d0a-9cda-c9199b06ea8b	queued	\N	Scan created	\N	2026-02-25 09:58:38.692
112	3eeb3511-4f4e-4d0a-9cda-c9199b06ea8b	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:58:38.717
113	3eeb3511-4f4e-4d0a-9cda-c9199b06ea8b	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:58:39.028
114	3eeb3511-4f4e-4d0a-9cda-c9199b06ea8b	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:58:39.341
115	3eeb3511-4f4e-4d0a-9cda-c9199b06ea8b	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:58:39.656
116	3eeb3511-4f4e-4d0a-9cda-c9199b06ea8b	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 09:58:39.96
117	487e2695-9e8d-40c2-bab2-c2b0b53f8b50	queued	\N	Scan created	\N	2026-02-25 10:04:12.845
118	487e2695-9e8d-40c2-bab2-c2b0b53f8b50	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 10:04:12.888
119	487e2695-9e8d-40c2-bab2-c2b0b53f8b50	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 10:04:13.195
120	487e2695-9e8d-40c2-bab2-c2b0b53f8b50	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 10:04:13.508
121	487e2695-9e8d-40c2-bab2-c2b0b53f8b50	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 10:04:13.813
122	487e2695-9e8d-40c2-bab2-c2b0b53f8b50	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 10:04:14.118
123	3fe2e624-a5b8-435a-a83e-0c461c1ae00a	queued	\N	Scan created	\N	2026-02-25 10:09:41.006
124	3fe2e624-a5b8-435a-a83e-0c461c1ae00a	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 10:09:41.027
125	3fe2e624-a5b8-435a-a83e-0c461c1ae00a	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 10:09:41.348
126	3fe2e624-a5b8-435a-a83e-0c461c1ae00a	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 10:09:41.674
127	3fe2e624-a5b8-435a-a83e-0c461c1ae00a	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 10:09:41.992
128	3fe2e624-a5b8-435a-a83e-0c461c1ae00a	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 10:09:42.302
129	7cb48596-9a6a-4413-b122-10b70a08f973	queued	\N	Scan created	\N	2026-02-25 10:13:51.828
130	7cb48596-9a6a-4413-b122-10b70a08f973	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 10:13:51.834
131	7cb48596-9a6a-4413-b122-10b70a08f973	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 10:13:52.15
132	7cb48596-9a6a-4413-b122-10b70a08f973	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 10:13:52.469
133	7cb48596-9a6a-4413-b122-10b70a08f973	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 10:13:52.79
134	7cb48596-9a6a-4413-b122-10b70a08f973	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}}	2026-02-25 10:13:53.096
135	0c755b2f-6640-49e6-b882-8049c0ad5d31	queued	\N	Scan created	\N	2026-02-26 04:16:44.86
136	0c755b2f-6640-49e6-b882-8049c0ad5d31	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 04:16:44.887
137	0c755b2f-6640-49e6-b882-8049c0ad5d31	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 04:16:45.209
138	0c755b2f-6640-49e6-b882-8049c0ad5d31	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 04:16:45.522
139	0c755b2f-6640-49e6-b882-8049c0ad5d31	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 04:16:45.84
140	0c755b2f-6640-49e6-b882-8049c0ad5d31	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 04:16:46.16
141	4f4c2224-5ff5-43ef-8197-7db1e8891a0c	queued	\N	Scan created	\N	2026-02-26 04:54:13.283
142	4f4c2224-5ff5-43ef-8197-7db1e8891a0c	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}}	2026-02-26 04:54:13.32
143	4f4c2224-5ff5-43ef-8197-7db1e8891a0c	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}}	2026-02-26 04:54:13.633
144	4f4c2224-5ff5-43ef-8197-7db1e8891a0c	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}}	2026-02-26 04:54:13.946
145	4f4c2224-5ff5-43ef-8197-7db1e8891a0c	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}}	2026-02-26 04:54:14.252
146	4f4c2224-5ff5-43ef-8197-7db1e8891a0c	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}}	2026-02-26 04:54:14.557
147	ed207888-58de-4ee5-b934-15f9173a4e95	queued	\N	Scan created	\N	2026-02-26 04:56:16.126
148	ed207888-58de-4ee5-b934-15f9173a4e95	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}}	2026-02-26 04:56:16.153
149	ed207888-58de-4ee5-b934-15f9173a4e95	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}}	2026-02-26 04:56:16.462
150	ed207888-58de-4ee5-b934-15f9173a4e95	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}}	2026-02-26 04:56:16.772
151	ed207888-58de-4ee5-b934-15f9173a4e95	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}}	2026-02-26 04:56:17.086
152	ed207888-58de-4ee5-b934-15f9173a4e95	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}}	2026-02-26 04:56:17.39
153	f6b6a24a-722e-4564-8d02-302ce3a5b200	queued	\N	Scan created	\N	2026-02-26 04:58:55.017
154	f6b6a24a-722e-4564-8d02-302ce3a5b200	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}}	2026-02-26 04:58:55.05
155	f6b6a24a-722e-4564-8d02-302ce3a5b200	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}}	2026-02-26 04:58:55.362
156	f6b6a24a-722e-4564-8d02-302ce3a5b200	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}}	2026-02-26 04:58:55.669
157	f6b6a24a-722e-4564-8d02-302ce3a5b200	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}}	2026-02-26 04:58:55.977
158	f6b6a24a-722e-4564-8d02-302ce3a5b200	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}}	2026-02-26 04:58:56.283
159	cc6cabac-2d2a-4671-9bb5-2580207912a4	queued	\N	Scan created	\N	2026-02-26 05:21:23.527
160	cc6cabac-2d2a-4671-9bb5-2580207912a4	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}}	2026-02-26 05:21:23.563
161	cc6cabac-2d2a-4671-9bb5-2580207912a4	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}}	2026-02-26 05:21:23.874
162	cc6cabac-2d2a-4671-9bb5-2580207912a4	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}}	2026-02-26 05:21:24.188
163	cc6cabac-2d2a-4671-9bb5-2580207912a4	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}}	2026-02-26 05:21:24.502
164	cc6cabac-2d2a-4671-9bb5-2580207912a4	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}}	2026-02-26 05:21:24.806
165	d7c5776b-e69a-4aa7-bbb4-777e43165072	queued	\N	Scan created	\N	2026-02-26 05:42:20.132
166	d7c5776b-e69a-4aa7-bbb4-777e43165072	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:42:20.154
167	d7c5776b-e69a-4aa7-bbb4-777e43165072	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:42:20.471
168	d7c5776b-e69a-4aa7-bbb4-777e43165072	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:42:20.79
171	1158da46-ccfd-4225-82b4-8fbb798177e4	queued	\N	Scan created	\N	2026-02-26 05:43:20.149
169	d7c5776b-e69a-4aa7-bbb4-777e43165072	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:42:21.11
170	d7c5776b-e69a-4aa7-bbb4-777e43165072	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:42:21.425
172	1158da46-ccfd-4225-82b4-8fbb798177e4	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:43:20.158
173	1158da46-ccfd-4225-82b4-8fbb798177e4	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:43:20.464
174	1158da46-ccfd-4225-82b4-8fbb798177e4	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:43:20.782
175	1158da46-ccfd-4225-82b4-8fbb798177e4	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:43:21.091
176	1158da46-ccfd-4225-82b4-8fbb798177e4	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:43:21.406
178	7b17a4f4-93a1-4ccb-a4b3-3f56b46db97b	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:44:20.157
179	7b17a4f4-93a1-4ccb-a4b3-3f56b46db97b	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:44:20.526
180	7b17a4f4-93a1-4ccb-a4b3-3f56b46db97b	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:44:20.833
181	7b17a4f4-93a1-4ccb-a4b3-3f56b46db97b	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:44:21.247
182	7b17a4f4-93a1-4ccb-a4b3-3f56b46db97b	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:44:21.55
183	d1cb990d-3b0f-47e8-9a0f-6ca45d329af7	queued	\N	Scan created	\N	2026-02-26 05:45:40.46
184	d1cb990d-3b0f-47e8-9a0f-6ca45d329af7	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:45:40.501
185	d1cb990d-3b0f-47e8-9a0f-6ca45d329af7	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:45:40.822
186	d1cb990d-3b0f-47e8-9a0f-6ca45d329af7	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:45:41.132
187	d1cb990d-3b0f-47e8-9a0f-6ca45d329af7	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:45:41.445
188	d1cb990d-3b0f-47e8-9a0f-6ca45d329af7	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:45:41.763
189	7d64dcdf-9e1f-4c07-83b3-2da3bc5ff5aa	queued	\N	Scan created	\N	2026-02-26 05:46:40.459
190	7d64dcdf-9e1f-4c07-83b3-2da3bc5ff5aa	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:46:52.072
191	7d64dcdf-9e1f-4c07-83b3-2da3bc5ff5aa	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:46:52.382
192	7d64dcdf-9e1f-4c07-83b3-2da3bc5ff5aa	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:46:52.691
193	7d64dcdf-9e1f-4c07-83b3-2da3bc5ff5aa	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:46:53
194	7d64dcdf-9e1f-4c07-83b3-2da3bc5ff5aa	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:46:53.305
195	b5462738-0085-4d4e-b1df-20a44d262436	queued	\N	Scan created	\N	2026-02-26 05:47:54.438
196	b5462738-0085-4d4e-b1df-20a44d262436	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:47:54.454
197	b5462738-0085-4d4e-b1df-20a44d262436	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:47:54.779
198	b5462738-0085-4d4e-b1df-20a44d262436	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:47:55.093
199	b5462738-0085-4d4e-b1df-20a44d262436	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:47:55.406
200	b5462738-0085-4d4e-b1df-20a44d262436	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:47:55.715
202	be868bbe-b8d8-4fb9-a94c-3732e8c13a32	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:48:54.449
203	be868bbe-b8d8-4fb9-a94c-3732e8c13a32	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:48:54.768
204	be868bbe-b8d8-4fb9-a94c-3732e8c13a32	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:48:55.08
205	be868bbe-b8d8-4fb9-a94c-3732e8c13a32	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:48:55.394
206	be868bbe-b8d8-4fb9-a94c-3732e8c13a32	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:48:55.709
1245	048d4168-0d61-4a70-a5de-ee44aefdb0bd	queued	\N	Scan created	\N	2026-02-26 08:42:12.165
1251	feda98a0-6e77-42d7-bd96-8b4100d24cc5	queued	\N	Scan created	\N	2026-02-26 08:43:12.178
1257	82a2aece-78e9-45d2-bab6-1668eee2d38a	queued	\N	Scan created	\N	2026-02-26 08:44:12.327
1291	4de26ff9-8648-4ee3-848c-6ecc8c66242e	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:49:36.895
1292	4de26ff9-8648-4ee3-848c-6ecc8c66242e	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:49:37.209
1311	c51d75da-1459-4766-9c1d-d1ae53aa6bca	queued	\N	Scan created	\N	2026-02-26 08:53:35.977
1324	62d0c697-d3b9-4800-b251-d71f630ba7d9	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:55:36.078
1325	62d0c697-d3b9-4800-b251-d71f630ba7d9	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:55:36.39
1326	62d0c697-d3b9-4800-b251-d71f630ba7d9	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:55:36.706
1327	62d0c697-d3b9-4800-b251-d71f630ba7d9	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:55:37.011
1328	62d0c697-d3b9-4800-b251-d71f630ba7d9	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:55:37.327
1330	01444663-6fc6-4377-89e3-47bc2163ee1b	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:56:36.061
1331	01444663-6fc6-4377-89e3-47bc2163ee1b	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:56:36.377
1332	01444663-6fc6-4377-89e3-47bc2163ee1b	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:56:36.683
1333	01444663-6fc6-4377-89e3-47bc2163ee1b	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:56:36.999
1334	01444663-6fc6-4377-89e3-47bc2163ee1b	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:56:37.315
1336	6147bb2e-7dd6-42ea-8ed9-9ee2ac7ae994	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:57:44.307
1337	6147bb2e-7dd6-42ea-8ed9-9ee2ac7ae994	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:57:44.619
1338	6147bb2e-7dd6-42ea-8ed9-9ee2ac7ae994	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:57:44.928
1347	5defbace-8c26-451c-928d-7f4b952e1f85	queued	\N	Scan created	\N	2026-02-26 08:59:46.748
1353	4b54b001-5ce2-4a79-94a4-007cce4e61f8	queued	\N	Scan created	\N	2026-02-26 09:00:46.749
201	be868bbe-b8d8-4fb9-a94c-3732e8c13a32	queued	\N	Scan created	\N	2026-02-26 05:48:54.444
207	b578e05b-6f01-4e7a-b2c6-b48aa03f4008	queued	\N	Scan created	\N	2026-02-26 05:49:54.444
208	b578e05b-6f01-4e7a-b2c6-b48aa03f4008	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:49:54.453
209	b578e05b-6f01-4e7a-b2c6-b48aa03f4008	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:49:54.76
210	b578e05b-6f01-4e7a-b2c6-b48aa03f4008	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:49:55.064
211	b578e05b-6f01-4e7a-b2c6-b48aa03f4008	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:49:55.369
212	b578e05b-6f01-4e7a-b2c6-b48aa03f4008	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:49:55.673
213	5096b3e1-679e-43ee-bcdf-fca912c9ce62	queued	\N	Scan created	\N	2026-02-26 05:50:36.289
214	5096b3e1-679e-43ee-bcdf-fca912c9ce62	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:50:36.332
215	5096b3e1-679e-43ee-bcdf-fca912c9ce62	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:50:36.64
216	5096b3e1-679e-43ee-bcdf-fca912c9ce62	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:50:36.946
217	5096b3e1-679e-43ee-bcdf-fca912c9ce62	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:50:37.254
218	5096b3e1-679e-43ee-bcdf-fca912c9ce62	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:50:37.563
219	824cf3aa-ceb0-4f8e-b447-443ea9640cdc	queued	\N	Scan created	\N	2026-02-26 05:51:36.246
220	824cf3aa-ceb0-4f8e-b447-443ea9640cdc	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:51:36.258
221	824cf3aa-ceb0-4f8e-b447-443ea9640cdc	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:51:36.577
222	824cf3aa-ceb0-4f8e-b447-443ea9640cdc	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:51:36.892
223	824cf3aa-ceb0-4f8e-b447-443ea9640cdc	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:51:37.206
224	824cf3aa-ceb0-4f8e-b447-443ea9640cdc	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:51:37.521
225	75abfc2d-9494-432a-a19b-dcbd16b88b19	queued	\N	Scan created	\N	2026-02-26 05:52:36.251
226	75abfc2d-9494-432a-a19b-dcbd16b88b19	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:52:36.261
227	75abfc2d-9494-432a-a19b-dcbd16b88b19	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:52:36.579
228	75abfc2d-9494-432a-a19b-dcbd16b88b19	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:52:36.902
229	75abfc2d-9494-432a-a19b-dcbd16b88b19	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:52:37.217
230	75abfc2d-9494-432a-a19b-dcbd16b88b19	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:52:37.535
231	edfab898-4dfd-4303-bda8-056e5d2d469c	queued	\N	Scan created	\N	2026-02-26 05:53:36.278
232	edfab898-4dfd-4303-bda8-056e5d2d469c	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:53:36.285
233	edfab898-4dfd-4303-bda8-056e5d2d469c	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:53:36.592
234	edfab898-4dfd-4303-bda8-056e5d2d469c	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:53:36.901
235	edfab898-4dfd-4303-bda8-056e5d2d469c	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:53:37.206
236	edfab898-4dfd-4303-bda8-056e5d2d469c	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:53:37.51
237	41783f5a-b949-46f1-b55c-20081930b0b5	queued	\N	Scan created	\N	2026-02-26 05:54:08.341
238	41783f5a-b949-46f1-b55c-20081930b0b5	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:54:08.394
239	41783f5a-b949-46f1-b55c-20081930b0b5	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:54:08.701
240	41783f5a-b949-46f1-b55c-20081930b0b5	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:54:09.008
241	41783f5a-b949-46f1-b55c-20081930b0b5	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:54:09.321
242	41783f5a-b949-46f1-b55c-20081930b0b5	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:54:09.626
243	523049ca-6d7f-4616-9159-496e54d9cdf3	queued	\N	Scan created	\N	2026-02-26 05:55:08.324
244	523049ca-6d7f-4616-9159-496e54d9cdf3	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:55:08.336
245	523049ca-6d7f-4616-9159-496e54d9cdf3	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:55:08.658
246	523049ca-6d7f-4616-9159-496e54d9cdf3	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:55:08.983
247	523049ca-6d7f-4616-9159-496e54d9cdf3	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:55:09.298
248	523049ca-6d7f-4616-9159-496e54d9cdf3	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:55:09.612
249	2d90297a-fa5f-4cad-b075-d81cacac61e8	queued	\N	Scan created	\N	2026-02-26 05:56:08.365
250	2d90297a-fa5f-4cad-b075-d81cacac61e8	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:56:08.37
251	2d90297a-fa5f-4cad-b075-d81cacac61e8	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:56:08.676
252	2d90297a-fa5f-4cad-b075-d81cacac61e8	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:56:08.981
253	2d90297a-fa5f-4cad-b075-d81cacac61e8	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:56:09.286
254	2d90297a-fa5f-4cad-b075-d81cacac61e8	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:56:09.594
255	9c9d19fa-2dc4-4ece-ad26-d94506be4b5e	queued	\N	Scan created	\N	2026-02-26 05:57:40.585
256	9c9d19fa-2dc4-4ece-ad26-d94506be4b5e	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:57:40.627
257	9c9d19fa-2dc4-4ece-ad26-d94506be4b5e	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:57:40.949
258	9c9d19fa-2dc4-4ece-ad26-d94506be4b5e	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:57:41.267
259	9c9d19fa-2dc4-4ece-ad26-d94506be4b5e	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:57:41.582
260	9c9d19fa-2dc4-4ece-ad26-d94506be4b5e	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:57:41.886
261	c11cdf0a-70cc-4fad-9b80-552ac9b367ad	queued	\N	Scan created	\N	2026-02-26 05:58:40.579
262	c11cdf0a-70cc-4fad-9b80-552ac9b367ad	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:58:40.587
321	7eccf2d1-8498-45e6-ac2b-b14b2542a1c2	queued	\N	Scan created	\N	2026-02-26 06:08:40.474
263	c11cdf0a-70cc-4fad-9b80-552ac9b367ad	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:58:40.907
264	c11cdf0a-70cc-4fad-9b80-552ac9b367ad	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:58:41.223
265	c11cdf0a-70cc-4fad-9b80-552ac9b367ad	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:58:41.535
266	c11cdf0a-70cc-4fad-9b80-552ac9b367ad	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:58:41.848
267	5b481e5a-b2f4-4c77-8f77-b512f9f37b02	queued	\N	Scan created	\N	2026-02-26 05:59:40.628
268	5b481e5a-b2f4-4c77-8f77-b512f9f37b02	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:59:40.637
269	5b481e5a-b2f4-4c77-8f77-b512f9f37b02	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:59:40.947
270	5b481e5a-b2f4-4c77-8f77-b512f9f37b02	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:59:41.253
271	5b481e5a-b2f4-4c77-8f77-b512f9f37b02	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:59:41.56
272	5b481e5a-b2f4-4c77-8f77-b512f9f37b02	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 05:59:41.862
273	c990a44a-eaa3-440b-8905-295f50874631	queued	\N	Scan created	\N	2026-02-26 06:00:10.966
274	c990a44a-eaa3-440b-8905-295f50874631	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:00:11.005
275	c990a44a-eaa3-440b-8905-295f50874631	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:00:11.314
276	c990a44a-eaa3-440b-8905-295f50874631	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:00:11.627
277	c990a44a-eaa3-440b-8905-295f50874631	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:00:11.933
278	c990a44a-eaa3-440b-8905-295f50874631	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:00:12.24
279	5113ae95-cdd0-47eb-a1b9-f749c41b21d4	queued	\N	Scan created	\N	2026-02-26 06:01:10.955
280	5113ae95-cdd0-47eb-a1b9-f749c41b21d4	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:01:10.967
281	5113ae95-cdd0-47eb-a1b9-f749c41b21d4	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:01:11.282
282	5113ae95-cdd0-47eb-a1b9-f749c41b21d4	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:01:11.595
283	5113ae95-cdd0-47eb-a1b9-f749c41b21d4	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:01:11.907
284	5113ae95-cdd0-47eb-a1b9-f749c41b21d4	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:01:12.226
285	cd2c208f-6842-4e16-80f2-d9a0d2a983dd	queued	\N	Scan created	\N	2026-02-26 06:02:10.97
286	cd2c208f-6842-4e16-80f2-d9a0d2a983dd	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:02:11.001
287	cd2c208f-6842-4e16-80f2-d9a0d2a983dd	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:02:11.316
288	cd2c208f-6842-4e16-80f2-d9a0d2a983dd	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:02:11.628
289	cd2c208f-6842-4e16-80f2-d9a0d2a983dd	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:02:11.946
291	03108f6d-6851-40bc-a78d-bb3edafec2f5	queued	\N	Scan created	\N	2026-02-26 06:03:10.981
297	f61271d3-2abb-4ba0-b048-1296d5229d75	queued	\N	Scan created	\N	2026-02-26 06:04:11.013
290	cd2c208f-6842-4e16-80f2-d9a0d2a983dd	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:02:12.259
292	03108f6d-6851-40bc-a78d-bb3edafec2f5	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:03:10.991
293	03108f6d-6851-40bc-a78d-bb3edafec2f5	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:03:11.314
294	03108f6d-6851-40bc-a78d-bb3edafec2f5	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:03:11.625
295	03108f6d-6851-40bc-a78d-bb3edafec2f5	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:03:11.942
296	03108f6d-6851-40bc-a78d-bb3edafec2f5	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:03:12.254
298	f61271d3-2abb-4ba0-b048-1296d5229d75	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:04:11.025
299	f61271d3-2abb-4ba0-b048-1296d5229d75	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:04:11.336
300	f61271d3-2abb-4ba0-b048-1296d5229d75	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:04:11.655
301	f61271d3-2abb-4ba0-b048-1296d5229d75	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:04:11.969
302	f61271d3-2abb-4ba0-b048-1296d5229d75	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:04:12.289
303	e69443c5-3f75-4136-9e48-7e592d0cdbd1	queued	\N	Scan created	\N	2026-02-26 06:05:11.055
304	e69443c5-3f75-4136-9e48-7e592d0cdbd1	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:05:11.063
305	e69443c5-3f75-4136-9e48-7e592d0cdbd1	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:05:11.368
306	e69443c5-3f75-4136-9e48-7e592d0cdbd1	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:05:11.672
307	e69443c5-3f75-4136-9e48-7e592d0cdbd1	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:05:11.976
308	e69443c5-3f75-4136-9e48-7e592d0cdbd1	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:05:12.28
309	792aaee1-e14c-4c94-92e2-d4bacf69face	queued	\N	Scan created	\N	2026-02-26 06:06:40.443
310	792aaee1-e14c-4c94-92e2-d4bacf69face	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:06:40.485
311	792aaee1-e14c-4c94-92e2-d4bacf69face	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:06:40.804
312	792aaee1-e14c-4c94-92e2-d4bacf69face	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:06:41.123
313	792aaee1-e14c-4c94-92e2-d4bacf69face	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:06:41.432
314	792aaee1-e14c-4c94-92e2-d4bacf69face	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:06:41.75
315	5594a3a4-390c-4bdd-b56c-79bfabeb9e18	queued	\N	Scan created	\N	2026-02-26 06:07:40.441
316	5594a3a4-390c-4bdd-b56c-79bfabeb9e18	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:07:40.449
317	5594a3a4-390c-4bdd-b56c-79bfabeb9e18	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:07:40.764
318	5594a3a4-390c-4bdd-b56c-79bfabeb9e18	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:07:41.084
319	5594a3a4-390c-4bdd-b56c-79bfabeb9e18	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:07:41.405
320	5594a3a4-390c-4bdd-b56c-79bfabeb9e18	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:07:41.723
322	7eccf2d1-8498-45e6-ac2b-b14b2542a1c2	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:08:40.481
323	7eccf2d1-8498-45e6-ac2b-b14b2542a1c2	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:08:40.803
324	7eccf2d1-8498-45e6-ac2b-b14b2542a1c2	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:08:41.121
325	7eccf2d1-8498-45e6-ac2b-b14b2542a1c2	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:08:41.438
326	7eccf2d1-8498-45e6-ac2b-b14b2542a1c2	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:08:41.746
328	15a33a64-a021-4479-b4e8-81aed1f35db2	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:09:40.515
329	15a33a64-a021-4479-b4e8-81aed1f35db2	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:09:40.875
330	15a33a64-a021-4479-b4e8-81aed1f35db2	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:09:41.227
331	15a33a64-a021-4479-b4e8-81aed1f35db2	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:09:41.62
332	15a33a64-a021-4479-b4e8-81aed1f35db2	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:09:41.925
1246	048d4168-0d61-4a70-a5de-ee44aefdb0bd	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:42:12.177
1247	048d4168-0d61-4a70-a5de-ee44aefdb0bd	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:42:12.494
1248	048d4168-0d61-4a70-a5de-ee44aefdb0bd	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:42:12.814
1249	048d4168-0d61-4a70-a5de-ee44aefdb0bd	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:42:13.138
1250	048d4168-0d61-4a70-a5de-ee44aefdb0bd	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:42:13.451
1252	feda98a0-6e77-42d7-bd96-8b4100d24cc5	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:43:12.19
1253	feda98a0-6e77-42d7-bd96-8b4100d24cc5	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:43:12.501
1254	feda98a0-6e77-42d7-bd96-8b4100d24cc5	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:43:12.826
1255	feda98a0-6e77-42d7-bd96-8b4100d24cc5	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:43:13.151
1256	feda98a0-6e77-42d7-bd96-8b4100d24cc5	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:43:13.464
1258	82a2aece-78e9-45d2-bab6-1668eee2d38a	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:44:12.334
1259	82a2aece-78e9-45d2-bab6-1668eee2d38a	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:44:12.711
1260	82a2aece-78e9-45d2-bab6-1668eee2d38a	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:44:13.018
327	15a33a64-a021-4479-b4e8-81aed1f35db2	queued	\N	Scan created	\N	2026-02-26 06:09:40.505
333	7f7f9b6b-6140-409f-b8f2-9877ff6b32ee	queued	\N	Scan created	\N	2026-02-26 06:10:05.723
334	7f7f9b6b-6140-409f-b8f2-9877ff6b32ee	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:10:05.762
335	7f7f9b6b-6140-409f-b8f2-9877ff6b32ee	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:10:06.069
336	7f7f9b6b-6140-409f-b8f2-9877ff6b32ee	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:10:06.381
337	7f7f9b6b-6140-409f-b8f2-9877ff6b32ee	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:10:06.687
338	7f7f9b6b-6140-409f-b8f2-9877ff6b32ee	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:10:06.995
339	2a60cf97-590f-498f-b404-2825fa751420	queued	\N	Scan created	\N	2026-02-26 06:11:05.718
340	2a60cf97-590f-498f-b404-2825fa751420	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:11:05.731
341	2a60cf97-590f-498f-b404-2825fa751420	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:11:06.047
342	2a60cf97-590f-498f-b404-2825fa751420	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:11:06.36
343	2a60cf97-590f-498f-b404-2825fa751420	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:11:06.676
344	2a60cf97-590f-498f-b404-2825fa751420	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:11:06.985
345	46cd7890-413c-461f-a8f1-56460bae71ca	queued	\N	Scan created	\N	2026-02-26 06:12:05.737
346	46cd7890-413c-461f-a8f1-56460bae71ca	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:12:05.747
347	46cd7890-413c-461f-a8f1-56460bae71ca	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:12:06.066
348	46cd7890-413c-461f-a8f1-56460bae71ca	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:12:06.382
349	46cd7890-413c-461f-a8f1-56460bae71ca	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:12:06.702
350	46cd7890-413c-461f-a8f1-56460bae71ca	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:12:07.016
351	fbc0cb2a-104e-4957-9932-3737390e887b	queued	\N	Scan created	\N	2026-02-26 06:13:05.767
352	fbc0cb2a-104e-4957-9932-3737390e887b	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:13:05.777
353	fbc0cb2a-104e-4957-9932-3737390e887b	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:13:06.1
354	fbc0cb2a-104e-4957-9932-3737390e887b	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:13:06.419
355	fbc0cb2a-104e-4957-9932-3737390e887b	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:13:06.735
356	fbc0cb2a-104e-4957-9932-3737390e887b	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:13:07.054
357	ee78c50e-1813-4813-bc06-eaf85376ffc1	queued	\N	Scan created	\N	2026-02-26 06:14:05.801
358	ee78c50e-1813-4813-bc06-eaf85376ffc1	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:14:05.811
359	ee78c50e-1813-4813-bc06-eaf85376ffc1	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:14:06.123
360	ee78c50e-1813-4813-bc06-eaf85376ffc1	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:14:06.444
361	ee78c50e-1813-4813-bc06-eaf85376ffc1	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:14:06.753
362	ee78c50e-1813-4813-bc06-eaf85376ffc1	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:14:07.066
1261	82a2aece-78e9-45d2-bab6-1668eee2d38a	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:44:13.339
1262	82a2aece-78e9-45d2-bab6-1668eee2d38a	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:44:13.649
1293	8ccec1ac-910d-4140-a36b-a226b1c4f143	queued	\N	Scan created	\N	2026-02-26 08:50:35.945
1312	c51d75da-1459-4766-9c1d-d1ae53aa6bca	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:53:35.988
1313	c51d75da-1459-4766-9c1d-d1ae53aa6bca	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:53:36.309
1314	c51d75da-1459-4766-9c1d-d1ae53aa6bca	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:53:36.623
1315	c51d75da-1459-4766-9c1d-d1ae53aa6bca	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:53:36.938
1316	c51d75da-1459-4766-9c1d-d1ae53aa6bca	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:53:37.247
1318	7e119a55-9548-49bd-b30d-ea2614badb85	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:54:36.052
1319	7e119a55-9548-49bd-b30d-ea2614badb85	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:54:36.375
1320	7e119a55-9548-49bd-b30d-ea2614badb85	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:54:36.688
1321	7e119a55-9548-49bd-b30d-ea2614badb85	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:54:37.002
1322	7e119a55-9548-49bd-b30d-ea2614badb85	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:54:37.314
1329	01444663-6fc6-4377-89e3-47bc2163ee1b	queued	\N	Scan created	\N	2026-02-26 08:56:36.05
1335	6147bb2e-7dd6-42ea-8ed9-9ee2ac7ae994	queued	\N	Scan created	\N	2026-02-26 08:57:36.056
1339	6147bb2e-7dd6-42ea-8ed9-9ee2ac7ae994	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:57:45.237
1340	6147bb2e-7dd6-42ea-8ed9-9ee2ac7ae994	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:57:45.545
1342	f93b88a0-4045-4751-b3fd-c00baa7f1db3	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:58:46.745
1343	f93b88a0-4045-4751-b3fd-c00baa7f1db3	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:58:47.058
1344	f93b88a0-4045-4751-b3fd-c00baa7f1db3	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:58:47.375
1345	f93b88a0-4045-4751-b3fd-c00baa7f1db3	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:58:47.695
1346	f93b88a0-4045-4751-b3fd-c00baa7f1db3	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:58:48.012
1348	5defbace-8c26-451c-928d-7f4b952e1f85	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:59:46.76
1349	5defbace-8c26-451c-928d-7f4b952e1f85	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:59:47.071
1350	5defbace-8c26-451c-928d-7f4b952e1f85	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:59:47.391
363	47eb3075-0580-4519-b6fc-07ef0aca8d31	queued	\N	Scan created	\N	2026-02-26 06:15:05.843
364	47eb3075-0580-4519-b6fc-07ef0aca8d31	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:15:05.877
365	47eb3075-0580-4519-b6fc-07ef0aca8d31	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:15:06.19
366	47eb3075-0580-4519-b6fc-07ef0aca8d31	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:15:06.503
367	47eb3075-0580-4519-b6fc-07ef0aca8d31	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:15:06.825
368	47eb3075-0580-4519-b6fc-07ef0aca8d31	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:15:07.136
369	69c0a4a0-1555-4cb2-ab36-c8e1eac60e79	queued	\N	Scan created	\N	2026-02-26 06:16:05.88
370	69c0a4a0-1555-4cb2-ab36-c8e1eac60e79	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:16:05.887
371	69c0a4a0-1555-4cb2-ab36-c8e1eac60e79	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:16:06.201
372	69c0a4a0-1555-4cb2-ab36-c8e1eac60e79	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:16:06.518
373	69c0a4a0-1555-4cb2-ab36-c8e1eac60e79	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:16:06.834
374	69c0a4a0-1555-4cb2-ab36-c8e1eac60e79	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:16:07.148
375	c510a88d-14b9-48bd-a31c-b673ecbf11b9	queued	\N	Scan created	\N	2026-02-26 06:17:06.036
376	c510a88d-14b9-48bd-a31c-b673ecbf11b9	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:17:06.057
377	c510a88d-14b9-48bd-a31c-b673ecbf11b9	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:17:06.37
378	c510a88d-14b9-48bd-a31c-b673ecbf11b9	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:17:06.686
379	c510a88d-14b9-48bd-a31c-b673ecbf11b9	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:17:07.098
380	c510a88d-14b9-48bd-a31c-b673ecbf11b9	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:17:07.477
381	26ecf181-db0c-4002-ae22-d35dab4a5a01	queued	\N	Scan created	\N	2026-02-26 06:18:25.158
382	26ecf181-db0c-4002-ae22-d35dab4a5a01	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:18:25.21
383	26ecf181-db0c-4002-ae22-d35dab4a5a01	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:18:25.528
384	26ecf181-db0c-4002-ae22-d35dab4a5a01	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:18:25.834
385	26ecf181-db0c-4002-ae22-d35dab4a5a01	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:18:26.151
386	26ecf181-db0c-4002-ae22-d35dab4a5a01	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:18:26.466
387	782f5801-4504-4647-b298-9b5bc5a8d77d	queued	\N	Scan created	\N	2026-02-26 06:19:25.166
388	782f5801-4504-4647-b298-9b5bc5a8d77d	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:19:25.176
389	782f5801-4504-4647-b298-9b5bc5a8d77d	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:19:25.489
390	782f5801-4504-4647-b298-9b5bc5a8d77d	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:19:25.8
393	ba52b287-0268-4ebf-8de4-c8d918b48909	queued	\N	Scan created	\N	2026-02-26 06:20:25.206
391	782f5801-4504-4647-b298-9b5bc5a8d77d	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:19:26.121
392	782f5801-4504-4647-b298-9b5bc5a8d77d	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:19:26.439
394	ba52b287-0268-4ebf-8de4-c8d918b48909	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:20:25.218
395	ba52b287-0268-4ebf-8de4-c8d918b48909	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:20:25.535
396	ba52b287-0268-4ebf-8de4-c8d918b48909	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:20:25.858
397	ba52b287-0268-4ebf-8de4-c8d918b48909	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:20:26.18
398	ba52b287-0268-4ebf-8de4-c8d918b48909	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:20:26.499
400	e22fe14d-ecdd-4468-9959-684e1a55401f	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:21:25.258
401	e22fe14d-ecdd-4468-9959-684e1a55401f	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:21:25.573
402	e22fe14d-ecdd-4468-9959-684e1a55401f	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:21:25.887
403	e22fe14d-ecdd-4468-9959-684e1a55401f	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:21:26.208
404	e22fe14d-ecdd-4468-9959-684e1a55401f	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:21:26.518
406	ffeacdea-d748-46a1-8b5e-a1e4a8528b54	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:22:25.299
407	ffeacdea-d748-46a1-8b5e-a1e4a8528b54	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:22:25.617
408	ffeacdea-d748-46a1-8b5e-a1e4a8528b54	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:22:25.934
409	ffeacdea-d748-46a1-8b5e-a1e4a8528b54	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:22:26.251
410	ffeacdea-d748-46a1-8b5e-a1e4a8528b54	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:22:26.563
1263	d87b4a38-8a12-4f96-b9c1-f819ed1f332f	queued	\N	Scan created	\N	2026-02-26 08:45:35.841
1294	8ccec1ac-910d-4140-a36b-a226b1c4f143	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:50:35.976
1295	8ccec1ac-910d-4140-a36b-a226b1c4f143	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:50:36.284
1296	8ccec1ac-910d-4140-a36b-a226b1c4f143	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:50:36.596
1297	8ccec1ac-910d-4140-a36b-a226b1c4f143	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:50:36.906
1298	8ccec1ac-910d-4140-a36b-a226b1c4f143	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:50:37.217
1300	56aba83a-ce29-4876-8b2c-beed00a8dfec	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:51:35.958
1301	56aba83a-ce29-4876-8b2c-beed00a8dfec	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:51:36.268
1317	7e119a55-9548-49bd-b30d-ea2614badb85	queued	\N	Scan created	\N	2026-02-26 08:54:36.042
1323	62d0c697-d3b9-4800-b251-d71f630ba7d9	queued	\N	Scan created	\N	2026-02-26 08:55:36.042
399	e22fe14d-ecdd-4468-9959-684e1a55401f	queued	\N	Scan created	\N	2026-02-26 06:21:25.247
405	ffeacdea-d748-46a1-8b5e-a1e4a8528b54	queued	\N	Scan created	\N	2026-02-26 06:22:25.291
411	0da31771-b5fe-43f7-a9cc-08144f72ceb7	queued	\N	Scan created	\N	2026-02-26 06:23:25.268
412	0da31771-b5fe-43f7-a9cc-08144f72ceb7	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:23:25.299
413	0da31771-b5fe-43f7-a9cc-08144f72ceb7	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:23:25.617
414	0da31771-b5fe-43f7-a9cc-08144f72ceb7	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:23:25.926
415	0da31771-b5fe-43f7-a9cc-08144f72ceb7	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:23:26.24
416	0da31771-b5fe-43f7-a9cc-08144f72ceb7	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:23:26.549
417	e81eb2b8-2e9d-45d1-93d4-3951878f6698	queued	\N	Scan created	\N	2026-02-26 06:24:25.305
418	e81eb2b8-2e9d-45d1-93d4-3951878f6698	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:24:25.315
419	e81eb2b8-2e9d-45d1-93d4-3951878f6698	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:24:25.633
420	e81eb2b8-2e9d-45d1-93d4-3951878f6698	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:24:25.95
421	e81eb2b8-2e9d-45d1-93d4-3951878f6698	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:24:26.264
422	e81eb2b8-2e9d-45d1-93d4-3951878f6698	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:24:26.578
423	6926ca56-92c4-4f14-bfe4-d51619163454	queued	\N	Scan created	\N	2026-02-26 06:25:25.339
424	6926ca56-92c4-4f14-bfe4-d51619163454	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:25:25.349
425	6926ca56-92c4-4f14-bfe4-d51619163454	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:25:25.663
426	6926ca56-92c4-4f14-bfe4-d51619163454	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:25:25.973
427	6926ca56-92c4-4f14-bfe4-d51619163454	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:25:26.293
428	6926ca56-92c4-4f14-bfe4-d51619163454	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:25:26.613
429	27af0e89-c078-4e25-b57a-c09698ac62c4	queued	\N	Scan created	\N	2026-02-26 06:26:25.377
430	27af0e89-c078-4e25-b57a-c09698ac62c4	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:26:25.409
431	27af0e89-c078-4e25-b57a-c09698ac62c4	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:26:25.733
432	27af0e89-c078-4e25-b57a-c09698ac62c4	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:26:26.05
433	27af0e89-c078-4e25-b57a-c09698ac62c4	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:26:26.365
434	27af0e89-c078-4e25-b57a-c09698ac62c4	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:26:26.681
435	344bec1f-575e-4851-9a0e-175a25fd8c44	queued	\N	Scan created	\N	2026-02-26 06:27:25.436
436	344bec1f-575e-4851-9a0e-175a25fd8c44	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:27:25.445
437	344bec1f-575e-4851-9a0e-175a25fd8c44	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:27:25.768
441	213d9813-b2f6-46c2-89b9-4edfb6a408b7	queued	\N	Scan created	\N	2026-02-26 06:28:25.446
495	eb50f271-ee98-4faf-87e1-64ee5998eee6	queued	\N	Scan created	\N	2026-02-26 06:37:25.685
501	8a2630b0-e42c-4de1-b0bd-70c172d503db	queued	\N	Scan created	\N	2026-02-26 06:38:25.716
438	344bec1f-575e-4851-9a0e-175a25fd8c44	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:27:26.088
439	344bec1f-575e-4851-9a0e-175a25fd8c44	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:27:26.402
440	344bec1f-575e-4851-9a0e-175a25fd8c44	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:27:26.719
442	213d9813-b2f6-46c2-89b9-4edfb6a408b7	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:28:25.457
443	213d9813-b2f6-46c2-89b9-4edfb6a408b7	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:28:25.778
444	213d9813-b2f6-46c2-89b9-4edfb6a408b7	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:28:26.097
445	213d9813-b2f6-46c2-89b9-4edfb6a408b7	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:28:26.41
446	213d9813-b2f6-46c2-89b9-4edfb6a408b7	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:28:26.727
447	569f34fa-1ebb-42fe-b439-b773daeeefb9	queued	\N	Scan created	\N	2026-02-26 06:29:25.467
448	569f34fa-1ebb-42fe-b439-b773daeeefb9	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:29:25.477
449	569f34fa-1ebb-42fe-b439-b773daeeefb9	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:29:25.795
450	569f34fa-1ebb-42fe-b439-b773daeeefb9	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:29:26.115
451	569f34fa-1ebb-42fe-b439-b773daeeefb9	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:29:26.432
452	569f34fa-1ebb-42fe-b439-b773daeeefb9	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:29:26.747
453	6089410c-0363-4db9-989b-edd47b2d5553	queued	\N	Scan created	\N	2026-02-26 06:30:25.482
454	6089410c-0363-4db9-989b-edd47b2d5553	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:30:25.487
455	6089410c-0363-4db9-989b-edd47b2d5553	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:30:25.801
456	6089410c-0363-4db9-989b-edd47b2d5553	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:30:26.119
457	6089410c-0363-4db9-989b-edd47b2d5553	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:30:26.431
458	6089410c-0363-4db9-989b-edd47b2d5553	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:30:26.746
459	60b5fc07-5247-4d19-a24f-93289f763a8e	queued	\N	Scan created	\N	2026-02-26 06:31:25.516
460	60b5fc07-5247-4d19-a24f-93289f763a8e	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:31:25.553
461	60b5fc07-5247-4d19-a24f-93289f763a8e	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:31:25.872
462	60b5fc07-5247-4d19-a24f-93289f763a8e	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:31:26.187
463	60b5fc07-5247-4d19-a24f-93289f763a8e	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:31:26.503
464	60b5fc07-5247-4d19-a24f-93289f763a8e	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:31:26.817
465	92aad6a8-1750-4f5b-b177-b4e46adbc641	queued	\N	Scan created	\N	2026-02-26 06:32:25.554
471	27c59590-0d9f-416b-ba19-79caf5a9628a	queued	\N	Scan created	\N	2026-02-26 06:33:25.568
525	219fa6e9-d6d2-4bd3-8ca7-199dcba656db	queued	\N	Scan created	\N	2026-02-26 06:42:25.834
466	92aad6a8-1750-4f5b-b177-b4e46adbc641	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:32:25.563
467	92aad6a8-1750-4f5b-b177-b4e46adbc641	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:32:25.881
468	92aad6a8-1750-4f5b-b177-b4e46adbc641	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:32:26.196
469	92aad6a8-1750-4f5b-b177-b4e46adbc641	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:32:26.514
470	92aad6a8-1750-4f5b-b177-b4e46adbc641	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:32:26.83
472	27c59590-0d9f-416b-ba19-79caf5a9628a	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:33:25.58
473	27c59590-0d9f-416b-ba19-79caf5a9628a	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:33:25.892
474	27c59590-0d9f-416b-ba19-79caf5a9628a	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:33:26.214
475	27c59590-0d9f-416b-ba19-79caf5a9628a	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:33:26.523
476	27c59590-0d9f-416b-ba19-79caf5a9628a	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:33:26.836
477	a337e16b-fc94-40fc-aceb-b20cce5e11d2	queued	\N	Scan created	\N	2026-02-26 06:34:25.604
478	a337e16b-fc94-40fc-aceb-b20cce5e11d2	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:34:25.611
479	a337e16b-fc94-40fc-aceb-b20cce5e11d2	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:34:25.922
480	a337e16b-fc94-40fc-aceb-b20cce5e11d2	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:34:26.238
481	a337e16b-fc94-40fc-aceb-b20cce5e11d2	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:34:26.55
482	a337e16b-fc94-40fc-aceb-b20cce5e11d2	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:34:26.859
483	14b9d7b5-4af6-45aa-8ef3-2ac607720157	queued	\N	Scan created	\N	2026-02-26 06:35:25.605
484	14b9d7b5-4af6-45aa-8ef3-2ac607720157	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:35:25.614
485	14b9d7b5-4af6-45aa-8ef3-2ac607720157	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:35:25.928
486	14b9d7b5-4af6-45aa-8ef3-2ac607720157	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:35:26.244
487	14b9d7b5-4af6-45aa-8ef3-2ac607720157	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:35:26.555
488	14b9d7b5-4af6-45aa-8ef3-2ac607720157	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:35:26.876
489	4e0958c9-6e3f-4aea-879c-f47b70d7ff16	queued	\N	Scan created	\N	2026-02-26 06:36:25.645
490	4e0958c9-6e3f-4aea-879c-f47b70d7ff16	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:36:25.679
491	4e0958c9-6e3f-4aea-879c-f47b70d7ff16	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:36:25.996
492	4e0958c9-6e3f-4aea-879c-f47b70d7ff16	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:36:26.312
493	4e0958c9-6e3f-4aea-879c-f47b70d7ff16	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:36:26.626
494	4e0958c9-6e3f-4aea-879c-f47b70d7ff16	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:36:26.943
496	eb50f271-ee98-4faf-87e1-64ee5998eee6	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:37:25.694
497	eb50f271-ee98-4faf-87e1-64ee5998eee6	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:37:26.01
498	eb50f271-ee98-4faf-87e1-64ee5998eee6	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:37:26.323
499	eb50f271-ee98-4faf-87e1-64ee5998eee6	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:37:26.635
500	eb50f271-ee98-4faf-87e1-64ee5998eee6	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:37:26.947
502	8a2630b0-e42c-4de1-b0bd-70c172d503db	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:38:25.727
503	8a2630b0-e42c-4de1-b0bd-70c172d503db	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:38:26.04
504	8a2630b0-e42c-4de1-b0bd-70c172d503db	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:38:26.351
505	8a2630b0-e42c-4de1-b0bd-70c172d503db	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:38:26.665
506	8a2630b0-e42c-4de1-b0bd-70c172d503db	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:38:26.97
507	c4893b86-7ee2-443c-b52b-d89da735ca1b	queued	\N	Scan created	\N	2026-02-26 06:39:25.779
508	c4893b86-7ee2-443c-b52b-d89da735ca1b	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:39:25.79
509	c4893b86-7ee2-443c-b52b-d89da735ca1b	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:39:26.106
510	c4893b86-7ee2-443c-b52b-d89da735ca1b	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:39:26.425
511	c4893b86-7ee2-443c-b52b-d89da735ca1b	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:39:26.742
512	c4893b86-7ee2-443c-b52b-d89da735ca1b	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:39:27.052
513	0bd961e1-8fa9-4f0f-864c-35be77f56f5e	queued	\N	Scan created	\N	2026-02-26 06:40:25.772
514	0bd961e1-8fa9-4f0f-864c-35be77f56f5e	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:40:25.782
515	0bd961e1-8fa9-4f0f-864c-35be77f56f5e	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:40:26.088
516	0bd961e1-8fa9-4f0f-864c-35be77f56f5e	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:40:26.398
517	0bd961e1-8fa9-4f0f-864c-35be77f56f5e	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:40:26.71
518	0bd961e1-8fa9-4f0f-864c-35be77f56f5e	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:40:27.023
519	22702cfd-b179-4eed-9c95-8e87ed502713	queued	\N	Scan created	\N	2026-02-26 06:41:25.801
520	22702cfd-b179-4eed-9c95-8e87ed502713	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:41:25.833
521	22702cfd-b179-4eed-9c95-8e87ed502713	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:41:26.15
522	22702cfd-b179-4eed-9c95-8e87ed502713	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:41:26.459
523	22702cfd-b179-4eed-9c95-8e87ed502713	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:41:26.776
524	22702cfd-b179-4eed-9c95-8e87ed502713	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:41:27.093
526	219fa6e9-d6d2-4bd3-8ca7-199dcba656db	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:42:25.865
527	219fa6e9-d6d2-4bd3-8ca7-199dcba656db	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:42:26.184
528	219fa6e9-d6d2-4bd3-8ca7-199dcba656db	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:42:26.499
529	219fa6e9-d6d2-4bd3-8ca7-199dcba656db	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:42:26.811
530	219fa6e9-d6d2-4bd3-8ca7-199dcba656db	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:42:27.122
532	c8c8380b-9ffe-4be3-880e-c33351df4ef7	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:43:25.861
533	c8c8380b-9ffe-4be3-880e-c33351df4ef7	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:43:26.173
534	c8c8380b-9ffe-4be3-880e-c33351df4ef7	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:43:26.483
535	c8c8380b-9ffe-4be3-880e-c33351df4ef7	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:43:26.8
536	c8c8380b-9ffe-4be3-880e-c33351df4ef7	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:43:27.113
538	d2f6721f-7bba-45c3-86bc-c59e2e63f47c	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:44:25.879
539	d2f6721f-7bba-45c3-86bc-c59e2e63f47c	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:44:26.185
540	d2f6721f-7bba-45c3-86bc-c59e2e63f47c	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:44:26.499
541	d2f6721f-7bba-45c3-86bc-c59e2e63f47c	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:44:26.81
542	d2f6721f-7bba-45c3-86bc-c59e2e63f47c	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:44:27.121
544	d9927960-da4f-425f-acb5-3e0fa36c6a6a	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:45:25.918
545	d9927960-da4f-425f-acb5-3e0fa36c6a6a	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:45:26.23
546	d9927960-da4f-425f-acb5-3e0fa36c6a6a	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:45:26.541
547	d9927960-da4f-425f-acb5-3e0fa36c6a6a	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:45:26.854
548	d9927960-da4f-425f-acb5-3e0fa36c6a6a	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:45:27.169
550	8bad6011-2c75-4068-996e-143f4e6950cd	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:46:25.981
551	8bad6011-2c75-4068-996e-143f4e6950cd	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:46:26.36
552	8bad6011-2c75-4068-996e-143f4e6950cd	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:46:26.7
531	c8c8380b-9ffe-4be3-880e-c33351df4ef7	queued	\N	Scan created	\N	2026-02-26 06:43:25.849
537	d2f6721f-7bba-45c3-86bc-c59e2e63f47c	queued	\N	Scan created	\N	2026-02-26 06:44:25.868
543	d9927960-da4f-425f-acb5-3e0fa36c6a6a	queued	\N	Scan created	\N	2026-02-26 06:45:25.908
549	8bad6011-2c75-4068-996e-143f4e6950cd	queued	\N	Scan created	\N	2026-02-26 06:46:25.967
1264	d87b4a38-8a12-4f96-b9c1-f819ed1f332f	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:45:35.882
1265	d87b4a38-8a12-4f96-b9c1-f819ed1f332f	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:45:36.204
1266	d87b4a38-8a12-4f96-b9c1-f819ed1f332f	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:45:36.512
1267	d87b4a38-8a12-4f96-b9c1-f819ed1f332f	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:45:36.836
1268	d87b4a38-8a12-4f96-b9c1-f819ed1f332f	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:45:37.148
1270	ba7c323d-6619-406e-8ee6-6b65239e9f50	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:46:35.856
1271	ba7c323d-6619-406e-8ee6-6b65239e9f50	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:46:36.172
1272	ba7c323d-6619-406e-8ee6-6b65239e9f50	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:46:36.488
1273	ba7c323d-6619-406e-8ee6-6b65239e9f50	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:46:36.801
1274	ba7c323d-6619-406e-8ee6-6b65239e9f50	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:46:37.117
1276	b6a1c6a3-4d86-41dd-b2f9-21d546cc5c1a	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:47:35.885
1277	b6a1c6a3-4d86-41dd-b2f9-21d546cc5c1a	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:47:36.199
1278	b6a1c6a3-4d86-41dd-b2f9-21d546cc5c1a	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:47:36.512
1279	b6a1c6a3-4d86-41dd-b2f9-21d546cc5c1a	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:47:36.822
1280	b6a1c6a3-4d86-41dd-b2f9-21d546cc5c1a	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:47:37.136
1282	b98bcf55-f50e-4f0e-bc27-4b81c030e99c	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:48:35.925
1283	b98bcf55-f50e-4f0e-bc27-4b81c030e99c	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:48:36.243
1284	b98bcf55-f50e-4f0e-bc27-4b81c030e99c	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:48:36.561
1285	b98bcf55-f50e-4f0e-bc27-4b81c030e99c	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:48:36.875
1286	b98bcf55-f50e-4f0e-bc27-4b81c030e99c	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:48:37.187
1288	4de26ff9-8648-4ee3-848c-6ecc8c66242e	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:49:35.943
1289	4de26ff9-8648-4ee3-848c-6ecc8c66242e	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:49:36.257
1290	4de26ff9-8648-4ee3-848c-6ecc8c66242e	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:49:36.58
1299	56aba83a-ce29-4876-8b2c-beed00a8dfec	queued	\N	Scan created	\N	2026-02-26 08:51:35.948
1305	6e4b07a2-d04d-4bc0-b64e-fa23a44d562d	queued	\N	Scan created	\N	2026-02-26 08:52:35.972
553	8bad6011-2c75-4068-996e-143f4e6950cd	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:46:27.006
554	8bad6011-2c75-4068-996e-143f4e6950cd	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:46:27.318
555	6b3b8b07-a66c-43e0-87a0-403b9b36205e	queued	\N	Scan created	\N	2026-02-26 06:47:16.3
556	6b3b8b07-a66c-43e0-87a0-403b9b36205e	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:47:16.339
557	6b3b8b07-a66c-43e0-87a0-403b9b36205e	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:47:16.65
558	6b3b8b07-a66c-43e0-87a0-403b9b36205e	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:47:16.964
559	6b3b8b07-a66c-43e0-87a0-403b9b36205e	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:47:17.27
560	6b3b8b07-a66c-43e0-87a0-403b9b36205e	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:47:17.574
561	b117affb-d5e7-4a74-b7e1-9d47875ba2d5	queued	\N	Scan created	\N	2026-02-26 06:48:16.295
562	b117affb-d5e7-4a74-b7e1-9d47875ba2d5	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:48:16.307
563	b117affb-d5e7-4a74-b7e1-9d47875ba2d5	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:48:16.628
564	b117affb-d5e7-4a74-b7e1-9d47875ba2d5	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:48:16.945
565	b117affb-d5e7-4a74-b7e1-9d47875ba2d5	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:48:17.252
566	b117affb-d5e7-4a74-b7e1-9d47875ba2d5	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:48:17.573
567	63c72e57-208e-4d0a-be02-3caf366d1dbc	queued	\N	Scan created	\N	2026-02-26 06:49:16.323
568	63c72e57-208e-4d0a-be02-3caf366d1dbc	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:49:16.334
569	63c72e57-208e-4d0a-be02-3caf366d1dbc	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:49:16.647
570	63c72e57-208e-4d0a-be02-3caf366d1dbc	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:49:16.962
571	63c72e57-208e-4d0a-be02-3caf366d1dbc	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:49:17.275
572	63c72e57-208e-4d0a-be02-3caf366d1dbc	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:49:17.59
573	dd76eca9-dd42-4ebc-b1f0-817f41916ba3	queued	\N	Scan created	\N	2026-02-26 06:50:16.353
574	dd76eca9-dd42-4ebc-b1f0-817f41916ba3	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:50:16.358
575	dd76eca9-dd42-4ebc-b1f0-817f41916ba3	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:50:16.677
576	dd76eca9-dd42-4ebc-b1f0-817f41916ba3	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:50:16.993
577	dd76eca9-dd42-4ebc-b1f0-817f41916ba3	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:50:17.307
578	dd76eca9-dd42-4ebc-b1f0-817f41916ba3	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:50:17.621
579	c0e704bd-1bb2-4226-847a-6c117fd8ad40	queued	\N	Scan created	\N	2026-02-26 06:51:16.377
580	c0e704bd-1bb2-4226-847a-6c117fd8ad40	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:51:16.388
675	09b5720e-f6db-4a8c-adba-2e56a721f2f3	queued	\N	Scan created	\N	2026-02-26 07:07:27.723
581	c0e704bd-1bb2-4226-847a-6c117fd8ad40	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:51:16.701
582	c0e704bd-1bb2-4226-847a-6c117fd8ad40	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:51:17.02
583	c0e704bd-1bb2-4226-847a-6c117fd8ad40	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:51:17.336
584	c0e704bd-1bb2-4226-847a-6c117fd8ad40	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:51:17.647
585	0b53ac89-0567-4255-9ad8-679cab7e7915	queued	\N	Scan created	\N	2026-02-26 06:52:16.433
586	0b53ac89-0567-4255-9ad8-679cab7e7915	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:52:16.457
587	0b53ac89-0567-4255-9ad8-679cab7e7915	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:52:16.776
588	0b53ac89-0567-4255-9ad8-679cab7e7915	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:52:17.094
589	0b53ac89-0567-4255-9ad8-679cab7e7915	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:52:17.407
590	0b53ac89-0567-4255-9ad8-679cab7e7915	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:52:17.724
591	eb7d01e5-149b-41c4-b1eb-fa30c8d209d8	queued	\N	Scan created	\N	2026-02-26 06:53:16.44
592	eb7d01e5-149b-41c4-b1eb-fa30c8d209d8	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:53:16.449
593	eb7d01e5-149b-41c4-b1eb-fa30c8d209d8	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:53:16.768
594	eb7d01e5-149b-41c4-b1eb-fa30c8d209d8	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:53:17.087
595	eb7d01e5-149b-41c4-b1eb-fa30c8d209d8	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:53:17.399
596	eb7d01e5-149b-41c4-b1eb-fa30c8d209d8	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:53:17.708
597	478f9b32-c71a-4668-bad8-0993dda6817e	queued	\N	Scan created	\N	2026-02-26 06:54:16.442
598	478f9b32-c71a-4668-bad8-0993dda6817e	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:54:16.456
599	478f9b32-c71a-4668-bad8-0993dda6817e	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:54:16.768
600	478f9b32-c71a-4668-bad8-0993dda6817e	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:54:17.086
601	478f9b32-c71a-4668-bad8-0993dda6817e	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:54:17.402
602	478f9b32-c71a-4668-bad8-0993dda6817e	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:54:17.711
603	91ac8707-cb10-46dc-b28a-53a17dc6da33	queued	\N	Scan created	\N	2026-02-26 06:55:16.473
604	91ac8707-cb10-46dc-b28a-53a17dc6da33	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:55:16.482
605	91ac8707-cb10-46dc-b28a-53a17dc6da33	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:55:16.803
606	91ac8707-cb10-46dc-b28a-53a17dc6da33	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:55:17.126
607	91ac8707-cb10-46dc-b28a-53a17dc6da33	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:55:17.444
609	5db954c0-a56a-406f-a7c1-e3b032393f3e	queued	\N	Scan created	\N	2026-02-26 06:56:16.509
681	111af853-c24b-4cd5-903d-c1bd76933ad6	queued	\N	Scan created	\N	2026-02-26 07:08:27.761
608	91ac8707-cb10-46dc-b28a-53a17dc6da33	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:55:17.757
610	5db954c0-a56a-406f-a7c1-e3b032393f3e	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:56:16.519
611	5db954c0-a56a-406f-a7c1-e3b032393f3e	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:56:16.833
612	5db954c0-a56a-406f-a7c1-e3b032393f3e	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:56:17.153
613	5db954c0-a56a-406f-a7c1-e3b032393f3e	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:56:17.473
614	5db954c0-a56a-406f-a7c1-e3b032393f3e	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:56:17.792
615	0fe9f2e9-4519-45fe-aa0b-b82db5e25d44	queued	\N	Scan created	\N	2026-02-26 06:57:16.571
616	0fe9f2e9-4519-45fe-aa0b-b82db5e25d44	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:57:16.595
617	0fe9f2e9-4519-45fe-aa0b-b82db5e25d44	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:57:16.912
618	0fe9f2e9-4519-45fe-aa0b-b82db5e25d44	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:57:17.229
619	0fe9f2e9-4519-45fe-aa0b-b82db5e25d44	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:57:17.548
620	0fe9f2e9-4519-45fe-aa0b-b82db5e25d44	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:57:17.866
621	5afa29f2-df94-447c-b158-c97ff705c8f6	queued	\N	Scan created	\N	2026-02-26 06:58:16.584
622	5afa29f2-df94-447c-b158-c97ff705c8f6	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:58:16.595
623	5afa29f2-df94-447c-b158-c97ff705c8f6	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:58:16.913
624	5afa29f2-df94-447c-b158-c97ff705c8f6	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:58:17.227
625	5afa29f2-df94-447c-b158-c97ff705c8f6	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:58:17.546
626	5afa29f2-df94-447c-b158-c97ff705c8f6	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:58:17.857
627	e9e98212-a1b1-4cc6-acb4-62492d0c35cc	queued	\N	Scan created	\N	2026-02-26 06:59:16.594
628	e9e98212-a1b1-4cc6-acb4-62492d0c35cc	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:59:16.604
629	e9e98212-a1b1-4cc6-acb4-62492d0c35cc	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:59:16.915
630	e9e98212-a1b1-4cc6-acb4-62492d0c35cc	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:59:17.237
631	e9e98212-a1b1-4cc6-acb4-62492d0c35cc	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:59:17.559
632	e9e98212-a1b1-4cc6-acb4-62492d0c35cc	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 06:59:17.875
633	585dc344-9f3b-4a4a-bd30-585340802eda	queued	\N	Scan created	\N	2026-02-26 07:00:16.634
634	585dc344-9f3b-4a4a-bd30-585340802eda	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:00:16.648
635	585dc344-9f3b-4a4a-bd30-585340802eda	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:00:16.957
705	8056dec8-be36-4212-8a92-f4ac5b3d1e9b	queued	\N	Scan created	\N	2026-02-26 07:12:27.88
711	52006cb2-f9dd-42d7-8d13-222e48f2ed30	queued	\N	Scan created	\N	2026-02-26 07:13:27.896
636	585dc344-9f3b-4a4a-bd30-585340802eda	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:00:17.27
637	585dc344-9f3b-4a4a-bd30-585340802eda	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:00:17.578
638	585dc344-9f3b-4a4a-bd30-585340802eda	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:00:17.893
639	9331ba97-f234-4b5f-91cb-2c3c5b8229d2	queued	\N	Scan created	\N	2026-02-26 07:01:16.647
640	9331ba97-f234-4b5f-91cb-2c3c5b8229d2	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:01:16.657
641	9331ba97-f234-4b5f-91cb-2c3c5b8229d2	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:01:16.969
642	9331ba97-f234-4b5f-91cb-2c3c5b8229d2	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:01:17.282
643	9331ba97-f234-4b5f-91cb-2c3c5b8229d2	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:01:17.596
644	9331ba97-f234-4b5f-91cb-2c3c5b8229d2	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:01:17.915
645	e0631f14-88df-49c2-958b-7739d4e267a1	queued	\N	Scan created	\N	2026-02-26 07:02:16.681
646	e0631f14-88df-49c2-958b-7739d4e267a1	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:02:16.713
647	e0631f14-88df-49c2-958b-7739d4e267a1	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:02:17.026
648	e0631f14-88df-49c2-958b-7739d4e267a1	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:02:17.343
649	e0631f14-88df-49c2-958b-7739d4e267a1	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:02:17.662
650	e0631f14-88df-49c2-958b-7739d4e267a1	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:02:17.973
651	e8d7865f-996d-4ed7-8940-5dbfa434ce58	queued	\N	Scan created	\N	2026-02-26 07:03:16.684
652	e8d7865f-996d-4ed7-8940-5dbfa434ce58	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:03:25.482
653	e8d7865f-996d-4ed7-8940-5dbfa434ce58	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:03:25.796
654	e8d7865f-996d-4ed7-8940-5dbfa434ce58	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:03:26.105
655	e8d7865f-996d-4ed7-8940-5dbfa434ce58	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:03:26.417
656	e8d7865f-996d-4ed7-8940-5dbfa434ce58	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:03:26.723
657	86a53ac0-6f2d-456d-984e-9cf86f7619ce	queued	\N	Scan created	\N	2026-02-26 07:04:27.65
658	86a53ac0-6f2d-456d-984e-9cf86f7619ce	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:04:27.665
659	86a53ac0-6f2d-456d-984e-9cf86f7619ce	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:04:27.982
660	86a53ac0-6f2d-456d-984e-9cf86f7619ce	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:04:28.295
661	86a53ac0-6f2d-456d-984e-9cf86f7619ce	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:04:28.616
662	86a53ac0-6f2d-456d-984e-9cf86f7619ce	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:04:28.929
663	e0b87adb-9ece-4fcb-9367-6e642e55ff06	queued	\N	Scan created	\N	2026-02-26 07:05:27.654
669	1d12d6cf-56b5-4726-8e7b-6021dcddbb0e	queued	\N	Scan created	\N	2026-02-26 07:06:27.692
664	e0b87adb-9ece-4fcb-9367-6e642e55ff06	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:05:27.664
665	e0b87adb-9ece-4fcb-9367-6e642e55ff06	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:05:27.977
666	e0b87adb-9ece-4fcb-9367-6e642e55ff06	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:05:28.293
667	e0b87adb-9ece-4fcb-9367-6e642e55ff06	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:05:28.61
668	e0b87adb-9ece-4fcb-9367-6e642e55ff06	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:05:28.921
670	1d12d6cf-56b5-4726-8e7b-6021dcddbb0e	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:06:27.703
671	1d12d6cf-56b5-4726-8e7b-6021dcddbb0e	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:06:28.021
672	1d12d6cf-56b5-4726-8e7b-6021dcddbb0e	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:06:28.335
673	1d12d6cf-56b5-4726-8e7b-6021dcddbb0e	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:06:28.648
674	1d12d6cf-56b5-4726-8e7b-6021dcddbb0e	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:06:28.963
676	09b5720e-f6db-4a8c-adba-2e56a721f2f3	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:07:27.73
677	09b5720e-f6db-4a8c-adba-2e56a721f2f3	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:07:28.049
678	09b5720e-f6db-4a8c-adba-2e56a721f2f3	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:07:28.366
679	09b5720e-f6db-4a8c-adba-2e56a721f2f3	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:07:28.682
680	09b5720e-f6db-4a8c-adba-2e56a721f2f3	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:07:28.998
682	111af853-c24b-4cd5-903d-c1bd76933ad6	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:08:27.793
683	111af853-c24b-4cd5-903d-c1bd76933ad6	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:08:28.107
684	111af853-c24b-4cd5-903d-c1bd76933ad6	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:08:28.424
685	111af853-c24b-4cd5-903d-c1bd76933ad6	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:08:28.74
686	111af853-c24b-4cd5-903d-c1bd76933ad6	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:08:29.047
687	49cdee0a-8b20-4b74-82e3-3cd19d658717	queued	\N	Scan created	\N	2026-02-26 07:09:27.812
688	49cdee0a-8b20-4b74-82e3-3cd19d658717	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:09:27.821
689	49cdee0a-8b20-4b74-82e3-3cd19d658717	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:09:28.143
690	49cdee0a-8b20-4b74-82e3-3cd19d658717	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:09:28.463
691	49cdee0a-8b20-4b74-82e3-3cd19d658717	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:09:28.781
693	07b082b1-a51d-426e-856f-f4fc7ff027e7	queued	\N	Scan created	\N	2026-02-26 07:10:27.82
699	fc1173c8-e845-4256-996d-0a2ba591cdf3	queued	\N	Scan created	\N	2026-02-26 07:11:27.858
692	49cdee0a-8b20-4b74-82e3-3cd19d658717	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:09:29.096
694	07b082b1-a51d-426e-856f-f4fc7ff027e7	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:10:27.829
695	07b082b1-a51d-426e-856f-f4fc7ff027e7	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:10:28.133
696	07b082b1-a51d-426e-856f-f4fc7ff027e7	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:10:28.446
697	07b082b1-a51d-426e-856f-f4fc7ff027e7	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:10:28.769
698	07b082b1-a51d-426e-856f-f4fc7ff027e7	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:10:29.08
700	fc1173c8-e845-4256-996d-0a2ba591cdf3	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:11:27.868
701	fc1173c8-e845-4256-996d-0a2ba591cdf3	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:11:28.179
702	fc1173c8-e845-4256-996d-0a2ba591cdf3	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:11:28.492
703	fc1173c8-e845-4256-996d-0a2ba591cdf3	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:11:28.804
704	fc1173c8-e845-4256-996d-0a2ba591cdf3	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:11:29.119
706	8056dec8-be36-4212-8a92-f4ac5b3d1e9b	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:12:27.891
707	8056dec8-be36-4212-8a92-f4ac5b3d1e9b	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:12:28.204
708	8056dec8-be36-4212-8a92-f4ac5b3d1e9b	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:12:28.52
709	8056dec8-be36-4212-8a92-f4ac5b3d1e9b	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:12:28.843
710	8056dec8-be36-4212-8a92-f4ac5b3d1e9b	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:12:29.162
712	52006cb2-f9dd-42d7-8d13-222e48f2ed30	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:13:27.927
713	52006cb2-f9dd-42d7-8d13-222e48f2ed30	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:13:28.239
714	52006cb2-f9dd-42d7-8d13-222e48f2ed30	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:13:28.553
715	52006cb2-f9dd-42d7-8d13-222e48f2ed30	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:13:28.864
716	52006cb2-f9dd-42d7-8d13-222e48f2ed30	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:13:29.183
717	882c6967-600f-4734-8208-3bea05902eb5	queued	\N	Scan created	\N	2026-02-26 07:14:27.91
718	882c6967-600f-4734-8208-3bea05902eb5	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:14:27.921
719	882c6967-600f-4734-8208-3bea05902eb5	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:14:28.238
720	882c6967-600f-4734-8208-3bea05902eb5	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:14:28.556
957	988a4dd4-e4c2-4c1c-83c2-2d5e895df886	queued	\N	Scan created	\N	2026-02-26 07:54:38.112
1149	df63cbfa-e8f9-4279-a4c5-c3bb9f395490	queued	\N	Scan created	\N	2026-02-26 08:26:51.182
721	882c6967-600f-4734-8208-3bea05902eb5	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:14:28.869
722	882c6967-600f-4734-8208-3bea05902eb5	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:14:29.178
723	332d7e51-e061-40d1-9f3f-45caf9a18af5	queued	\N	Scan created	\N	2026-02-26 07:15:27.94
724	332d7e51-e061-40d1-9f3f-45caf9a18af5	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:15:27.952
725	332d7e51-e061-40d1-9f3f-45caf9a18af5	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:15:28.264
726	332d7e51-e061-40d1-9f3f-45caf9a18af5	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:15:28.572
727	332d7e51-e061-40d1-9f3f-45caf9a18af5	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:15:28.895
728	332d7e51-e061-40d1-9f3f-45caf9a18af5	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:15:29.209
729	5c0754cb-410e-49ba-aab9-93fd32c76912	queued	\N	Scan created	\N	2026-02-26 07:16:27.965
730	5c0754cb-410e-49ba-aab9-93fd32c76912	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:16:27.975
731	5c0754cb-410e-49ba-aab9-93fd32c76912	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:16:28.295
732	5c0754cb-410e-49ba-aab9-93fd32c76912	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:16:28.613
733	5c0754cb-410e-49ba-aab9-93fd32c76912	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:16:28.924
734	5c0754cb-410e-49ba-aab9-93fd32c76912	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:16:29.238
735	0f4db452-7137-4704-8769-39154c695def	queued	\N	Scan created	\N	2026-02-26 07:17:27.979
736	0f4db452-7137-4704-8769-39154c695def	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:17:27.988
737	0f4db452-7137-4704-8769-39154c695def	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:17:28.303
738	0f4db452-7137-4704-8769-39154c695def	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:17:28.624
739	0f4db452-7137-4704-8769-39154c695def	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:17:28.94
740	0f4db452-7137-4704-8769-39154c695def	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:17:29.255
741	96727ca3-55b5-46a9-85e6-f88f60eb5a71	queued	\N	Scan created	\N	2026-02-26 07:18:27.98
742	96727ca3-55b5-46a9-85e6-f88f60eb5a71	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:18:28.011
743	96727ca3-55b5-46a9-85e6-f88f60eb5a71	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:18:28.33
744	96727ca3-55b5-46a9-85e6-f88f60eb5a71	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:18:28.652
745	96727ca3-55b5-46a9-85e6-f88f60eb5a71	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:18:28.974
746	96727ca3-55b5-46a9-85e6-f88f60eb5a71	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:18:29.294
747	9696c966-b820-4b94-8a90-90fa249246eb	queued	\N	Scan created	\N	2026-02-26 07:19:28.019
748	9696c966-b820-4b94-8a90-90fa249246eb	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:19:28.029
981	0bb03412-63cd-4fd6-8f60-0c5a5b146420	queued	\N	Scan created	\N	2026-02-26 07:58:33.003
749	9696c966-b820-4b94-8a90-90fa249246eb	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:19:28.347
750	9696c966-b820-4b94-8a90-90fa249246eb	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:19:28.664
751	9696c966-b820-4b94-8a90-90fa249246eb	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:19:28.981
752	9696c966-b820-4b94-8a90-90fa249246eb	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:19:29.296
753	8d302e06-9bf3-4211-add3-61d655c923de	queued	\N	Scan created	\N	2026-02-26 07:20:28.064
754	8d302e06-9bf3-4211-add3-61d655c923de	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:20:28.075
755	8d302e06-9bf3-4211-add3-61d655c923de	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:20:28.387
756	8d302e06-9bf3-4211-add3-61d655c923de	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:20:28.693
757	8d302e06-9bf3-4211-add3-61d655c923de	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:20:29.014
758	8d302e06-9bf3-4211-add3-61d655c923de	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:20:29.326
759	0004f30a-a563-4fa5-8e51-64d98a830759	queued	\N	Scan created	\N	2026-02-26 07:21:28.079
760	0004f30a-a563-4fa5-8e51-64d98a830759	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:21:28.088
761	0004f30a-a563-4fa5-8e51-64d98a830759	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:21:28.408
762	0004f30a-a563-4fa5-8e51-64d98a830759	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:21:28.726
763	0004f30a-a563-4fa5-8e51-64d98a830759	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:21:29.039
764	0004f30a-a563-4fa5-8e51-64d98a830759	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:21:29.352
765	2ef76755-478e-4180-be92-b65ee05f666e	queued	\N	Scan created	\N	2026-02-26 07:22:28.088
766	2ef76755-478e-4180-be92-b65ee05f666e	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:22:28.098
767	2ef76755-478e-4180-be92-b65ee05f666e	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:22:28.419
768	2ef76755-478e-4180-be92-b65ee05f666e	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:22:28.734
769	2ef76755-478e-4180-be92-b65ee05f666e	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:22:29.05
770	2ef76755-478e-4180-be92-b65ee05f666e	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:22:29.36
771	4088313f-f98b-427f-bab4-987dfe4a62d5	queued	\N	Scan created	\N	2026-02-26 07:23:28.128
772	4088313f-f98b-427f-bab4-987dfe4a62d5	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:23:28.16
773	4088313f-f98b-427f-bab4-987dfe4a62d5	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:23:28.477
774	4088313f-f98b-427f-bab4-987dfe4a62d5	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:23:28.793
775	4088313f-f98b-427f-bab4-987dfe4a62d5	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:23:29.106
777	0a79cef8-5cb8-4ef6-ae40-38714cb0bf16	queued	\N	Scan created	\N	2026-02-26 07:24:28.169
987	b75f0781-d362-4bdb-956a-8a8d20455efa	queued	\N	Scan created	\N	2026-02-26 07:59:33.02
776	4088313f-f98b-427f-bab4-987dfe4a62d5	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:23:29.421
778	0a79cef8-5cb8-4ef6-ae40-38714cb0bf16	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:24:28.178
779	0a79cef8-5cb8-4ef6-ae40-38714cb0bf16	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:24:28.493
780	0a79cef8-5cb8-4ef6-ae40-38714cb0bf16	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:24:28.813
781	0a79cef8-5cb8-4ef6-ae40-38714cb0bf16	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:24:29.132
782	0a79cef8-5cb8-4ef6-ae40-38714cb0bf16	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:24:29.45
783	723e73eb-ee67-420c-acb0-af9ab86ca317	queued	\N	Scan created	\N	2026-02-26 07:25:28.208
784	723e73eb-ee67-420c-acb0-af9ab86ca317	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:25:28.219
785	723e73eb-ee67-420c-acb0-af9ab86ca317	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:25:28.538
786	723e73eb-ee67-420c-acb0-af9ab86ca317	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:25:28.861
787	723e73eb-ee67-420c-acb0-af9ab86ca317	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:25:29.166
788	723e73eb-ee67-420c-acb0-af9ab86ca317	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:25:29.485
789	29206ccf-07a5-472a-9410-50fa92d112ef	queued	\N	Scan created	\N	2026-02-26 07:26:28.211
790	29206ccf-07a5-472a-9410-50fa92d112ef	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:26:28.22
791	29206ccf-07a5-472a-9410-50fa92d112ef	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:26:28.533
792	29206ccf-07a5-472a-9410-50fa92d112ef	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:26:28.848
793	29206ccf-07a5-472a-9410-50fa92d112ef	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:26:29.167
794	29206ccf-07a5-472a-9410-50fa92d112ef	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:26:29.478
795	bfafa98d-eb1b-4142-a48f-b54a482a8cdf	queued	\N	Scan created	\N	2026-02-26 07:27:28.227
796	bfafa98d-eb1b-4142-a48f-b54a482a8cdf	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:27:28.236
797	bfafa98d-eb1b-4142-a48f-b54a482a8cdf	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:27:28.545
798	bfafa98d-eb1b-4142-a48f-b54a482a8cdf	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:27:28.859
799	bfafa98d-eb1b-4142-a48f-b54a482a8cdf	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:27:29.181
800	bfafa98d-eb1b-4142-a48f-b54a482a8cdf	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:27:29.496
801	1f99561a-328a-472d-bceb-faf39ae4ff12	queued	\N	Scan created	\N	2026-02-26 07:28:28.263
802	1f99561a-328a-472d-bceb-faf39ae4ff12	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:28:28.299
803	1f99561a-328a-472d-bceb-faf39ae4ff12	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:28:28.616
993	321e903d-0a17-4683-b42f-daa363c60578	queued	\N	Scan created	\N	2026-02-26 08:00:33.225
1209	2785459a-29fd-4700-bd16-f6e2056a2be6	queued	\N	Scan created	\N	2026-02-26 08:36:51.664
804	1f99561a-328a-472d-bceb-faf39ae4ff12	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:28:28.93
805	1f99561a-328a-472d-bceb-faf39ae4ff12	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:28:29.246
806	1f99561a-328a-472d-bceb-faf39ae4ff12	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:28:29.556
807	6015e5c1-c8ad-4f8c-991b-3880ab4d7d12	queued	\N	Scan created	\N	2026-02-26 07:29:28.281
808	6015e5c1-c8ad-4f8c-991b-3880ab4d7d12	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:29:28.292
809	6015e5c1-c8ad-4f8c-991b-3880ab4d7d12	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:29:28.613
810	6015e5c1-c8ad-4f8c-991b-3880ab4d7d12	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:29:28.93
811	6015e5c1-c8ad-4f8c-991b-3880ab4d7d12	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:29:29.239
812	6015e5c1-c8ad-4f8c-991b-3880ab4d7d12	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:29:29.552
813	ed443c1f-c1fb-4a16-905f-f499282d9841	queued	\N	Scan created	\N	2026-02-26 07:30:28.28
814	ed443c1f-c1fb-4a16-905f-f499282d9841	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:30:28.291
815	ed443c1f-c1fb-4a16-905f-f499282d9841	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:30:28.611
816	ed443c1f-c1fb-4a16-905f-f499282d9841	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:30:28.931
817	ed443c1f-c1fb-4a16-905f-f499282d9841	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:30:29.244
818	ed443c1f-c1fb-4a16-905f-f499282d9841	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:30:29.55
819	30179c23-a96e-450c-b1e0-bb11f4ca8a81	queued	\N	Scan created	\N	2026-02-26 07:31:28.297
820	30179c23-a96e-450c-b1e0-bb11f4ca8a81	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:31:28.306
821	30179c23-a96e-450c-b1e0-bb11f4ca8a81	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:31:28.627
822	30179c23-a96e-450c-b1e0-bb11f4ca8a81	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:31:28.946
823	30179c23-a96e-450c-b1e0-bb11f4ca8a81	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:31:29.261
824	30179c23-a96e-450c-b1e0-bb11f4ca8a81	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:31:29.573
825	621eb9e9-de32-4e9a-88b8-02864cc1b8a0	queued	\N	Scan created	\N	2026-02-26 07:32:28.326
826	621eb9e9-de32-4e9a-88b8-02864cc1b8a0	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:32:28.337
827	621eb9e9-de32-4e9a-88b8-02864cc1b8a0	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:32:28.643
828	621eb9e9-de32-4e9a-88b8-02864cc1b8a0	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:32:28.955
829	621eb9e9-de32-4e9a-88b8-02864cc1b8a0	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:32:29.268
830	621eb9e9-de32-4e9a-88b8-02864cc1b8a0	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:32:29.584
831	b32ab2f5-f2e1-4db2-8cb3-89cab9a647b1	queued	\N	Scan created	\N	2026-02-26 07:33:28.357
1041	09059663-edbe-4886-bbd5-65fc09bf0a8e	queued	\N	Scan created	\N	2026-02-26 08:08:50.668
832	b32ab2f5-f2e1-4db2-8cb3-89cab9a647b1	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:33:28.388
833	b32ab2f5-f2e1-4db2-8cb3-89cab9a647b1	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:33:28.703
834	b32ab2f5-f2e1-4db2-8cb3-89cab9a647b1	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:33:29.021
835	b32ab2f5-f2e1-4db2-8cb3-89cab9a647b1	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:33:29.339
836	b32ab2f5-f2e1-4db2-8cb3-89cab9a647b1	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:33:29.649
837	989ff458-bf02-4945-a708-1213873d4362	queued	\N	Scan created	\N	2026-02-26 07:34:28.369
838	989ff458-bf02-4945-a708-1213873d4362	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:34:40.23
839	989ff458-bf02-4945-a708-1213873d4362	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:34:40.541
840	989ff458-bf02-4945-a708-1213873d4362	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:34:40.854
841	989ff458-bf02-4945-a708-1213873d4362	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:34:41.166
842	989ff458-bf02-4945-a708-1213873d4362	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:34:41.471
843	9795df7a-6b39-4113-9da6-0d87a55f6f42	queued	\N	Scan created	\N	2026-02-26 07:35:42.503
844	9795df7a-6b39-4113-9da6-0d87a55f6f42	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:35:42.52
845	9795df7a-6b39-4113-9da6-0d87a55f6f42	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:35:42.834
846	9795df7a-6b39-4113-9da6-0d87a55f6f42	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:35:43.159
847	9795df7a-6b39-4113-9da6-0d87a55f6f42	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:35:43.483
848	9795df7a-6b39-4113-9da6-0d87a55f6f42	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:35:43.792
849	f31a2b85-1021-420d-a9ac-cc7741d58891	queued	\N	Scan created	\N	2026-02-26 07:36:42.529
850	f31a2b85-1021-420d-a9ac-cc7741d58891	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:36:42.539
851	f31a2b85-1021-420d-a9ac-cc7741d58891	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:36:42.848
852	f31a2b85-1021-420d-a9ac-cc7741d58891	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:36:43.169
853	f31a2b85-1021-420d-a9ac-cc7741d58891	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:36:43.484
854	f31a2b85-1021-420d-a9ac-cc7741d58891	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:36:43.797
855	c9ee8b0b-3872-4396-9a6c-b3811ea587d8	queued	\N	Scan created	\N	2026-02-26 07:37:42.543
856	c9ee8b0b-3872-4396-9a6c-b3811ea587d8	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:37:42.55
857	c9ee8b0b-3872-4396-9a6c-b3811ea587d8	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:37:42.863
858	c9ee8b0b-3872-4396-9a6c-b3811ea587d8	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:37:43.184
1047	e39d16da-a8eb-4611-8e2d-8ca9ec9263ef	queued	\N	Scan created	\N	2026-02-26 08:09:50.685
1215	e119984c-c9ff-40ed-b2ef-4c0c53905a8c	queued	\N	Scan created	\N	2026-02-26 08:37:51.681
859	c9ee8b0b-3872-4396-9a6c-b3811ea587d8	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:37:43.508
860	c9ee8b0b-3872-4396-9a6c-b3811ea587d8	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:37:43.826
861	61a224a7-5a1b-4325-81b6-894d2990ead3	queued	\N	Scan created	\N	2026-02-26 07:38:42.545
862	61a224a7-5a1b-4325-81b6-894d2990ead3	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:38:42.554
863	61a224a7-5a1b-4325-81b6-894d2990ead3	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:38:42.877
864	61a224a7-5a1b-4325-81b6-894d2990ead3	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:38:43.194
865	61a224a7-5a1b-4325-81b6-894d2990ead3	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:38:43.517
866	61a224a7-5a1b-4325-81b6-894d2990ead3	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:38:43.834
867	a2c49ab9-c016-4d69-b4e4-82f0565f7108	queued	\N	Scan created	\N	2026-02-26 07:39:42.554
868	a2c49ab9-c016-4d69-b4e4-82f0565f7108	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:39:42.586
869	a2c49ab9-c016-4d69-b4e4-82f0565f7108	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:39:42.909
870	a2c49ab9-c016-4d69-b4e4-82f0565f7108	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:39:43.219
871	a2c49ab9-c016-4d69-b4e4-82f0565f7108	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:39:43.536
872	a2c49ab9-c016-4d69-b4e4-82f0565f7108	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:39:43.84
873	ef843102-f2c2-4c49-a93c-00690a35a8e8	queued	\N	Scan created	\N	2026-02-26 07:40:42.586
874	ef843102-f2c2-4c49-a93c-00690a35a8e8	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:40:42.59
875	ef843102-f2c2-4c49-a93c-00690a35a8e8	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:40:42.91
876	ef843102-f2c2-4c49-a93c-00690a35a8e8	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:40:43.23
877	ef843102-f2c2-4c49-a93c-00690a35a8e8	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:40:43.554
878	ef843102-f2c2-4c49-a93c-00690a35a8e8	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:40:43.864
879	2da8188a-f236-4244-8dbe-ad363cf6c0b7	queued	\N	Scan created	\N	2026-02-26 07:41:42.61
880	2da8188a-f236-4244-8dbe-ad363cf6c0b7	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:41:45.794
881	2da8188a-f236-4244-8dbe-ad363cf6c0b7	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:41:46.106
882	2da8188a-f236-4244-8dbe-ad363cf6c0b7	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:41:46.421
883	2da8188a-f236-4244-8dbe-ad363cf6c0b7	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:41:46.737
884	2da8188a-f236-4244-8dbe-ad363cf6c0b7	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:41:47.043
885	a1eed477-f661-49f3-9cce-f0821ed933d2	queued	\N	Scan created	\N	2026-02-26 07:42:47.984
886	a1eed477-f661-49f3-9cce-f0821ed933d2	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:42:48
1089	1b94627d-3345-432c-886d-a347844da828	queued	\N	Scan created	\N	2026-02-26 08:16:50.862
887	a1eed477-f661-49f3-9cce-f0821ed933d2	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:42:48.316
888	a1eed477-f661-49f3-9cce-f0821ed933d2	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:42:48.64
889	a1eed477-f661-49f3-9cce-f0821ed933d2	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:42:48.949
890	a1eed477-f661-49f3-9cce-f0821ed933d2	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:42:49.265
891	4c9b2360-5fcd-4170-b363-9961bf8c8461	queued	\N	Scan created	\N	2026-02-26 07:43:47.988
892	4c9b2360-5fcd-4170-b363-9961bf8c8461	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:43:48
893	4c9b2360-5fcd-4170-b363-9961bf8c8461	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:43:48.312
894	4c9b2360-5fcd-4170-b363-9961bf8c8461	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:43:48.63
895	4c9b2360-5fcd-4170-b363-9961bf8c8461	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:43:48.952
896	4c9b2360-5fcd-4170-b363-9961bf8c8461	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:43:49.271
897	1a89e1ae-5617-49fc-a7fe-1b671ef0e168	queued	\N	Scan created	\N	2026-02-26 07:44:48.027
898	1a89e1ae-5617-49fc-a7fe-1b671ef0e168	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:44:48.038
899	1a89e1ae-5617-49fc-a7fe-1b671ef0e168	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:44:48.356
900	1a89e1ae-5617-49fc-a7fe-1b671ef0e168	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:44:48.676
901	1a89e1ae-5617-49fc-a7fe-1b671ef0e168	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:44:48.984
902	1a89e1ae-5617-49fc-a7fe-1b671ef0e168	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:44:49.29
903	a0e13f46-57fd-4637-b0b4-5c7df8684f0b	queued	\N	Scan created	\N	2026-02-26 07:45:48.065
904	a0e13f46-57fd-4637-b0b4-5c7df8684f0b	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:45:48.076
905	a0e13f46-57fd-4637-b0b4-5c7df8684f0b	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:45:48.394
906	a0e13f46-57fd-4637-b0b4-5c7df8684f0b	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:45:48.711
907	a0e13f46-57fd-4637-b0b4-5c7df8684f0b	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:45:49.032
908	a0e13f46-57fd-4637-b0b4-5c7df8684f0b	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:45:49.341
909	3238e99e-b237-4c6e-bf19-ab3e480f7d0b	queued	\N	Scan created	\N	2026-02-26 07:46:48.099
910	3238e99e-b237-4c6e-bf19-ab3e480f7d0b	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:46:48.132
911	3238e99e-b237-4c6e-bf19-ab3e480f7d0b	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:46:48.448
912	3238e99e-b237-4c6e-bf19-ab3e480f7d0b	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:46:48.761
913	3238e99e-b237-4c6e-bf19-ab3e480f7d0b	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:46:49.07
915	97709e36-d264-494e-a38e-d3e9ddbe8cdf	queued	\N	Scan created	\N	2026-02-26 07:47:48.297
1095	4e815782-6ebc-4287-b98f-fc91ec796b0e	queued	\N	Scan created	\N	2026-02-26 08:17:50.898
914	3238e99e-b237-4c6e-bf19-ab3e480f7d0b	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:46:49.38
916	97709e36-d264-494e-a38e-d3e9ddbe8cdf	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:47:48.305
917	97709e36-d264-494e-a38e-d3e9ddbe8cdf	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:47:48.61
918	97709e36-d264-494e-a38e-d3e9ddbe8cdf	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:47:48.924
919	97709e36-d264-494e-a38e-d3e9ddbe8cdf	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:47:49.234
920	97709e36-d264-494e-a38e-d3e9ddbe8cdf	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:47:49.567
921	b804e4fd-8df9-4d27-8a1e-03914897a44b	queued	\N	Scan created	\N	2026-02-26 07:48:37.99
922	b804e4fd-8df9-4d27-8a1e-03914897a44b	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:48:38.02
923	b804e4fd-8df9-4d27-8a1e-03914897a44b	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:48:38.327
924	b804e4fd-8df9-4d27-8a1e-03914897a44b	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:48:38.632
925	b804e4fd-8df9-4d27-8a1e-03914897a44b	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:48:38.942
926	b804e4fd-8df9-4d27-8a1e-03914897a44b	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:48:39.249
927	c00343f5-8994-4b86-bb85-4ccb2226ac10	queued	\N	Scan created	\N	2026-02-26 07:49:37.991
928	c00343f5-8994-4b86-bb85-4ccb2226ac10	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:49:38
929	c00343f5-8994-4b86-bb85-4ccb2226ac10	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:49:38.316
930	c00343f5-8994-4b86-bb85-4ccb2226ac10	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:49:38.639
931	c00343f5-8994-4b86-bb85-4ccb2226ac10	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:49:38.958
932	c00343f5-8994-4b86-bb85-4ccb2226ac10	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:49:39.278
933	b8d0e891-2ce5-4492-bc1f-c1a286d1e12a	queued	\N	Scan created	\N	2026-02-26 07:50:38.013
934	b8d0e891-2ce5-4492-bc1f-c1a286d1e12a	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:50:38.022
935	b8d0e891-2ce5-4492-bc1f-c1a286d1e12a	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:50:38.359
936	b8d0e891-2ce5-4492-bc1f-c1a286d1e12a	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:50:38.675
937	b8d0e891-2ce5-4492-bc1f-c1a286d1e12a	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:50:38.989
938	b8d0e891-2ce5-4492-bc1f-c1a286d1e12a	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:50:39.301
939	df3704a5-530a-45e9-8626-d2c3329429e5	queued	\N	Scan created	\N	2026-02-26 07:51:38.023
940	df3704a5-530a-45e9-8626-d2c3329429e5	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:51:38.034
941	df3704a5-530a-45e9-8626-d2c3329429e5	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:51:38.348
945	6f9e668e-8e83-4616-9cb6-2ad78ae00365	queued	\N	Scan created	\N	2026-02-26 07:52:38.049
951	9b127e51-6e0e-4c0f-b525-c3bf4b2f0878	queued	\N	Scan created	\N	2026-02-26 07:53:38.066
942	df3704a5-530a-45e9-8626-d2c3329429e5	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:51:38.661
943	df3704a5-530a-45e9-8626-d2c3329429e5	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:51:38.975
944	df3704a5-530a-45e9-8626-d2c3329429e5	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:51:39.285
946	6f9e668e-8e83-4616-9cb6-2ad78ae00365	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:52:38.058
947	6f9e668e-8e83-4616-9cb6-2ad78ae00365	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:52:38.38
948	6f9e668e-8e83-4616-9cb6-2ad78ae00365	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:52:38.689
949	6f9e668e-8e83-4616-9cb6-2ad78ae00365	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:52:39.006
950	6f9e668e-8e83-4616-9cb6-2ad78ae00365	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:52:39.326
952	9b127e51-6e0e-4c0f-b525-c3bf4b2f0878	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:53:38.072
953	9b127e51-6e0e-4c0f-b525-c3bf4b2f0878	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:53:38.4
954	9b127e51-6e0e-4c0f-b525-c3bf4b2f0878	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:53:38.715
955	9b127e51-6e0e-4c0f-b525-c3bf4b2f0878	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:53:39.033
956	9b127e51-6e0e-4c0f-b525-c3bf4b2f0878	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:53:39.344
958	988a4dd4-e4c2-4c1c-83c2-2d5e895df886	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:54:38.124
959	988a4dd4-e4c2-4c1c-83c2-2d5e895df886	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:54:38.444
960	988a4dd4-e4c2-4c1c-83c2-2d5e895df886	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:54:38.76
961	988a4dd4-e4c2-4c1c-83c2-2d5e895df886	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:54:39.074
962	988a4dd4-e4c2-4c1c-83c2-2d5e895df886	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:54:39.389
963	903339c5-b5fe-4a1c-8348-c3713b4d2dca	queued	\N	Scan created	\N	2026-02-26 07:55:38.166
964	903339c5-b5fe-4a1c-8348-c3713b4d2dca	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:55:38.176
965	903339c5-b5fe-4a1c-8348-c3713b4d2dca	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:55:38.489
966	903339c5-b5fe-4a1c-8348-c3713b4d2dca	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:55:38.795
967	903339c5-b5fe-4a1c-8348-c3713b4d2dca	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:55:39.102
968	903339c5-b5fe-4a1c-8348-c3713b4d2dca	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:55:39.407
969	7fdf7631-d391-4ac0-b593-b4e1c08aa68a	queued	\N	Scan created	\N	2026-02-26 07:56:32.957
970	7fdf7631-d391-4ac0-b593-b4e1c08aa68a	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:56:32.993
975	b5ee5640-36df-403b-a864-7ec3a9cb2d0f	queued	\N	Scan created	\N	2026-02-26 07:57:32.97
971	7fdf7631-d391-4ac0-b593-b4e1c08aa68a	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:56:33.299
972	7fdf7631-d391-4ac0-b593-b4e1c08aa68a	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:56:33.608
973	7fdf7631-d391-4ac0-b593-b4e1c08aa68a	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:56:33.914
974	7fdf7631-d391-4ac0-b593-b4e1c08aa68a	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:56:34.219
976	b5ee5640-36df-403b-a864-7ec3a9cb2d0f	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:57:32.982
977	b5ee5640-36df-403b-a864-7ec3a9cb2d0f	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:57:33.297
978	b5ee5640-36df-403b-a864-7ec3a9cb2d0f	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:57:33.613
979	b5ee5640-36df-403b-a864-7ec3a9cb2d0f	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:57:33.929
980	b5ee5640-36df-403b-a864-7ec3a9cb2d0f	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:57:34.243
982	0bb03412-63cd-4fd6-8f60-0c5a5b146420	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:58:33.015
983	0bb03412-63cd-4fd6-8f60-0c5a5b146420	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:58:33.325
984	0bb03412-63cd-4fd6-8f60-0c5a5b146420	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:58:33.642
985	0bb03412-63cd-4fd6-8f60-0c5a5b146420	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:58:33.953
986	0bb03412-63cd-4fd6-8f60-0c5a5b146420	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:58:34.265
988	b75f0781-d362-4bdb-956a-8a8d20455efa	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:59:33.025
989	b75f0781-d362-4bdb-956a-8a8d20455efa	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:59:33.339
990	b75f0781-d362-4bdb-956a-8a8d20455efa	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:59:33.659
991	b75f0781-d362-4bdb-956a-8a8d20455efa	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:59:33.973
992	b75f0781-d362-4bdb-956a-8a8d20455efa	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 07:59:34.293
994	321e903d-0a17-4683-b42f-daa363c60578	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:00:33.238
995	321e903d-0a17-4683-b42f-daa363c60578	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:00:33.647
996	321e903d-0a17-4683-b42f-daa363c60578	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:00:33.957
997	321e903d-0a17-4683-b42f-daa363c60578	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:00:34.264
998	321e903d-0a17-4683-b42f-daa363c60578	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:00:34.567
999	a284244b-0635-461a-bc61-296e0358fed4	queued	\N	Scan created	\N	2026-02-26 08:01:50.52
1119	19739215-081c-4e1e-92b4-965d6d1bd701	queued	\N	Scan created	\N	2026-02-26 08:21:51.013
1125	0aa1ea9e-29e3-419f-a049-fbaf618efe3a	queued	\N	Scan created	\N	2026-02-26 08:22:51.051
1000	a284244b-0635-461a-bc61-296e0358fed4	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:01:50.549
1001	a284244b-0635-461a-bc61-296e0358fed4	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:01:50.868
1002	a284244b-0635-461a-bc61-296e0358fed4	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:01:51.182
1003	a284244b-0635-461a-bc61-296e0358fed4	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:01:51.505
1004	a284244b-0635-461a-bc61-296e0358fed4	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:01:51.819
1005	92621df9-19d4-4dc0-b491-7a96ae0dd9a0	queued	\N	Scan created	\N	2026-02-26 08:02:50.545
1006	92621df9-19d4-4dc0-b491-7a96ae0dd9a0	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:02:50.556
1007	92621df9-19d4-4dc0-b491-7a96ae0dd9a0	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:02:50.873
1008	92621df9-19d4-4dc0-b491-7a96ae0dd9a0	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:02:51.194
1009	92621df9-19d4-4dc0-b491-7a96ae0dd9a0	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:02:51.511
1010	92621df9-19d4-4dc0-b491-7a96ae0dd9a0	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:02:51.829
1011	a21cc20a-df69-4139-96de-0ec8df69e919	queued	\N	Scan created	\N	2026-02-26 08:03:50.577
1012	a21cc20a-df69-4139-96de-0ec8df69e919	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:03:50.587
1013	a21cc20a-df69-4139-96de-0ec8df69e919	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:03:50.901
1014	a21cc20a-df69-4139-96de-0ec8df69e919	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:03:51.22
1015	a21cc20a-df69-4139-96de-0ec8df69e919	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:03:51.534
1016	a21cc20a-df69-4139-96de-0ec8df69e919	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:03:51.842
1017	1407259e-d52b-4dc4-ac3a-d3dffa9a4fac	queued	\N	Scan created	\N	2026-02-26 08:04:50.583
1018	1407259e-d52b-4dc4-ac3a-d3dffa9a4fac	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:04:50.593
1019	1407259e-d52b-4dc4-ac3a-d3dffa9a4fac	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:04:50.907
1020	1407259e-d52b-4dc4-ac3a-d3dffa9a4fac	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:04:51.22
1021	1407259e-d52b-4dc4-ac3a-d3dffa9a4fac	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:04:51.525
1022	1407259e-d52b-4dc4-ac3a-d3dffa9a4fac	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:04:51.834
1023	3abe1dbb-08ac-44e5-8c79-696c8b3f8610	queued	\N	Scan created	\N	2026-02-26 08:05:50.618
1024	3abe1dbb-08ac-44e5-8c79-696c8b3f8610	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:05:50.626
1025	3abe1dbb-08ac-44e5-8c79-696c8b3f8610	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:05:50.946
1026	3abe1dbb-08ac-44e5-8c79-696c8b3f8610	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:05:51.263
1029	4de5c34a-6a6c-4836-ac5c-00e464a5c3b8	queued	\N	Scan created	\N	2026-02-26 08:06:50.596
1035	499e70de-a44d-4a1b-ab13-3ec76471a7a7	queued	\N	Scan created	\N	2026-02-26 08:07:50.635
1027	3abe1dbb-08ac-44e5-8c79-696c8b3f8610	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:05:51.577
1028	3abe1dbb-08ac-44e5-8c79-696c8b3f8610	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:05:51.896
1030	4de5c34a-6a6c-4836-ac5c-00e464a5c3b8	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:06:50.617
1031	4de5c34a-6a6c-4836-ac5c-00e464a5c3b8	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:06:50.933
1032	4de5c34a-6a6c-4836-ac5c-00e464a5c3b8	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:06:51.246
1033	4de5c34a-6a6c-4836-ac5c-00e464a5c3b8	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:06:51.561
1034	4de5c34a-6a6c-4836-ac5c-00e464a5c3b8	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:06:51.871
1036	499e70de-a44d-4a1b-ab13-3ec76471a7a7	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:07:50.645
1037	499e70de-a44d-4a1b-ab13-3ec76471a7a7	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:07:50.964
1038	499e70de-a44d-4a1b-ab13-3ec76471a7a7	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:07:51.281
1039	499e70de-a44d-4a1b-ab13-3ec76471a7a7	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:07:51.601
1040	499e70de-a44d-4a1b-ab13-3ec76471a7a7	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:07:51.92
1042	09059663-edbe-4886-bbd5-65fc09bf0a8e	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:08:50.676
1043	09059663-edbe-4886-bbd5-65fc09bf0a8e	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:08:50.988
1044	09059663-edbe-4886-bbd5-65fc09bf0a8e	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:08:51.309
1045	09059663-edbe-4886-bbd5-65fc09bf0a8e	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:08:51.621
1046	09059663-edbe-4886-bbd5-65fc09bf0a8e	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:08:51.931
1048	e39d16da-a8eb-4611-8e2d-8ca9ec9263ef	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:09:50.695
1049	e39d16da-a8eb-4611-8e2d-8ca9ec9263ef	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:09:51.008
1050	e39d16da-a8eb-4611-8e2d-8ca9ec9263ef	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:09:51.318
1051	e39d16da-a8eb-4611-8e2d-8ca9ec9263ef	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:09:51.63
1052	e39d16da-a8eb-4611-8e2d-8ca9ec9263ef	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:09:51.94
1053	fb393a25-5d0e-4f4a-9fff-bb51cd659ffc	queued	\N	Scan created	\N	2026-02-26 08:10:50.751
1054	fb393a25-5d0e-4f4a-9fff-bb51cd659ffc	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:10:50.759
1055	fb393a25-5d0e-4f4a-9fff-bb51cd659ffc	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:10:51.081
1059	f3beeae4-afec-4ca7-9a8e-9e754abbf139	queued	\N	Scan created	\N	2026-02-26 08:11:50.761
1065	483e74b3-8fb5-452f-bf66-cb5d4c53ca8e	queued	\N	Scan created	\N	2026-02-26 08:12:50.791
1056	fb393a25-5d0e-4f4a-9fff-bb51cd659ffc	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:10:51.395
1057	fb393a25-5d0e-4f4a-9fff-bb51cd659ffc	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:10:51.71
1058	fb393a25-5d0e-4f4a-9fff-bb51cd659ffc	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:10:52.024
1060	f3beeae4-afec-4ca7-9a8e-9e754abbf139	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:11:50.783
1061	f3beeae4-afec-4ca7-9a8e-9e754abbf139	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:11:51.097
1062	f3beeae4-afec-4ca7-9a8e-9e754abbf139	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:11:51.414
1063	f3beeae4-afec-4ca7-9a8e-9e754abbf139	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:11:51.731
1064	f3beeae4-afec-4ca7-9a8e-9e754abbf139	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:11:52.04
1066	483e74b3-8fb5-452f-bf66-cb5d4c53ca8e	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:12:50.802
1067	483e74b3-8fb5-452f-bf66-cb5d4c53ca8e	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:12:51.116
1068	483e74b3-8fb5-452f-bf66-cb5d4c53ca8e	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:12:51.428
1069	483e74b3-8fb5-452f-bf66-cb5d4c53ca8e	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:12:51.746
1070	483e74b3-8fb5-452f-bf66-cb5d4c53ca8e	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:12:52.063
1071	7156865d-88cf-485d-a68b-74231991f49c	queued	\N	Scan created	\N	2026-02-26 08:13:50.823
1072	7156865d-88cf-485d-a68b-74231991f49c	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:13:50.833
1073	7156865d-88cf-485d-a68b-74231991f49c	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:13:51.151
1074	7156865d-88cf-485d-a68b-74231991f49c	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:13:51.469
1075	7156865d-88cf-485d-a68b-74231991f49c	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:13:51.79
1076	7156865d-88cf-485d-a68b-74231991f49c	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:13:52.107
1077	c27abe50-11ea-480e-9f5b-e8cb679a7cf8	queued	\N	Scan created	\N	2026-02-26 08:14:50.827
1078	c27abe50-11ea-480e-9f5b-e8cb679a7cf8	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:14:50.837
1079	c27abe50-11ea-480e-9f5b-e8cb679a7cf8	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:14:51.149
1080	c27abe50-11ea-480e-9f5b-e8cb679a7cf8	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:14:51.462
1081	c27abe50-11ea-480e-9f5b-e8cb679a7cf8	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:14:51.774
1082	c27abe50-11ea-480e-9f5b-e8cb679a7cf8	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:14:52.084
1083	5e94972a-dc21-45a7-b853-7aea8ed2d380	queued	\N	Scan created	\N	2026-02-26 08:15:50.836
1084	5e94972a-dc21-45a7-b853-7aea8ed2d380	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:15:50.845
1085	5e94972a-dc21-45a7-b853-7aea8ed2d380	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:15:51.167
1086	5e94972a-dc21-45a7-b853-7aea8ed2d380	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:15:51.484
1087	5e94972a-dc21-45a7-b853-7aea8ed2d380	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:15:51.797
1088	5e94972a-dc21-45a7-b853-7aea8ed2d380	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:15:52.114
1090	1b94627d-3345-432c-886d-a347844da828	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:16:50.894
1091	1b94627d-3345-432c-886d-a347844da828	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:16:51.201
1092	1b94627d-3345-432c-886d-a347844da828	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:16:51.517
1093	1b94627d-3345-432c-886d-a347844da828	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:16:51.832
1094	1b94627d-3345-432c-886d-a347844da828	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:16:52.144
1096	4e815782-6ebc-4287-b98f-fc91ec796b0e	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:17:50.909
1097	4e815782-6ebc-4287-b98f-fc91ec796b0e	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:17:51.221
1098	4e815782-6ebc-4287-b98f-fc91ec796b0e	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:17:51.541
1099	4e815782-6ebc-4287-b98f-fc91ec796b0e	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:17:51.853
1100	4e815782-6ebc-4287-b98f-fc91ec796b0e	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:17:52.163
1101	2a2d1429-c99e-474b-80f5-be69f150b434	queued	\N	Scan created	\N	2026-02-26 08:18:50.952
1102	2a2d1429-c99e-474b-80f5-be69f150b434	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:18:50.961
1103	2a2d1429-c99e-474b-80f5-be69f150b434	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:18:51.283
1104	2a2d1429-c99e-474b-80f5-be69f150b434	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:18:51.602
1105	2a2d1429-c99e-474b-80f5-be69f150b434	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:18:51.918
1106	2a2d1429-c99e-474b-80f5-be69f150b434	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:18:52.232
1107	8750ed25-7937-448b-bb40-ad610362b9da	queued	\N	Scan created	\N	2026-02-26 08:19:50.957
1108	8750ed25-7937-448b-bb40-ad610362b9da	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:19:50.969
1109	8750ed25-7937-448b-bb40-ad610362b9da	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:19:51.281
1110	8750ed25-7937-448b-bb40-ad610362b9da	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:19:51.593
1111	8750ed25-7937-448b-bb40-ad610362b9da	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:19:51.91
1112	8750ed25-7937-448b-bb40-ad610362b9da	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:19:52.221
1113	459a80ad-e3c0-4763-bf7e-eae5b31d71ab	queued	\N	Scan created	\N	2026-02-26 08:20:50.99
1114	459a80ad-e3c0-4763-bf7e-eae5b31d71ab	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:20:51
1115	459a80ad-e3c0-4763-bf7e-eae5b31d71ab	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:20:51.311
1116	459a80ad-e3c0-4763-bf7e-eae5b31d71ab	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:20:51.624
1117	459a80ad-e3c0-4763-bf7e-eae5b31d71ab	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:20:51.936
1118	459a80ad-e3c0-4763-bf7e-eae5b31d71ab	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:20:52.247
1120	19739215-081c-4e1e-92b4-965d6d1bd701	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:21:51.046
1121	19739215-081c-4e1e-92b4-965d6d1bd701	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:21:51.354
1122	19739215-081c-4e1e-92b4-965d6d1bd701	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:21:51.665
1123	19739215-081c-4e1e-92b4-965d6d1bd701	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:21:51.984
1124	19739215-081c-4e1e-92b4-965d6d1bd701	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:21:52.303
1126	0aa1ea9e-29e3-419f-a049-fbaf618efe3a	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:22:51.062
1127	0aa1ea9e-29e3-419f-a049-fbaf618efe3a	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:22:51.378
1128	0aa1ea9e-29e3-419f-a049-fbaf618efe3a	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:22:51.693
1129	0aa1ea9e-29e3-419f-a049-fbaf618efe3a	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:22:52.005
1130	0aa1ea9e-29e3-419f-a049-fbaf618efe3a	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:22:52.326
1131	fe07a089-b3de-4212-a7bc-4bdbe396423c	queued	\N	Scan created	\N	2026-02-26 08:23:51.107
1132	fe07a089-b3de-4212-a7bc-4bdbe396423c	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:23:51.114
1133	fe07a089-b3de-4212-a7bc-4bdbe396423c	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:23:51.434
1134	fe07a089-b3de-4212-a7bc-4bdbe396423c	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:23:51.75
1135	fe07a089-b3de-4212-a7bc-4bdbe396423c	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:23:52.066
1136	fe07a089-b3de-4212-a7bc-4bdbe396423c	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:23:52.374
1137	d59029ee-9f0c-41bc-987e-e40f5c26ec70	queued	\N	Scan created	\N	2026-02-26 08:24:51.114
1138	d59029ee-9f0c-41bc-987e-e40f5c26ec70	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:24:51.123
1139	d59029ee-9f0c-41bc-987e-e40f5c26ec70	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:24:51.438
1140	d59029ee-9f0c-41bc-987e-e40f5c26ec70	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:24:51.757
1141	d59029ee-9f0c-41bc-987e-e40f5c26ec70	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:24:52.068
1143	fb0d9a6e-40be-4fc6-bed1-dd7fd9eb8aef	queued	\N	Scan created	\N	2026-02-26 08:25:51.149
1142	d59029ee-9f0c-41bc-987e-e40f5c26ec70	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:24:52.38
1144	fb0d9a6e-40be-4fc6-bed1-dd7fd9eb8aef	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:25:51.158
1145	fb0d9a6e-40be-4fc6-bed1-dd7fd9eb8aef	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:25:51.474
1146	fb0d9a6e-40be-4fc6-bed1-dd7fd9eb8aef	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:25:51.792
1147	fb0d9a6e-40be-4fc6-bed1-dd7fd9eb8aef	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:25:52.105
1148	fb0d9a6e-40be-4fc6-bed1-dd7fd9eb8aef	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:25:52.416
1150	df63cbfa-e8f9-4279-a4c5-c3bb9f395490	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:26:51.214
1151	df63cbfa-e8f9-4279-a4c5-c3bb9f395490	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:26:51.526
1152	df63cbfa-e8f9-4279-a4c5-c3bb9f395490	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:26:51.841
1153	df63cbfa-e8f9-4279-a4c5-c3bb9f395490	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:26:52.152
1154	df63cbfa-e8f9-4279-a4c5-c3bb9f395490	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:26:52.472
1155	ccf1fb3c-3667-4dd9-9e6c-89d9e46c4d62	queued	\N	Scan created	\N	2026-02-26 08:27:50.93
1156	ccf1fb3c-3667-4dd9-9e6c-89d9e46c4d62	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:27:50.963
1157	ccf1fb3c-3667-4dd9-9e6c-89d9e46c4d62	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:27:51.271
1158	ccf1fb3c-3667-4dd9-9e6c-89d9e46c4d62	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:27:51.577
1159	ccf1fb3c-3667-4dd9-9e6c-89d9e46c4d62	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:27:51.882
1160	ccf1fb3c-3667-4dd9-9e6c-89d9e46c4d62	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:27:52.185
1161	7643f718-f12e-4865-8755-f8fee64ab281	queued	\N	Scan created	\N	2026-02-26 08:28:50.915
1162	7643f718-f12e-4865-8755-f8fee64ab281	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:28:50.923
1163	7643f718-f12e-4865-8755-f8fee64ab281	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:28:51.24
1164	7643f718-f12e-4865-8755-f8fee64ab281	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:28:51.557
1165	7643f718-f12e-4865-8755-f8fee64ab281	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:28:51.874
1166	7643f718-f12e-4865-8755-f8fee64ab281	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:28:52.192
1167	5e923fb0-50f8-4068-8d2b-62cd3c79c105	queued	\N	Scan created	\N	2026-02-26 08:29:50.954
1168	5e923fb0-50f8-4068-8d2b-62cd3c79c105	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:29:50.965
1169	5e923fb0-50f8-4068-8d2b-62cd3c79c105	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:29:51.282
1170	5e923fb0-50f8-4068-8d2b-62cd3c79c105	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:29:51.605
1171	5e923fb0-50f8-4068-8d2b-62cd3c79c105	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:29:51.921
1172	5e923fb0-50f8-4068-8d2b-62cd3c79c105	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:29:52.238
1173	7a1e3eae-c1ec-4942-aa40-3de190aab2d7	queued	\N	Scan created	\N	2026-02-26 08:30:50.983
1174	7a1e3eae-c1ec-4942-aa40-3de190aab2d7	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:30:50.997
1175	7a1e3eae-c1ec-4942-aa40-3de190aab2d7	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:30:51.303
1176	7a1e3eae-c1ec-4942-aa40-3de190aab2d7	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:30:51.616
1177	7a1e3eae-c1ec-4942-aa40-3de190aab2d7	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:30:51.935
1178	7a1e3eae-c1ec-4942-aa40-3de190aab2d7	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:30:52.249
1179	4653ea7d-26f4-4879-80b0-e1da75e043d6	queued	\N	Scan created	\N	2026-02-26 08:31:51.015
1180	4653ea7d-26f4-4879-80b0-e1da75e043d6	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:31:51.028
1181	4653ea7d-26f4-4879-80b0-e1da75e043d6	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:31:51.338
1182	4653ea7d-26f4-4879-80b0-e1da75e043d6	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:31:51.654
1183	4653ea7d-26f4-4879-80b0-e1da75e043d6	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:31:51.966
1184	4653ea7d-26f4-4879-80b0-e1da75e043d6	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:31:52.275
1185	f9b8e5ed-f90e-443b-829d-ad31f0941e2b	queued	\N	Scan created	\N	2026-02-26 08:32:51.03
1186	f9b8e5ed-f90e-443b-829d-ad31f0941e2b	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:32:51.062
1187	f9b8e5ed-f90e-443b-829d-ad31f0941e2b	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:32:51.38
1188	f9b8e5ed-f90e-443b-829d-ad31f0941e2b	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:32:51.692
1189	f9b8e5ed-f90e-443b-829d-ad31f0941e2b	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:32:52.013
1190	f9b8e5ed-f90e-443b-829d-ad31f0941e2b	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:32:52.33
1191	9f4f72da-4ae5-4687-9e69-aed4d37155de	queued	\N	Scan created	\N	2026-02-26 08:33:51.07
1192	9f4f72da-4ae5-4687-9e69-aed4d37155de	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:33:51.08
1193	9f4f72da-4ae5-4687-9e69-aed4d37155de	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:33:51.388
1194	9f4f72da-4ae5-4687-9e69-aed4d37155de	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:33:51.708
1195	9f4f72da-4ae5-4687-9e69-aed4d37155de	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:33:52.019
1196	9f4f72da-4ae5-4687-9e69-aed4d37155de	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:33:52.33
1197	dca62beb-44fb-4b2a-bfc2-1e737dd4e8fc	queued	\N	Scan created	\N	2026-02-26 08:34:51.664
1198	dca62beb-44fb-4b2a-bfc2-1e737dd4e8fc	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:34:51.713
1203	f0dad537-f37b-428d-a64a-996220f5acea	queued	\N	Scan created	\N	2026-02-26 08:35:51.639
1199	dca62beb-44fb-4b2a-bfc2-1e737dd4e8fc	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:34:52.023
1200	dca62beb-44fb-4b2a-bfc2-1e737dd4e8fc	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:34:52.331
1201	dca62beb-44fb-4b2a-bfc2-1e737dd4e8fc	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:34:52.637
1202	dca62beb-44fb-4b2a-bfc2-1e737dd4e8fc	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:34:52.942
1204	f0dad537-f37b-428d-a64a-996220f5acea	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:35:51.65
1205	f0dad537-f37b-428d-a64a-996220f5acea	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:35:51.965
1206	f0dad537-f37b-428d-a64a-996220f5acea	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:35:52.288
1207	f0dad537-f37b-428d-a64a-996220f5acea	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:35:52.603
1208	f0dad537-f37b-428d-a64a-996220f5acea	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:35:52.917
1210	2785459a-29fd-4700-bd16-f6e2056a2be6	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:36:51.674
1211	2785459a-29fd-4700-bd16-f6e2056a2be6	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:36:51.989
1212	2785459a-29fd-4700-bd16-f6e2056a2be6	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:36:52.306
1213	2785459a-29fd-4700-bd16-f6e2056a2be6	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:36:52.614
1214	2785459a-29fd-4700-bd16-f6e2056a2be6	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:36:52.929
1216	e119984c-c9ff-40ed-b2ef-4c0c53905a8c	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:37:51.692
1217	e119984c-c9ff-40ed-b2ef-4c0c53905a8c	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:37:52.014
1218	e119984c-c9ff-40ed-b2ef-4c0c53905a8c	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:37:52.334
1219	e119984c-c9ff-40ed-b2ef-4c0c53905a8c	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:37:52.648
1220	e119984c-c9ff-40ed-b2ef-4c0c53905a8c	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:37:52.967
1222	4a3983ad-d35d-41ab-897e-1913f66aa389	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:38:51.705
1223	4a3983ad-d35d-41ab-897e-1913f66aa389	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:38:52.016
1224	4a3983ad-d35d-41ab-897e-1913f66aa389	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:38:52.331
1225	4a3983ad-d35d-41ab-897e-1913f66aa389	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:38:52.652
1226	4a3983ad-d35d-41ab-897e-1913f66aa389	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:38:52.967
1269	ba7c323d-6619-406e-8ee6-6b65239e9f50	queued	\N	Scan created	\N	2026-02-26 08:46:35.839
1275	b6a1c6a3-4d86-41dd-b2f9-21d546cc5c1a	queued	\N	Scan created	\N	2026-02-26 08:47:35.875
1281	b98bcf55-f50e-4f0e-bc27-4b81c030e99c	queued	\N	Scan created	\N	2026-02-26 08:48:35.915
1221	4a3983ad-d35d-41ab-897e-1913f66aa389	queued	\N	Scan created	\N	2026-02-26 08:38:51.696
1227	71c0152c-ac86-4aa6-a1db-be9169bebfb6	queued	\N	Scan created	\N	2026-02-26 08:39:51.754
1228	71c0152c-ac86-4aa6-a1db-be9169bebfb6	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:39:51.78
1229	71c0152c-ac86-4aa6-a1db-be9169bebfb6	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:39:52.102
1230	71c0152c-ac86-4aa6-a1db-be9169bebfb6	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:39:52.421
1231	71c0152c-ac86-4aa6-a1db-be9169bebfb6	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:39:52.736
1232	71c0152c-ac86-4aa6-a1db-be9169bebfb6	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:39:53.051
1233	f076e94f-6afe-4c94-868c-3d701e6b4f9d	queued	\N	Scan created	\N	2026-02-26 08:40:51.877
1234	f076e94f-6afe-4c94-868c-3d701e6b4f9d	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:40:51.921
1235	f076e94f-6afe-4c94-868c-3d701e6b4f9d	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:40:52.292
1236	f076e94f-6afe-4c94-868c-3d701e6b4f9d	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:40:52.617
1237	f076e94f-6afe-4c94-868c-3d701e6b4f9d	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:40:53.018
1238	f076e94f-6afe-4c94-868c-3d701e6b4f9d	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:40:53.323
1239	cfc59097-d8f8-4a0a-b943-01060da535e5	queued	\N	Scan created	\N	2026-02-26 08:41:12.148
1240	cfc59097-d8f8-4a0a-b943-01060da535e5	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:41:12.184
1241	cfc59097-d8f8-4a0a-b943-01060da535e5	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:41:12.491
1242	cfc59097-d8f8-4a0a-b943-01060da535e5	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:41:12.807
1243	cfc59097-d8f8-4a0a-b943-01060da535e5	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:41:13.114
1244	cfc59097-d8f8-4a0a-b943-01060da535e5	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:41:13.421
1287	4de26ff9-8648-4ee3-848c-6ecc8c66242e	queued	\N	Scan created	\N	2026-02-26 08:49:35.932
1302	56aba83a-ce29-4876-8b2c-beed00a8dfec	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:51:36.583
1303	56aba83a-ce29-4876-8b2c-beed00a8dfec	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:51:36.897
1304	56aba83a-ce29-4876-8b2c-beed00a8dfec	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:51:37.208
1306	6e4b07a2-d04d-4bc0-b64e-fa23a44d562d	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:52:35.978
1307	6e4b07a2-d04d-4bc0-b64e-fa23a44d562d	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:52:36.298
1308	6e4b07a2-d04d-4bc0-b64e-fa23a44d562d	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:52:36.619
1309	6e4b07a2-d04d-4bc0-b64e-fa23a44d562d	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:52:36.942
1310	6e4b07a2-d04d-4bc0-b64e-fa23a44d562d	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:52:37.258
1341	f93b88a0-4045-4751-b3fd-c00baa7f1db3	queued	\N	Scan created	\N	2026-02-26 08:58:46.73
1351	5defbace-8c26-451c-928d-7f4b952e1f85	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:59:47.711
1352	5defbace-8c26-451c-928d-7f4b952e1f85	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 08:59:48.02
1354	4b54b001-5ce2-4a79-94a4-007cce4e61f8	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:00:46.761
1355	4b54b001-5ce2-4a79-94a4-007cce4e61f8	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:00:47.07
1356	4b54b001-5ce2-4a79-94a4-007cce4e61f8	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:00:47.384
1357	4b54b001-5ce2-4a79-94a4-007cce4e61f8	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:00:47.696
1358	4b54b001-5ce2-4a79-94a4-007cce4e61f8	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:00:48.004
1360	457e924a-a47b-4a93-9b9a-ba47972f6dad	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:01:46.79
1361	457e924a-a47b-4a93-9b9a-ba47972f6dad	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:01:47.112
1362	457e924a-a47b-4a93-9b9a-ba47972f6dad	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:01:47.436
1363	457e924a-a47b-4a93-9b9a-ba47972f6dad	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:01:47.751
1364	457e924a-a47b-4a93-9b9a-ba47972f6dad	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:01:48.068
1359	457e924a-a47b-4a93-9b9a-ba47972f6dad	queued	\N	Scan created	\N	2026-02-26 09:01:46.78
1365	5a69fc08-936e-4969-a468-920f7885ed5b	queued	\N	Scan created	\N	2026-02-26 09:02:46.816
1366	5a69fc08-936e-4969-a468-920f7885ed5b	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:02:46.85
1367	5a69fc08-936e-4969-a468-920f7885ed5b	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:02:47.168
1368	5a69fc08-936e-4969-a468-920f7885ed5b	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:02:47.477
1369	5a69fc08-936e-4969-a468-920f7885ed5b	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:02:47.788
1370	5a69fc08-936e-4969-a468-920f7885ed5b	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:02:48.103
1371	a8740d52-2ddb-4104-a234-80d52e66a071	queued	\N	Scan created	\N	2026-02-26 09:03:46.853
1372	a8740d52-2ddb-4104-a234-80d52e66a071	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:03:46.859
1373	a8740d52-2ddb-4104-a234-80d52e66a071	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:03:47.178
1374	a8740d52-2ddb-4104-a234-80d52e66a071	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:03:47.495
1375	a8740d52-2ddb-4104-a234-80d52e66a071	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:03:47.81
1376	a8740d52-2ddb-4104-a234-80d52e66a071	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:03:48.123
1377	ad27d234-0522-4303-8636-e935717e816d	queued	\N	Scan created	\N	2026-02-26 09:04:46.917
1378	ad27d234-0522-4303-8636-e935717e816d	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:04:46.924
1379	ad27d234-0522-4303-8636-e935717e816d	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:04:47.236
1380	ad27d234-0522-4303-8636-e935717e816d	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:04:47.55
1381	ad27d234-0522-4303-8636-e935717e816d	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:04:47.871
1382	ad27d234-0522-4303-8636-e935717e816d	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:04:48.186
1383	2a338175-bb64-4cd2-ba6f-8aad8711554e	queued	\N	Scan created	\N	2026-02-26 09:05:04.018
1384	2a338175-bb64-4cd2-ba6f-8aad8711554e	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "10.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:05:04.026
1385	2a338175-bb64-4cd2-ba6f-8aad8711554e	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "10.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:05:04.341
1386	2a338175-bb64-4cd2-ba6f-8aad8711554e	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "10.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:05:04.649
1387	2a338175-bb64-4cd2-ba6f-8aad8711554e	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "10.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:05:04.963
1388	2a338175-bb64-4cd2-ba6f-8aad8711554e	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "10.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:05:05.279
1389	ce51ca7b-445e-4ea3-b927-93a1385a5abe	queued	\N	Scan created	\N	2026-02-26 09:05:46.926
1390	ce51ca7b-445e-4ea3-b927-93a1385a5abe	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:05:46.936
1391	ce51ca7b-445e-4ea3-b927-93a1385a5abe	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:05:47.251
1392	ce51ca7b-445e-4ea3-b927-93a1385a5abe	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:05:47.562
1395	a0b4f8e1-2254-4e9e-84f1-2be119d677a7	queued	\N	Scan created	\N	2026-02-26 09:06:44.737
1393	ce51ca7b-445e-4ea3-b927-93a1385a5abe	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:05:47.883
1394	ce51ca7b-445e-4ea3-b927-93a1385a5abe	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:05:48.204
1396	a0b4f8e1-2254-4e9e-84f1-2be119d677a7	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "cidr", "value": "192.168.1.0/24"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:06:44.744
1397	a0b4f8e1-2254-4e9e-84f1-2be119d677a7	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "cidr", "value": "192.168.1.0/24"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:06:45.055
1398	a0b4f8e1-2254-4e9e-84f1-2be119d677a7	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "cidr", "value": "192.168.1.0/24"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:06:45.37
1399	a0b4f8e1-2254-4e9e-84f1-2be119d677a7	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "cidr", "value": "192.168.1.0/24"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:06:45.676
1400	a0b4f8e1-2254-4e9e-84f1-2be119d677a7	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "cidr", "value": "192.168.1.0/24"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:06:45.989
1402	6c534ace-594e-4fcf-9317-e8e28db63bb2	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:06:46.933
1403	6c534ace-594e-4fcf-9317-e8e28db63bb2	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:06:47.249
1404	6c534ace-594e-4fcf-9317-e8e28db63bb2	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:06:47.566
1405	6c534ace-594e-4fcf-9317-e8e28db63bb2	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:06:47.888
1406	6c534ace-594e-4fcf-9317-e8e28db63bb2	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:06:48.206
1401	6c534ace-594e-4fcf-9317-e8e28db63bb2	queued	\N	Scan created	\N	2026-02-26 09:06:46.923
1407	893597b0-5733-431c-8f2a-90bb37e1c59d	queued	\N	Scan created	\N	2026-02-26 09:07:46.931
1408	893597b0-5733-431c-8f2a-90bb37e1c59d	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:07:46.964
1409	893597b0-5733-431c-8f2a-90bb37e1c59d	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:07:47.278
1410	893597b0-5733-431c-8f2a-90bb37e1c59d	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:07:47.593
1411	893597b0-5733-431c-8f2a-90bb37e1c59d	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:07:47.898
1412	893597b0-5733-431c-8f2a-90bb37e1c59d	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:07:48.215
1413	8fc64757-b47f-4e86-9e78-e7d7b6203898	queued	\N	Scan created	\N	2026-02-26 09:08:46.943
1414	8fc64757-b47f-4e86-9e78-e7d7b6203898	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:08:46.956
1415	8fc64757-b47f-4e86-9e78-e7d7b6203898	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:08:47.276
1416	8fc64757-b47f-4e86-9e78-e7d7b6203898	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:08:47.593
1417	8fc64757-b47f-4e86-9e78-e7d7b6203898	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:08:47.906
1418	8fc64757-b47f-4e86-9e78-e7d7b6203898	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:08:48.219
1419	e4e1c2cc-9826-4d68-9032-7a5952ee2b43	queued	\N	Scan created	\N	2026-02-26 09:09:46.962
1420	e4e1c2cc-9826-4d68-9032-7a5952ee2b43	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:09:46.97
1421	e4e1c2cc-9826-4d68-9032-7a5952ee2b43	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:09:47.298
1422	e4e1c2cc-9826-4d68-9032-7a5952ee2b43	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:09:47.619
1423	e4e1c2cc-9826-4d68-9032-7a5952ee2b43	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:09:47.934
1424	e4e1c2cc-9826-4d68-9032-7a5952ee2b43	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:09:48.244
1425	03f1b859-a5cc-4b2d-bcda-9f0f5b19a666	queued	\N	Scan created	\N	2026-02-26 09:10:46.977
1426	03f1b859-a5cc-4b2d-bcda-9f0f5b19a666	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:10:46.986
1427	03f1b859-a5cc-4b2d-bcda-9f0f5b19a666	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:10:47.299
1428	03f1b859-a5cc-4b2d-bcda-9f0f5b19a666	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:10:47.61
1429	03f1b859-a5cc-4b2d-bcda-9f0f5b19a666	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:10:47.923
1430	03f1b859-a5cc-4b2d-bcda-9f0f5b19a666	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:10:48.238
1431	e3fc1d80-b45a-4ac1-ad48-d89d871ad7d7	queued	\N	Scan created	\N	2026-02-26 09:11:47.013
1432	e3fc1d80-b45a-4ac1-ad48-d89d871ad7d7	running	naabu	Stage naabu running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:11:47.021
1433	e3fc1d80-b45a-4ac1-ad48-d89d871ad7d7	running	nmap	Stage nmap running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:11:47.341
1434	e3fc1d80-b45a-4ac1-ad48-d89d871ad7d7	running	httpx	Stage httpx running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:11:47.661
1435	e3fc1d80-b45a-4ac1-ad48-d89d871ad7d7	running	nuclei	Stage nuclei running	{"status": "running", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:11:47.983
1436	e3fc1d80-b45a-4ac1-ad48-d89d871ad7d7	completed	nuclei	Pipeline completed	{"status": "completed", "request": {"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}}	2026-02-26 09:11:48.302
\.


--
-- Data for Name: scan_schedules; Type: TABLE DATA; Schema: public; Owner: armadillo
--

COPY public.scan_schedules (id, name, enabled, "cronExpr", timezone, "projectId", "requestedBy", targets, config, "nextRunAt", "lastRunAt", "createdAt", "updatedAt", "lastRunScanId", "lastRunStatus", "lastRunMessage") FROM stdin;
ffc068dc-7557-4119-89fa-b165743db89e	Nightly safe scan	f	0 2 * * *	Australia/Melbourne	proj-001	jason	[{"type": "ip", "value": "127.0.0.1"}]	{"profile": "safe-default"}	\N	\N	2026-02-26 05:35:09.302	2026-02-26 05:35:16.889	\N	\N	\N
04d60ac7-6f68-4c7c-b36e-0f2abc88498b	Every minute test	t	*/1 * * * *	Australia/Melbourne	proj-001	jason	[{"type": "ip", "value": "127.0.0.1"}]	{"profile": "safe-default"}	2026-02-26 09:12:00	2026-02-26 09:11:47.004	2026-02-26 05:41:20.17	2026-02-26 09:11:47.019	e3fc1d80-b45a-4ac1-ad48-d89d871ad7d7	queued	Scheduled run queued
\.


--
-- Data for Name: scans; Type: TABLE DATA; Schema: public; Owner: armadillo
--

COPY public.scans (id, "projectId", "requestedBy", status, request, "createdAt", "updatedAt", annotations) FROM stdin;
50250b3a-ac3e-4f6a-8d69-b423618f417b	proj-001	local-smoke	queued	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}	2026-02-25 08:12:10.412	2026-02-25 08:12:10.412	\N
342829f8-219a-4982-8f92-d689f0e8df99	proj-001	local-smoke	queued	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}	2026-02-25 08:34:14.369	2026-02-25 08:34:14.369	\N
16e14b58-2b65-41ad-8f82-1b64a623bb40	proj-001	step2-test	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "step2-test"}	2026-02-25 08:34:43.832	2026-02-25 08:34:45.105	\N
9f466d7a-217b-43ad-b416-ed78d4968ccb	proj-001	local-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}	2026-02-25 08:46:11.22	2026-02-25 08:46:12.485	\N
ceade3fb-d9ee-4635-b341-f60aaf0ad92a	proj-001	step2-test	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "step2-test"}	2026-02-25 08:34:49.869	2026-02-25 08:34:51.139	\N
e9eef081-839e-42ee-9aeb-c33970fe5ad5	proj-001	local-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}	2026-02-25 09:01:03.428	2026-02-25 09:01:04.716	\N
012f6b5b-8cbf-4788-b6b1-137705c2626f	proj-001	local-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}	2026-02-25 08:38:07.731	2026-02-25 08:38:09.027	\N
d43bf8cd-8fe4-458f-b6f1-a6fc147dc264	proj-001	local-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}	2026-02-25 08:49:51.937	2026-02-25 08:49:53.228	\N
cd8f0949-0cef-4b0b-b5f3-e8bf86b8dbfc	proj-001	local-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}	2026-02-25 08:41:35.809	2026-02-25 08:41:37.092	\N
7b4dbd9c-0daa-40eb-a71f-0f5b8c206d12	proj-001	local-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}	2026-02-25 09:45:06.209	2026-02-25 09:45:07.49	\N
ccfefed5-c39f-4770-a644-32b8151a2824	proj-001	local-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}	2026-02-25 09:22:59.581	2026-02-25 09:23:00.854	\N
3320bbef-75c3-4e12-9e74-24a0502ad7c6	proj-001	local-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}	2026-02-25 08:57:01.683	2026-02-25 08:57:02.939	\N
4d0119c6-7a12-449d-9c16-2eda09257747	proj-001	local-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}	2026-02-25 09:19:56.522	2026-02-25 09:19:57.793	\N
d5ea14c1-cb10-4270-973a-1b91657c268b	proj-001	local-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}	2026-02-25 09:33:31.779	2026-02-25 09:33:33.064	\N
32a04a16-8b68-4300-ab3f-f1f70a495634	proj-001	local-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}	2026-02-25 09:20:25.065	2026-02-25 09:20:26.357	\N
2369d66e-c271-40c9-9d1d-5a05ce2ad5c6	proj-001	local-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}	2026-02-25 09:23:18.891	2026-02-25 09:23:20.165	\N
2ec68b31-1b3e-4f54-840a-229994dfb5c4	proj-001	local-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}	2026-02-25 09:41:56.217	2026-02-25 09:41:57.479	\N
9e2a546f-44b7-45a6-9b9d-34f7c283ca54	proj-001	local-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}	2026-02-25 09:37:21.106	2026-02-25 09:37:22.41	\N
5584e06a-706e-46e6-9bc0-eab88435983f	proj-001	local-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}	2026-02-25 09:48:26.236	2026-02-25 09:48:27.494	\N
be0ce310-f29c-4045-9439-380d15a7abe5	proj-001	local-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}	2026-02-25 09:51:26.384	2026-02-25 09:51:27.659	\N
487e2695-9e8d-40c2-bab2-c2b0b53f8b50	proj-001	local-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}	2026-02-25 10:04:12.834	2026-02-25 10:04:14.116	\N
3eeb3511-4f4e-4d0a-9cda-c9199b06ea8b	proj-001	local-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}	2026-02-25 09:58:38.682	2026-02-25 09:58:39.958	\N
7cb48596-9a6a-4413-b122-10b70a08f973	proj-001	local-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}	2026-02-25 10:13:51.826	2026-02-25 10:13:53.094	\N
3fe2e624-a5b8-435a-a83e-0c461c1ae00a	proj-001	local-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "local-smoke"}	2026-02-25 10:09:41.004	2026-02-25 10:09:42.298	\N
0c755b2f-6640-49e6-b882-8049c0ad5d31	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 04:16:44.856	2026-02-26 04:16:46.157	\N
4f4c2224-5ff5-43ef-8197-7db1e8891a0c	proj-001	phase4-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}	2026-02-26 04:54:13.265	2026-02-26 04:54:14.555	\N
ed207888-58de-4ee5-b934-15f9173a4e95	proj-001	phase4-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}	2026-02-26 04:56:16.107	2026-02-26 04:56:17.389	\N
f6b6a24a-722e-4564-8d02-302ce3a5b200	proj-001	phase4-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}	2026-02-26 04:58:55.015	2026-02-26 04:58:56.282	\N
75abfc2d-9494-432a-a19b-dcbd16b88b19	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 05:52:36.247	2026-02-26 05:52:37.532	\N
f61271d3-2abb-4ba0-b048-1296d5229d75	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:04:11.009	2026-02-26 06:04:12.286	\N
cc6cabac-2d2a-4671-9bb5-2580207912a4	proj-001	phase4-smoke	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "phase4-smoke"}	2026-02-26 05:21:23.525	2026-02-26 05:21:24.805	\N
edfab898-4dfd-4303-bda8-056e5d2d469c	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 05:53:36.248	2026-02-26 05:53:37.509	\N
e69443c5-3f75-4136-9e48-7e592d0cdbd1	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:05:11.019	2026-02-26 06:05:12.279	\N
d7c5776b-e69a-4aa7-bbb4-777e43165072	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 05:42:20.13	2026-02-26 05:42:21.42	\N
41783f5a-b949-46f1-b55c-20081930b0b5	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 05:54:08.338	2026-02-26 05:54:09.624	\N
1158da46-ccfd-4225-82b4-8fbb798177e4	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 05:43:20.145	2026-02-26 05:43:21.403	\N
792aaee1-e14c-4c94-92e2-d4bacf69face	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:06:40.437	2026-02-26 06:06:41.746	\N
523049ca-6d7f-4616-9159-496e54d9cdf3	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 05:55:08.321	2026-02-26 05:55:09.607	\N
7b17a4f4-93a1-4ccb-a4b3-3f56b46db97b	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 05:44:20.145	2026-02-26 05:44:21.549	\N
d1cb990d-3b0f-47e8-9a0f-6ca45d329af7	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 05:45:40.455	2026-02-26 05:45:41.759	\N
2d90297a-fa5f-4cad-b075-d81cacac61e8	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 05:56:08.341	2026-02-26 05:56:09.593	\N
7d64dcdf-9e1f-4c07-83b3-2da3bc5ff5aa	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 05:46:40.456	2026-02-26 05:46:53.303	\N
9c9d19fa-2dc4-4ece-ad26-d94506be4b5e	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 05:57:40.58	2026-02-26 05:57:41.884	\N
b5462738-0085-4d4e-b1df-20a44d262436	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 05:47:54.433	2026-02-26 05:47:55.713	\N
c11cdf0a-70cc-4fad-9b80-552ac9b367ad	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 05:58:40.576	2026-02-26 05:58:41.844	\N
be868bbe-b8d8-4fb9-a94c-3732e8c13a32	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 05:48:54.442	2026-02-26 05:48:55.705	\N
5b481e5a-b2f4-4c77-8f77-b512f9f37b02	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 05:59:40.598	2026-02-26 05:59:41.861	\N
b578e05b-6f01-4e7a-b2c6-b48aa03f4008	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 05:49:54.443	2026-02-26 05:49:55.672	\N
c990a44a-eaa3-440b-8905-295f50874631	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:00:10.961	2026-02-26 06:00:12.238	\N
5096b3e1-679e-43ee-bcdf-fca912c9ce62	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 05:50:36.287	2026-02-26 05:50:37.562	\N
824cf3aa-ceb0-4f8e-b447-443ea9640cdc	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 05:51:36.242	2026-02-26 05:51:37.518	\N
5113ae95-cdd0-47eb-a1b9-f749c41b21d4	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:01:10.952	2026-02-26 06:01:12.223	\N
cd2c208f-6842-4e16-80f2-d9a0d2a983dd	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:02:10.966	2026-02-26 06:02:12.256	\N
03108f6d-6851-40bc-a78d-bb3edafec2f5	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:03:10.977	2026-02-26 06:03:12.251	\N
5594a3a4-390c-4bdd-b56c-79bfabeb9e18	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:07:40.439	2026-02-26 06:07:41.721	\N
c510a88d-14b9-48bd-a31c-b673ecbf11b9	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:17:05.914	2026-02-26 06:17:07.4	\N
6089410c-0363-4db9-989b-edd47b2d5553	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:30:25.481	2026-02-26 06:30:26.743	\N
7eccf2d1-8498-45e6-ac2b-b14b2542a1c2	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:08:40.472	2026-02-26 06:08:41.743	\N
26ecf181-db0c-4002-ae22-d35dab4a5a01	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:18:25.154	2026-02-26 06:18:26.462	\N
60b5fc07-5247-4d19-a24f-93289f763a8e	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:31:25.512	2026-02-26 06:31:26.815	\N
15a33a64-a021-4479-b4e8-81aed1f35db2	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:09:40.504	2026-02-26 06:09:41.923	\N
782f5801-4504-4647-b298-9b5bc5a8d77d	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:19:25.163	2026-02-26 06:19:26.436	\N
7f7f9b6b-6140-409f-b8f2-9877ff6b32ee	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:10:05.72	2026-02-26 06:10:06.994	\N
92aad6a8-1750-4f5b-b177-b4e46adbc641	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:32:25.55	2026-02-26 06:32:26.827	\N
ba52b287-0268-4ebf-8de4-c8d918b48909	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:20:25.203	2026-02-26 06:20:26.495	\N
2a60cf97-590f-498f-b404-2825fa751420	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:11:05.715	2026-02-26 06:11:06.982	\N
27c59590-0d9f-416b-ba19-79caf5a9628a	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:33:25.565	2026-02-26 06:33:26.834	\N
e22fe14d-ecdd-4468-9959-684e1a55401f	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:21:25.242	2026-02-26 06:21:26.515	\N
46cd7890-413c-461f-a8f1-56460bae71ca	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:12:05.734	2026-02-26 06:12:07.013	\N
ffeacdea-d748-46a1-8b5e-a1e4a8528b54	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:22:25.288	2026-02-26 06:22:26.56	\N
fbc0cb2a-104e-4957-9932-3737390e887b	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:13:05.764	2026-02-26 06:13:07.051	\N
0da31771-b5fe-43f7-a9cc-08144f72ceb7	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:23:25.265	2026-02-26 06:23:26.546	\N
ee78c50e-1813-4813-bc06-eaf85376ffc1	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:14:05.797	2026-02-26 06:14:07.063	\N
e81eb2b8-2e9d-45d1-93d4-3951878f6698	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:24:25.302	2026-02-26 06:24:26.575	\N
47eb3075-0580-4519-b6fc-07ef0aca8d31	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:15:05.839	2026-02-26 06:15:07.132	\N
6926ca56-92c4-4f14-bfe4-d51619163454	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:25:25.336	2026-02-26 06:25:26.61	\N
69c0a4a0-1555-4cb2-ab36-c8e1eac60e79	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:16:05.878	2026-02-26 06:16:07.145	\N
27af0e89-c078-4e25-b57a-c09698ac62c4	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:26:25.373	2026-02-26 06:26:26.677	\N
344bec1f-575e-4851-9a0e-175a25fd8c44	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:27:25.433	2026-02-26 06:27:26.716	\N
213d9813-b2f6-46c2-89b9-4edfb6a408b7	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:28:25.443	2026-02-26 06:28:26.724	\N
569f34fa-1ebb-42fe-b439-b773daeeefb9	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:29:25.463	2026-02-26 06:29:26.743	\N
a337e16b-fc94-40fc-aceb-b20cce5e11d2	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:34:25.601	2026-02-26 06:34:26.857	\N
d2f6721f-7bba-45c3-86bc-c59e2e63f47c	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:44:25.864	2026-02-26 06:44:27.117	\N
5afa29f2-df94-447c-b158-c97ff705c8f6	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:58:16.581	2026-02-26 06:58:17.856	\N
14b9d7b5-4af6-45aa-8ef3-2ac607720157	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:35:25.603	2026-02-26 06:35:26.872	\N
d9927960-da4f-425f-acb5-3e0fa36c6a6a	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:45:25.905	2026-02-26 06:45:27.165	\N
4e0958c9-6e3f-4aea-879c-f47b70d7ff16	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:36:25.642	2026-02-26 06:36:26.94	\N
e9e98212-a1b1-4cc6-acb4-62492d0c35cc	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:59:16.591	2026-02-26 06:59:17.872	\N
eb50f271-ee98-4faf-87e1-64ee5998eee6	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:37:25.682	2026-02-26 06:37:26.944	\N
8bad6011-2c75-4068-996e-143f4e6950cd	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:46:25.9	2026-02-26 06:46:27.309	\N
585dc344-9f3b-4a4a-bd30-585340802eda	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:00:16.628	2026-02-26 07:00:17.89	\N
8a2630b0-e42c-4de1-b0bd-70c172d503db	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:38:25.714	2026-02-26 06:38:26.969	\N
6b3b8b07-a66c-43e0-87a0-403b9b36205e	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:47:16.298	2026-02-26 06:47:17.573	\N
c4893b86-7ee2-443c-b52b-d89da735ca1b	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:39:25.776	2026-02-26 06:39:27.049	\N
b117affb-d5e7-4a74-b7e1-9d47875ba2d5	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:48:16.292	2026-02-26 06:48:17.57	\N
0bd961e1-8fa9-4f0f-864c-35be77f56f5e	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:40:25.769	2026-02-26 06:40:27.02	\N
63c72e57-208e-4d0a-be02-3caf366d1dbc	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:49:16.32	2026-02-26 06:49:17.586	\N
22702cfd-b179-4eed-9c95-8e87ed502713	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:41:25.797	2026-02-26 06:41:27.089	\N
dd76eca9-dd42-4ebc-b1f0-817f41916ba3	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:50:16.352	2026-02-26 06:50:17.618	\N
219fa6e9-d6d2-4bd3-8ca7-199dcba656db	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:42:25.83	2026-02-26 06:42:27.118	\N
c0e704bd-1bb2-4226-847a-6c117fd8ad40	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:51:16.375	2026-02-26 06:51:17.644	\N
c8c8380b-9ffe-4be3-880e-c33351df4ef7	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:43:25.846	2026-02-26 06:43:27.111	\N
0b53ac89-0567-4255-9ad8-679cab7e7915	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:52:16.43	2026-02-26 06:52:17.72	\N
eb7d01e5-149b-41c4-b1eb-fa30c8d209d8	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:53:16.437	2026-02-26 06:53:17.704	\N
478f9b32-c71a-4668-bad8-0993dda6817e	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:54:16.439	2026-02-26 06:54:17.707	\N
91ac8707-cb10-46dc-b28a-53a17dc6da33	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:55:16.472	2026-02-26 06:55:17.753	\N
5db954c0-a56a-406f-a7c1-e3b032393f3e	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:56:16.506	2026-02-26 06:56:17.789	\N
0fe9f2e9-4519-45fe-aa0b-b82db5e25d44	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 06:57:16.567	2026-02-26 06:57:17.862	\N
52006cb2-f9dd-42d7-8d13-222e48f2ed30	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:13:27.892	2026-02-26 07:13:29.179	\N
9331ba97-f234-4b5f-91cb-2c3c5b8229d2	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:01:16.641	2026-02-26 07:01:17.912	\N
882c6967-600f-4734-8208-3bea05902eb5	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:14:27.906	2026-02-26 07:14:29.175	\N
e0631f14-88df-49c2-958b-7739d4e267a1	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:02:16.676	2026-02-26 07:02:17.969	\N
332d7e51-e061-40d1-9f3f-45caf9a18af5	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:15:27.937	2026-02-26 07:15:29.206	\N
e8d7865f-996d-4ed7-8940-5dbfa434ce58	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:03:16.68	2026-02-26 07:03:26.72	\N
5c0754cb-410e-49ba-aab9-93fd32c76912	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:16:27.96	2026-02-26 07:16:29.234	\N
86a53ac0-6f2d-456d-984e-9cf86f7619ce	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:04:27.645	2026-02-26 07:04:28.926	\N
0f4db452-7137-4704-8769-39154c695def	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:17:27.975	2026-02-26 07:17:29.252	\N
e0b87adb-9ece-4fcb-9367-6e642e55ff06	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:05:27.65	2026-02-26 07:05:28.918	\N
96727ca3-55b5-46a9-85e6-f88f60eb5a71	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:18:27.977	2026-02-26 07:18:29.292	\N
1d12d6cf-56b5-4726-8e7b-6021dcddbb0e	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:06:27.688	2026-02-26 07:06:28.959	\N
9696c966-b820-4b94-8a90-90fa249246eb	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:19:28.015	2026-02-26 07:19:29.294	\N
09b5720e-f6db-4a8c-adba-2e56a721f2f3	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:07:27.721	2026-02-26 07:07:28.995	\N
8d302e06-9bf3-4211-add3-61d655c923de	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:20:28.058	2026-02-26 07:20:29.323	\N
111af853-c24b-4cd5-903d-c1bd76933ad6	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:08:27.758	2026-02-26 07:08:29.045	\N
0004f30a-a563-4fa5-8e51-64d98a830759	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:21:28.076	2026-02-26 07:21:29.348	\N
49cdee0a-8b20-4b74-82e3-3cd19d658717	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:09:27.809	2026-02-26 07:09:29.092	\N
2ef76755-478e-4180-be92-b65ee05f666e	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:22:28.084	2026-02-26 07:22:29.357	\N
07b082b1-a51d-426e-856f-f4fc7ff027e7	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:10:27.816	2026-02-26 07:10:29.076	\N
4088313f-f98b-427f-bab4-987dfe4a62d5	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:23:28.125	2026-02-26 07:23:29.417	\N
fc1173c8-e845-4256-996d-0a2ba591cdf3	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:11:27.854	2026-02-26 07:11:29.116	\N
0a79cef8-5cb8-4ef6-ae40-38714cb0bf16	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:24:28.165	2026-02-26 07:24:29.447	\N
8056dec8-be36-4212-8a92-f4ac5b3d1e9b	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:12:27.877	2026-02-26 07:12:29.159	\N
723e73eb-ee67-420c-acb0-af9ab86ca317	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:25:28.204	2026-02-26 07:25:29.481	\N
29206ccf-07a5-472a-9410-50fa92d112ef	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:26:28.207	2026-02-26 07:26:29.475	\N
bfafa98d-eb1b-4142-a48f-b54a482a8cdf	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:27:28.226	2026-02-26 07:27:29.492	\N
6015e5c1-c8ad-4f8c-991b-3880ab4d7d12	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:29:28.277	2026-02-26 07:29:29.551	\N
a0e13f46-57fd-4637-b0b4-5c7df8684f0b	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:45:48.061	2026-02-26 07:45:49.339	\N
1f99561a-328a-472d-bceb-faf39ae4ff12	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:28:28.261	2026-02-26 07:28:29.553	\N
ed443c1f-c1fb-4a16-905f-f499282d9841	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:30:28.277	2026-02-26 07:30:29.549	\N
3238e99e-b237-4c6e-bf19-ab3e480f7d0b	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:46:48.096	2026-02-26 07:46:49.378	\N
30179c23-a96e-450c-b1e0-bb11f4ca8a81	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:31:28.293	2026-02-26 07:31:29.57	\N
97709e36-d264-494e-a38e-d3e9ddbe8cdf	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:47:48.124	2026-02-26 07:47:49.536	\N
621eb9e9-de32-4e9a-88b8-02864cc1b8a0	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:32:28.323	2026-02-26 07:32:29.58	\N
b32ab2f5-f2e1-4db2-8cb3-89cab9a647b1	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:33:28.355	2026-02-26 07:33:29.647	\N
b804e4fd-8df9-4d27-8a1e-03914897a44b	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:48:37.988	2026-02-26 07:48:39.245	\N
989ff458-bf02-4945-a708-1213873d4362	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:34:28.367	2026-02-26 07:34:41.47	\N
c00343f5-8994-4b86-bb85-4ccb2226ac10	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:49:37.988	2026-02-26 07:49:39.275	\N
9795df7a-6b39-4113-9da6-0d87a55f6f42	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:35:42.497	2026-02-26 07:35:43.788	\N
f31a2b85-1021-420d-a9ac-cc7741d58891	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:36:42.526	2026-02-26 07:36:43.793	\N
b8d0e891-2ce5-4492-bc1f-c1a286d1e12a	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:50:38.01	2026-02-26 07:50:39.297	\N
c9ee8b0b-3872-4396-9a6c-b3811ea587d8	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:37:42.539	2026-02-26 07:37:43.823	\N
df3704a5-530a-45e9-8626-d2c3329429e5	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:51:38.018	2026-02-26 07:51:39.283	\N
61a224a7-5a1b-4325-81b6-894d2990ead3	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:38:42.542	2026-02-26 07:38:43.831	\N
a2c49ab9-c016-4d69-b4e4-82f0565f7108	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:39:42.552	2026-02-26 07:39:43.839	\N
6f9e668e-8e83-4616-9cb6-2ad78ae00365	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:52:38.042	2026-02-26 07:52:39.323	\N
ef843102-f2c2-4c49-a93c-00690a35a8e8	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:40:42.584	2026-02-26 07:40:43.86	\N
9b127e51-6e0e-4c0f-b525-c3bf4b2f0878	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:53:38.064	2026-02-26 07:53:39.341	\N
2da8188a-f236-4244-8dbe-ad363cf6c0b7	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:41:42.607	2026-02-26 07:41:47.04	\N
988a4dd4-e4c2-4c1c-83c2-2d5e895df886	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:54:38.108	2026-02-26 07:54:39.386	\N
a1eed477-f661-49f3-9cce-f0821ed933d2	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:42:47.978	2026-02-26 07:42:49.262	\N
4c9b2360-5fcd-4170-b363-9961bf8c8461	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:43:47.984	2026-02-26 07:43:49.267	\N
1a89e1ae-5617-49fc-a7fe-1b671ef0e168	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:44:48.023	2026-02-26 07:44:49.288	\N
92621df9-19d4-4dc0-b491-7a96ae0dd9a0	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:02:50.541	2026-02-26 08:02:51.825	\N
459a80ad-e3c0-4763-bf7e-eae5b31d71ab	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:20:50.986	2026-02-26 08:20:52.244	\N
71c0152c-ac86-4aa6-a1db-be9169bebfb6	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:39:51.751	2026-02-26 08:39:53.048	\N
903339c5-b5fe-4a1c-8348-c3713b4d2dca	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:55:38.162	2026-02-26 07:55:39.404	\N
a21cc20a-df69-4139-96de-0ec8df69e919	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:03:50.573	2026-02-26 08:03:51.839	\N
19739215-081c-4e1e-92b4-965d6d1bd701	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:21:51.008	2026-02-26 08:21:52.298	\N
7fdf7631-d391-4ac0-b593-b4e1c08aa68a	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:56:32.955	2026-02-26 07:56:34.217	\N
1407259e-d52b-4dc4-ac3a-d3dffa9a4fac	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:04:50.58	2026-02-26 08:04:51.831	\N
b5ee5640-36df-403b-a864-7ec3a9cb2d0f	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:57:32.967	2026-02-26 07:57:34.241	\N
3abe1dbb-08ac-44e5-8c79-696c8b3f8610	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:05:50.615	2026-02-26 08:05:51.892	\N
0bb03412-63cd-4fd6-8f60-0c5a5b146420	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:58:32.999	2026-02-26 07:58:34.263	\N
4de5c34a-6a6c-4836-ac5c-00e464a5c3b8	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:06:50.595	2026-02-26 08:06:51.868	\N
b75f0781-d362-4bdb-956a-8a8d20455efa	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 07:59:33.019	2026-02-26 07:59:34.29	\N
499e70de-a44d-4a1b-ab13-3ec76471a7a7	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:07:50.631	2026-02-26 08:07:51.917	\N
321e903d-0a17-4683-b42f-daa363c60578	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:00:33.026	2026-02-26 08:00:34.566	\N
09059663-edbe-4886-bbd5-65fc09bf0a8e	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:08:50.664	2026-02-26 08:08:51.929	\N
a284244b-0635-461a-bc61-296e0358fed4	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:01:50.517	2026-02-26 08:01:51.815	\N
e39d16da-a8eb-4611-8e2d-8ca9ec9263ef	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:09:50.682	2026-02-26 08:09:51.938	\N
fb393a25-5d0e-4f4a-9fff-bb51cd659ffc	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:10:50.748	2026-02-26 08:10:52.021	\N
f3beeae4-afec-4ca7-9a8e-9e754abbf139	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:11:50.759	2026-02-26 08:11:52.037	\N
483e74b3-8fb5-452f-bf66-cb5d4c53ca8e	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:12:50.787	2026-02-26 08:12:52.06	\N
7156865d-88cf-485d-a68b-74231991f49c	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:13:50.819	2026-02-26 08:13:52.105	\N
c27abe50-11ea-480e-9f5b-e8cb679a7cf8	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:14:50.822	2026-02-26 08:14:52.083	\N
5e94972a-dc21-45a7-b853-7aea8ed2d380	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:15:50.832	2026-02-26 08:15:52.111	\N
1b94627d-3345-432c-886d-a347844da828	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:16:50.858	2026-02-26 08:16:52.14	\N
4e815782-6ebc-4287-b98f-fc91ec796b0e	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:17:50.894	2026-02-26 08:17:52.16	\N
2a2d1429-c99e-474b-80f5-be69f150b434	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:18:50.949	2026-02-26 08:18:52.229	\N
8750ed25-7937-448b-bb40-ad610362b9da	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:19:50.953	2026-02-26 08:19:52.219	\N
f93b88a0-4045-4751-b3fd-c00baa7f1db3	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:58:46.726	2026-02-26 08:58:48.01	\N
0aa1ea9e-29e3-419f-a049-fbaf618efe3a	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:22:51.046	2026-02-26 08:22:52.323	\N
f076e94f-6afe-4c94-868c-3d701e6b4f9d	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:40:51.757	2026-02-26 08:40:53.322	\N
fe07a089-b3de-4212-a7bc-4bdbe396423c	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:23:51.104	2026-02-26 08:23:52.371	\N
cfc59097-d8f8-4a0a-b943-01060da535e5	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:41:12.146	2026-02-26 08:41:13.419	\N
d59029ee-9f0c-41bc-987e-e40f5c26ec70	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:24:51.11	2026-02-26 08:24:52.377	\N
048d4168-0d61-4a70-a5de-ee44aefdb0bd	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:42:12.161	2026-02-26 08:42:13.448	\N
fb0d9a6e-40be-4fc6-bed1-dd7fd9eb8aef	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:25:51.144	2026-02-26 08:25:52.412	\N
feda98a0-6e77-42d7-bd96-8b4100d24cc5	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:43:12.174	2026-02-26 08:43:13.461	\N
df63cbfa-e8f9-4279-a4c5-c3bb9f395490	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:26:51.178	2026-02-26 08:26:52.468	\N
82a2aece-78e9-45d2-bab6-1668eee2d38a	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:44:12.182	2026-02-26 08:44:13.642	\N
ccf1fb3c-3667-4dd9-9e6c-89d9e46c4d62	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:27:50.928	2026-02-26 08:27:52.184	\N
d87b4a38-8a12-4f96-b9c1-f819ed1f332f	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:45:35.835	2026-02-26 08:45:37.144	\N
7643f718-f12e-4865-8755-f8fee64ab281	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:28:50.913	2026-02-26 08:28:52.188	\N
ba7c323d-6619-406e-8ee6-6b65239e9f50	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:46:35.835	2026-02-26 08:46:37.113	\N
5e923fb0-50f8-4068-8d2b-62cd3c79c105	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:29:50.95	2026-02-26 08:29:52.234	\N
b6a1c6a3-4d86-41dd-b2f9-21d546cc5c1a	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:47:35.872	2026-02-26 08:47:37.134	\N
7a1e3eae-c1ec-4942-aa40-3de190aab2d7	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:30:50.978	2026-02-26 08:30:52.245	\N
b98bcf55-f50e-4f0e-bc27-4b81c030e99c	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:48:35.913	2026-02-26 08:48:37.185	\N
4653ea7d-26f4-4879-80b0-e1da75e043d6	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:31:51.01	2026-02-26 08:31:52.273	\N
f9b8e5ed-f90e-443b-829d-ad31f0941e2b	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:32:51.027	2026-02-26 08:32:52.326	\N
4de26ff9-8648-4ee3-848c-6ecc8c66242e	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:49:35.928	2026-02-26 08:49:37.206	\N
9f4f72da-4ae5-4687-9e69-aed4d37155de	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:33:51.066	2026-02-26 08:33:52.326	\N
dca62beb-44fb-4b2a-bfc2-1e737dd4e8fc	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:34:51.661	2026-02-26 08:34:52.94	\N
f0dad537-f37b-428d-a64a-996220f5acea	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:35:51.636	2026-02-26 08:35:52.913	\N
2785459a-29fd-4700-bd16-f6e2056a2be6	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:36:51.66	2026-02-26 08:36:52.927	\N
e119984c-c9ff-40ed-b2ef-4c0c53905a8c	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:37:51.676	2026-02-26 08:37:52.963	\N
4a3983ad-d35d-41ab-897e-1913f66aa389	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:38:51.693	2026-02-26 08:38:52.963	\N
8ccec1ac-910d-4140-a36b-a226b1c4f143	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:50:35.94	2026-02-26 08:50:37.214	\N
5defbace-8c26-451c-928d-7f4b952e1f85	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:59:46.745	2026-02-26 08:59:48.016	\N
56aba83a-ce29-4876-8b2c-beed00a8dfec	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:51:35.943	2026-02-26 08:51:37.206	\N
4b54b001-5ce2-4a79-94a4-007cce4e61f8	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 09:00:46.745	2026-02-26 09:00:48.002	\N
6e4b07a2-d04d-4bc0-b64e-fa23a44d562d	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:52:35.97	2026-02-26 08:52:37.254	\N
457e924a-a47b-4a93-9b9a-ba47972f6dad	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 09:01:46.775	2026-02-26 09:01:48.065	\N
c51d75da-1459-4766-9c1d-d1ae53aa6bca	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:53:35.974	2026-02-26 08:53:37.246	\N
5a69fc08-936e-4969-a468-920f7885ed5b	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 09:02:46.812	2026-02-26 09:02:48.099	\N
7e119a55-9548-49bd-b30d-ea2614badb85	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:54:36.038	2026-02-26 08:54:37.311	\N
a8740d52-2ddb-4104-a234-80d52e66a071	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 09:03:46.851	2026-02-26 09:03:48.12	\N
62d0c697-d3b9-4800-b251-d71f630ba7d9	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:55:36.039	2026-02-26 08:55:37.325	\N
ad27d234-0522-4303-8636-e935717e816d	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 09:04:46.914	2026-02-26 09:04:48.182	\N
01444663-6fc6-4377-89e3-47bc2163ee1b	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:56:36.047	2026-02-26 08:56:37.311	\N
2a338175-bb64-4cd2-ba6f-8aad8711554e	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "10.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 09:05:04.016	2026-02-26 09:05:05.276	\N
6147bb2e-7dd6-42ea-8ed9-9ee2ac7ae994	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 08:57:36.053	2026-02-26 08:57:45.542	\N
ce51ca7b-445e-4ea3-b927-93a1385a5abe	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 09:05:46.922	2026-02-26 09:05:48.2	\N
a0b4f8e1-2254-4e9e-84f1-2be119d677a7	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "cidr", "value": "192.168.1.0/24"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 09:06:44.735	2026-02-26 09:06:45.985	\N
6c534ace-594e-4fcf-9317-e8e28db63bb2	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 09:06:46.921	2026-02-26 09:06:48.203	\N
893597b0-5733-431c-8f2a-90bb37e1c59d	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 09:07:46.927	2026-02-26 09:07:48.212	\N
8fc64757-b47f-4e86-9e78-e7d7b6203898	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 09:08:46.938	2026-02-26 09:08:48.216	\N
e4e1c2cc-9826-4d68-9032-7a5952ee2b43	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 09:09:46.961	2026-02-26 09:09:48.241	\N
03f1b859-a5cc-4b2d-bcda-9f0f5b19a666	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 09:10:46.974	2026-02-26 09:10:48.235	\N
e3fc1d80-b45a-4ac1-ad48-d89d871ad7d7	proj-001	jason	completed	{"config": {"profile": "safe-default"}, "targets": [{"type": "ip", "value": "127.0.0.1"}], "projectId": "proj-001", "requestedBy": "jason"}	2026-02-26 09:11:47.01	2026-02-26 09:11:48.299	\N
\.


--
-- Data for Name: xml_imports; Type: TABLE DATA; Schema: public; Owner: armadillo
--

COPY public.xml_imports (id, source, "requestedBy", "rootNode", "itemCount", payload, "createdAt", "normalizedAssetCount", "skippedAssetCount", "invalidAssetCount", "qualitySummary", "qualityMode", "qualityStatus", "alertTriggered", "rejectArtifact", annotations) FROM stdin;
84388151-ce77-42b3-a585-d5e10bd23317	smoke-test	smoke-test	assets	2	{"assets": {"asset": [{"ip": "10.0.0.1"}, {"ip": "10.0.0.2"}]}}	2026-02-25 08:49:52.102	0	0	0	\N	lenient	pass	f	\N	\N
8a15fe75-ab6a-49c8-9913-a90b6212b283	smoke-test	smoke-test	assets	2	{"assets": {"asset": [{"ip": "10.0.0.1"}, {"ip": "10.0.0.2"}]}}	2026-02-25 08:57:01.822	0	0	0	\N	lenient	pass	f	\N	\N
37f70c73-0fb6-4bd2-ab23-2dc8fe9e8cd6	smoke-test	smoke-test	assets	2	{"assets": {"asset": [{"ip": "10.0.0.1"}, {"ip": "10.0.0.2"}]}}	2026-02-25 09:01:03.523	0	0	0	\N	lenient	pass	f	\N	\N
7062010c-b833-4288-adf9-f5ccceb66548	smoke-test	smoke-test	assets	2	{"assets": {"asset": [{"ip": "10.0.0.1"}, {"ip": "10.0.0.2"}]}}	2026-02-25 09:20:25.151	0	0	0	\N	lenient	pass	f	\N	\N
014f0473-3a10-4a64-92b7-6295c440686b	dedup-check	smoke-test	assets	2	{"assets": {"asset": [{"ip": "10.0.0.1"}, {"ip": "10.0.0.2"}]}}	2026-02-25 09:20:30.834	0	0	0	\N	lenient	pass	f	\N	\N
006a7801-ce85-44f7-9190-1bd62de642af	smoke-test	smoke-test	assets	2	{"assets": {"asset": [{"ip": "10.0.0.1"}, {"ip": "10.0.0.2"}]}}	2026-02-25 09:22:59.68	0	0	0	\N	lenient	pass	f	\N	\N
3134e6e2-2bd9-4620-9d46-cf8a237621a7	smoke-test	smoke-test	assets	2	{"assets": {"asset": [{"ip": "10.0.0.1"}, {"ip": "10.0.0.2"}]}}	2026-02-25 09:23:18.967	0	0	0	\N	lenient	pass	f	\N	\N
b5ffc678-1100-4dd7-b478-acea5b647496	smoke-test	smoke-test	assets	2	{"assets": {"asset": [{"ip": "10.0.0.1"}, {"ip": "10.0.0.2"}]}}	2026-02-25 09:33:31.909	0	0	0	\N	lenient	pass	f	\N	\N
e2e360bc-d667-466f-b3fd-fcf371fbea78	smoke-test	smoke-test	assets	2	{"assets": {"asset": [{"ip": "10.0.0.1"}, {"ip": "10.0.0.2"}]}}	2026-02-25 09:37:21.21	0	0	0	\N	lenient	pass	f	\N	\N
d604cf15-a614-4f45-a721-25cc7b881107	smoke-test	smoke-test	assets	3	{"assets": {"asset": [{"ip": "10.0.0.1", "ports": "443,8443", "serviceTags": "web"}, {"ip": "10.0.0.2", "port": 22, "tags": "ssh"}, {"port": "abc", "hostname": "bad-port-host"}]}}	2026-02-25 09:41:56.314	3	2	1	{"parsedObjects": 5, "reasonBuckets": {"invalid_ports": 1, "missing_identity": 2}, "invalidAssetCount": 1, "skippedAssetCount": 2, "normalizedAssetCount": 3}	lenient	pass	f	\N	\N
cfe2d5fc-8d4a-4eb4-b6d0-27a2a29b7d08	smoke-test	smoke-test	assets	3	{"assets": {"asset": [{"ip": "10.0.0.1", "ports": "443,8443", "serviceTags": "web"}, {"ip": "10.0.0.2", "port": 22, "tags": "ssh"}, {"port": "abc", "hostname": "bad-port-host"}]}}	2026-02-25 09:45:06.392	3	2	1	{"parsedObjects": 5, "reasonBuckets": {"invalid_ports": 1, "missing_identity": 2}, "invalidAssetCount": 1, "skippedAssetCount": 2, "normalizedAssetCount": 3}	lenient	pass	f	\N	\N
0306313a-9418-493c-a71b-aecf56f79597	smoke-test	smoke-test	assets	3	{"assets": {"asset": [{"ip": "10.0.0.1", "ports": "443,8443", "serviceTags": "web"}, {"ip": "10.0.0.2", "port": 22, "tags": "ssh"}, {"port": "abc", "hostname": "bad-port-host"}]}}	2026-02-25 09:48:26.367	3	2	1	{"parsedObjects": 5, "reasonBuckets": {"invalid_ports": 1, "missing_identity": 2}, "invalidAssetCount": 1, "skippedAssetCount": 2, "normalizedAssetCount": 3}	lenient	pass	f	\N	\N
285b867b-0f52-4619-8fe6-caa536dca65c	smoke-test	smoke-test	assets	3	{"assets": {"asset": [{"ip": "10.0.0.1", "ports": "443,8443", "serviceTags": "web"}, {"ip": "10.0.0.2", "port": 22, "tags": "ssh"}, {"port": "abc", "hostname": "bad-port-host"}]}}	2026-02-25 09:51:26.479	3	2	1	{"parsedObjects": 5, "reasonBuckets": {"invalid_ports": 1, "missing_identity": 2}, "invalidAssetCount": 1, "skippedAssetCount": 2, "normalizedAssetCount": 3}	lenient	pass	f	\N	\N
c75426da-11f7-4128-8204-5e597817b18c	smoke-test	smoke-test	assets	3	{"assets": {"asset": [{"ip": "10.0.0.1", "ports": "443,8443", "serviceTags": "web"}, {"ip": "10.0.0.2", "port": 22, "tags": "ssh"}, {"port": "abc", "hostname": "bad-port-host"}]}}	2026-02-25 09:58:38.785	3	2	1	{"parsedObjects": 5, "reasonBuckets": {"invalid_ports": 1, "missing_identity": 2}, "invalidAssetCount": 1, "skippedAssetCount": 2, "normalizedAssetCount": 3}	lenient	fail	t	{"rejected": [{"node": {"assets": {"asset": [{"ip": "10.0.0.1", "ports": "443,8443", "serviceTags": "web"}, {"ip": "10.0.0.2", "port": 22, "tags": "ssh"}, {"port": "abc", "hostname": "bad-port-host"}]}}, "reason": "missing_identity"}, {"node": {"asset": [{"ip": "10.0.0.1", "ports": "443,8443", "serviceTags": "web"}, {"ip": "10.0.0.2", "port": 22, "tags": "ssh"}, {"port": "abc", "hostname": "bad-port-host"}]}, "reason": "missing_identity"}, {"node": {"port": "abc", "hostname": "bad-port-host"}, "reason": "invalid_ports"}], "rejectedCount": 3}	\N
7019690b-9825-438b-bda2-062574920146	smoke-test	smoke-test	assets	3	{"assets": {"asset": [{"ip": "10.0.0.1", "ports": "443,8443", "serviceTags": "web"}, {"ip": "10.0.0.2", "port": 22, "tags": "ssh"}, {"port": "abc", "hostname": "bad-port-host"}]}}	2026-02-25 10:04:12.942	3	2	1	{"parsedObjects": 5, "reasonBuckets": {"invalid_ports": 1, "missing_identity": 2}, "invalidAssetCount": 1, "skippedAssetCount": 2, "normalizedAssetCount": 3}	lenient	fail	t	{"rejected": [{"node": {"assets": {"asset": [{"ip": "10.0.0.1", "ports": "443,8443", "serviceTags": "web"}, {"ip": "10.0.0.2", "port": 22, "tags": "ssh"}, {"port": "abc", "hostname": "bad-port-host"}]}}, "reason": "missing_identity"}, {"node": {"asset": [{"ip": "10.0.0.1", "ports": "443,8443", "serviceTags": "web"}, {"ip": "10.0.0.2", "port": 22, "tags": "ssh"}, {"port": "abc", "hostname": "bad-port-host"}]}, "reason": "missing_identity"}, {"node": {"port": "abc", "hostname": "bad-port-host"}, "reason": "invalid_ports"}], "rejectedCount": 3}	\N
dc270ad9-361a-4dcf-988a-9ade80d0bf2d	smoke-test	smoke-test	assets	3	{"assets": {"asset": [{"ip": "10.0.0.1", "ports": "443,8443", "serviceTags": "web"}, {"ip": "10.0.0.2", "port": 22, "tags": "ssh"}, {"port": "abc", "hostname": "bad-port-host"}]}}	2026-02-25 10:13:51.907	3	2	1	{"parsedObjects": 5, "reasonBuckets": {"invalid_ports": 1, "missing_identity": 2}, "invalidAssetCount": 1, "skippedAssetCount": 2, "normalizedAssetCount": 3}	lenient	fail	t	{"rejected": [{"node": {"assets": {"asset": [{"ip": "10.0.0.1", "ports": "443,8443", "serviceTags": "web"}, {"ip": "10.0.0.2", "port": 22, "tags": "ssh"}, {"port": "abc", "hostname": "bad-port-host"}]}}, "reason": "missing_identity"}, {"node": {"asset": [{"ip": "10.0.0.1", "ports": "443,8443", "serviceTags": "web"}, {"ip": "10.0.0.2", "port": 22, "tags": "ssh"}, {"port": "abc", "hostname": "bad-port-host"}]}, "reason": "missing_identity"}, {"node": {"port": "abc", "hostname": "bad-port-host"}, "reason": "invalid_ports"}], "rejectedCount": 3}	\N
28d7b220-ae7e-47ec-94fa-455034f7e355	smoke-test	smoke-test	assets	3	{"assets": {"asset": [{"ip": "10.0.0.1", "ports": "443,8443", "serviceTags": "web"}, {"ip": "10.0.0.2", "port": 22, "tags": "ssh"}, {"port": "abc", "hostname": "bad-port-host"}]}}	2026-02-25 10:09:41.083	3	2	1	{"parsedObjects": 5, "reasonBuckets": {"invalid_ports": 1, "missing_identity": 2}, "invalidAssetCount": 1, "skippedAssetCount": 2, "normalizedAssetCount": 3}	lenient	fail	t	{"rejected": [{"node": {"assets": {"asset": [{"ip": "10.0.0.1", "ports": "443,8443", "serviceTags": "web"}, {"ip": "10.0.0.2", "port": 22, "tags": "ssh"}, {"port": "abc", "hostname": "bad-port-host"}]}}, "reason": "missing_identity"}, {"node": {"asset": [{"ip": "10.0.0.1", "ports": "443,8443", "serviceTags": "web"}, {"ip": "10.0.0.2", "port": 22, "tags": "ssh"}, {"port": "abc", "hostname": "bad-port-host"}]}, "reason": "missing_identity"}, {"node": {"port": "abc", "hostname": "bad-port-host"}, "reason": "invalid_ports"}], "rejectedCount": 3}	{"notes": "import note", "labels": ["followup"]}
\.


--
-- Name: asset_vulnerabilities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: armadillo
--

SELECT pg_catalog.setval('public.asset_vulnerabilities_id_seq', 9, true);


--
-- Name: scan_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: armadillo
--

SELECT pg_catalog.setval('public.scan_events_id_seq', 1436, true);


--
-- Name: _prisma_migrations _prisma_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: armadillo
--

ALTER TABLE ONLY public._prisma_migrations
    ADD CONSTRAINT _prisma_migrations_pkey PRIMARY KEY (id);


--
-- Name: asset_vulnerabilities asset_vulnerabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: armadillo
--

ALTER TABLE ONLY public.asset_vulnerabilities
    ADD CONSTRAINT asset_vulnerabilities_pkey PRIMARY KEY (id);


--
-- Name: assets assets_pkey; Type: CONSTRAINT; Schema: public; Owner: armadillo
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_pkey PRIMARY KEY (id);


--
-- Name: import_source_policies import_source_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: armadillo
--

ALTER TABLE ONLY public.import_source_policies
    ADD CONSTRAINT import_source_policies_pkey PRIMARY KEY (source);


--
-- Name: scan_events scan_events_pkey; Type: CONSTRAINT; Schema: public; Owner: armadillo
--

ALTER TABLE ONLY public.scan_events
    ADD CONSTRAINT scan_events_pkey PRIMARY KEY (id);


--
-- Name: scan_schedules scan_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: armadillo
--

ALTER TABLE ONLY public.scan_schedules
    ADD CONSTRAINT scan_schedules_pkey PRIMARY KEY (id);


--
-- Name: scans scans_pkey; Type: CONSTRAINT; Schema: public; Owner: armadillo
--

ALTER TABLE ONLY public.scans
    ADD CONSTRAINT scans_pkey PRIMARY KEY (id);


--
-- Name: xml_imports xml_imports_pkey; Type: CONSTRAINT; Schema: public; Owner: armadillo
--

ALTER TABLE ONLY public.xml_imports
    ADD CONSTRAINT xml_imports_pkey PRIMARY KEY (id);


--
-- Name: asset_vulnerabilities_assetId_cve_key; Type: INDEX; Schema: public; Owner: armadillo
--

CREATE UNIQUE INDEX "asset_vulnerabilities_assetId_cve_key" ON public.asset_vulnerabilities USING btree ("assetId", cve);


--
-- Name: asset_vulnerabilities_cve_idx; Type: INDEX; Schema: public; Owner: armadillo
--

CREATE INDEX asset_vulnerabilities_cve_idx ON public.asset_vulnerabilities USING btree (cve);


--
-- Name: asset_vulnerabilities_detectedAt_idx; Type: INDEX; Schema: public; Owner: armadillo
--

CREATE INDEX "asset_vulnerabilities_detectedAt_idx" ON public.asset_vulnerabilities USING btree ("detectedAt");


--
-- Name: asset_vulnerabilities_importId_detectedAt_idx; Type: INDEX; Schema: public; Owner: armadillo
--

CREATE INDEX "asset_vulnerabilities_importId_detectedAt_idx" ON public.asset_vulnerabilities USING btree ("importId", "detectedAt");


--
-- Name: asset_vulnerabilities_importId_severity_idx; Type: INDEX; Schema: public; Owner: armadillo
--

CREATE INDEX "asset_vulnerabilities_importId_severity_idx" ON public.asset_vulnerabilities USING btree ("importId", severity);


--
-- Name: asset_vulnerabilities_severity_detectedAt_idx; Type: INDEX; Schema: public; Owner: armadillo
--

CREATE INDEX "asset_vulnerabilities_severity_detectedAt_idx" ON public.asset_vulnerabilities USING btree (severity, "detectedAt");


--
-- Name: assets_hostname_idx; Type: INDEX; Schema: public; Owner: armadillo
--

CREATE INDEX assets_hostname_idx ON public.assets USING btree (hostname);


--
-- Name: assets_identityKey_key; Type: INDEX; Schema: public; Owner: armadillo
--

CREATE UNIQUE INDEX "assets_identityKey_key" ON public.assets USING btree ("identityKey");


--
-- Name: assets_importId_createdAt_idx; Type: INDEX; Schema: public; Owner: armadillo
--

CREATE INDEX "assets_importId_createdAt_idx" ON public.assets USING btree ("importId", "createdAt");


--
-- Name: assets_ip_idx; Type: INDEX; Schema: public; Owner: armadillo
--

CREATE INDEX assets_ip_idx ON public.assets USING btree (ip);


--
-- Name: scan_events_scanId_createdAt_idx; Type: INDEX; Schema: public; Owner: armadillo
--

CREATE INDEX "scan_events_scanId_createdAt_idx" ON public.scan_events USING btree ("scanId", "createdAt");


--
-- Name: scan_schedules_enabled_nextRunAt_idx; Type: INDEX; Schema: public; Owner: armadillo
--

CREATE INDEX "scan_schedules_enabled_nextRunAt_idx" ON public.scan_schedules USING btree (enabled, "nextRunAt");


--
-- Name: scan_schedules_projectId_createdAt_idx; Type: INDEX; Schema: public; Owner: armadillo
--

CREATE INDEX "scan_schedules_projectId_createdAt_idx" ON public.scan_schedules USING btree ("projectId", "createdAt");


--
-- Name: scans_createdAt_idx; Type: INDEX; Schema: public; Owner: armadillo
--

CREATE INDEX "scans_createdAt_idx" ON public.scans USING btree ("createdAt");


--
-- Name: scans_projectId_idx; Type: INDEX; Schema: public; Owner: armadillo
--

CREATE INDEX "scans_projectId_idx" ON public.scans USING btree ("projectId");


--
-- Name: scans_status_idx; Type: INDEX; Schema: public; Owner: armadillo
--

CREATE INDEX scans_status_idx ON public.scans USING btree (status);


--
-- Name: scans_updatedAt_idx; Type: INDEX; Schema: public; Owner: armadillo
--

CREATE INDEX "scans_updatedAt_idx" ON public.scans USING btree ("updatedAt");


--
-- Name: xml_imports_createdAt_idx; Type: INDEX; Schema: public; Owner: armadillo
--

CREATE INDEX "xml_imports_createdAt_idx" ON public.xml_imports USING btree ("createdAt");


--
-- Name: xml_imports_source_createdAt_idx; Type: INDEX; Schema: public; Owner: armadillo
--

CREATE INDEX "xml_imports_source_createdAt_idx" ON public.xml_imports USING btree (source, "createdAt");


--
-- Name: asset_vulnerabilities asset_vulnerabilities_assetId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: armadillo
--

ALTER TABLE ONLY public.asset_vulnerabilities
    ADD CONSTRAINT "asset_vulnerabilities_assetId_fkey" FOREIGN KEY ("assetId") REFERENCES public.assets(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: asset_vulnerabilities asset_vulnerabilities_importId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: armadillo
--

ALTER TABLE ONLY public.asset_vulnerabilities
    ADD CONSTRAINT "asset_vulnerabilities_importId_fkey" FOREIGN KEY ("importId") REFERENCES public.xml_imports(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: assets assets_importId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: armadillo
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT "assets_importId_fkey" FOREIGN KEY ("importId") REFERENCES public.xml_imports(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: scan_events scan_events_scanId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: armadillo
--

ALTER TABLE ONLY public.scan_events
    ADD CONSTRAINT "scan_events_scanId_fkey" FOREIGN KEY ("scanId") REFERENCES public.scans(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict uxewfyAZLcE7B93bjVHpvZgbfu0ncVazG1PQgdKyyM7VN6W6r1BhPM6dOi3bQ7n

