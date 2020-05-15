--------------------------------------------------------- --
-- View definitioner til brug for downloadtjeneste til MU --
------------------------------------------------------------
-- BygningPaaFremmedGrundFlade
-- Selektering af BygningPaaFremmedGrundFlade som har status Gældende, ikke er afregistreret og hvor virkningen er på tidspunktet angivet ved parameteren @Virkningstid
create or replace view BYGNINGPAAFREMMEDGRUNDFLADE
AS
SELECT 	mua.OBJECTID,
		mua.ID_LOKALID AS "lokalid",
		mua.REGISTRERINGFRA AS "reg_Fra",
		mua.REGISTRERINGTIL AS "reg_Til",
		mua.VIRKNINGFRA AS "virk_Fra",
		mua.VIRKNINGTIL AS "virk_Til",
		mua.VIRKNINGSAKTOER AS "virkAktoer",
		mua.FORRETNINGSHAENDELSE AS "haendelse",
		mua.FORRETNINGSPROCES AS "sagskatego",
		mua.SENESTESAGLOKALID AS "senesteSag",
		mua.GEOMETRI,
		mua.BFENUMMER AS "BFEnr",
		mua.OPDELTIEJERLEJLIGHEDER AS "opdeltIEjl",
		mua.OPRINDELSE AS "oprindelse",
		mua.PAAHAVET AS "paaHavet",
		mua.RIDS AS "rids",
		mua.SAMLETFASTEJENDOMLOKALID AS "SFEnr"
FROM MATRIKEL_L1_PREPROD.BYGNINGPAAFREMMEDGRUNDFLADE mua
WHERE mua.status = 'Gældende' AND mua.REGISTRERINGTIL IS NULL AND mua.VIRKNINGFRA <= @Virkningstid AND (VIRKNINGTIL IS NULL OR @Virkningstid < VIRKNINGTIL);


-- BygningPaaFremmedGrundPunkt
-- Selektering af BygningPaaFremmedGrundPunkt som har status Gældende, ikke er afregistreret og hvor virkningen er på tidspunktet angivet ved parameteren @Virkningstid
create or replace view BYGNINGPAAFREMMEDGRUNDPUNKT
AS
SELECT 	mua.OBJECTID,
		mua.ID_LOKALID AS "lokalid",
		mua.REGISTRERINGFRA AS "reg_Fra",
		mua.REGISTRERINGTIL AS "reg_Til",
		mua.VIRKNINGFRA AS "virk_Fra",
		mua.VIRKNINGTIL AS "virk_Til",
		mua.VIRKNINGSAKTOER AS "virkAktoer",
		mua.FORRETNINGSHAENDELSE AS "haendelse",
		mua.FORRETNINGSPROCES AS "sagskatego",
		mua.SENESTESAGLOKALID AS "senesteSag",
		mua.GEOMETRI,
		mua.BFENUMMER AS "BFEnr",
		mua.OPDELTIEJERLEJLIGHEDER AS "opdeltIEjl",
		mua.OPRINDELSE AS "oprindelse",
		mua.PAAHAVET AS "paaHavet",
		mua.RIDS AS "rids",
		mua.SAMLETFASTEJENDOMLOKALID AS "SFEnr"
FROM MATRIKEL_L1_PREPROD.BYGNINGPAAFREMMEDGRUNDPUNKT mua
WHERE mua.status = 'Gældende' AND mua.REGISTRERINGTIL IS NULL AND mua.VIRKNINGFRA <= @Virkningstid AND (VIRKNINGTIL IS NULL OR @Virkningstid < VIRKNINGTIL);

-- Centroide
-- Selektering af Centroide som har status Gældende, ikke er afregistreret og hvor virkningen er på tidspunktet angivet ved parameteren @Virkningstid
-- Yderligere hentes matrikelnummer og ejerlavskode via et join til jordstykke
create or replace view CENTROIDE
AS
SELECT	mua.OBJECTID,
		mua.ID_LOKALID AS "lokalid",
		mua.REGISTRERINGFRA AS "reg_Fra",
		mua.REGISTRERINGTIL AS "reg_Til",
		mua.VIRKNINGFRA AS "virk_Fra",
		mua.VIRKNINGTIL AS "virk_Til",
		mua.VIRKNINGSAKTOER AS "virkAktoer",
		mua.FORRETNINGSHAENDELSE AS "haendelse",
		mua.FORRETNINGSPROCES AS "sagskatego",
		mua.SENESTESAGLOKALID AS "senesteSag",
		mua.GEOMETRI,
		muj.EJERLAVLOKALID AS "ejlavskode",
		mua.JORDSTYKKELOKALID AS "jordstykId",
		muj.MATRIKELNUMMER AS "matrikelnr"
FROM MATRIKEL_L1_PREPROD.CENTROIDE mua, (SELECT distinct MATRIKELNUMMER , ID_LOKALID, EJERLAVLOKALID FROM MATRIKEL_L1_PREPROD.JORDSTYKKE) muj
WHERE mua.status = 'Gældende' AND mua.REGISTRERINGTIL IS NULL AND mua.VIRKNINGFRA <= @Virkningstid AND (VIRKNINGTIL IS NULL OR @Virkningstid < VIRKNINGTIL) AND muj.ID_LOKALID = mua.JORDSTYKKELOKALID;


-- Ejerlav
-- Selektering af Ejerlav som har status Gældende, ikke er afregistreret og hvor virkningen er på tidspunktet angivet ved parameteren @Virkningstid
create or replace view EJERLAV
AS
SELECT	mua.OBJECTID,
		mua.ID_LOKALID AS "lokalid",
		mua.REGISTRERINGFRA AS "reg_Fra",
		mua.REGISTRERINGTIL AS "reg_Til",
		mua.VIRKNINGFRA AS "virk_Fra",
		mua.VIRKNINGTIL AS "virk_Til",
		mua.VIRKNINGSAKTOER AS "virkAktoer",
		mua.SAGLOKALID AS "senesteSag",
		mua.GEOMETRI,
		mua.EJERLAVSKODE AS "ejlavskode",
		mua.EJERLAVSNAVN AS "ejlavsnavn"
FROM MATRIKEL_L1_PREPROD.EJERLAV mua
WHERE mua.status = 'Gældende' AND mua.REGISTRERINGTIL IS NULL AND mua.VIRKNINGFRA <= @Virkningstid AND (VIRKNINGTIL IS NULL OR @Virkningstid < VIRKNINGTIL);


-- Matrikelkommune
-- Selektering af Matrikelkommune som har status Gældende, ikke er afregistreret og hvor virkningen er på tidspunktet angivet ved parameteren @Virkningstid
create or replace view MATRIKELKOMMUNE
AS
SELECT	mua.OBJECTID,
		mua.ID_LOKALID AS "lokalid",
		mua.REGISTRERINGFRA AS "reg_Fra",
		mua.REGISTRERINGTIL AS "reg_Til",
		mua.VIRKNINGFRA AS "virk_Fra",
		mua.VIRKNINGTIL AS "virk_Til",
		mua.VIRKNINGSAKTOER AS "virkAktoer",
		mua.SAGLOKALID AS "senesteSag",
		mua.GEOMETRI,
		mua.KOMMUNEKODE AS "kommunKode",
		mua.KOMMUNENAVN AS "kommunNavn"
FROM MATRIKEL_L1_PREPROD.MATRIKELKOMMUNE mua
WHERE mua.status = 'Gældende' AND mua.REGISTRERINGTIL IS NULL AND mua.VIRKNINGFRA <= @Virkningstid AND (VIRKNINGTIL IS NULL OR @Virkningstid < VIRKNINGTIL);


-- Matrikelsogn
-- Selektering af Matrikelsogn som har status Gældende, ikke er afregistreret og hvor virkningen er på tidspunktet angivet ved parameteren @Virkningstid
create or replace view MATRIKELSOGN
AS
SELECT	mua.OBJECTID,
		mua.ID_LOKALID AS "lokalid",
		mua.REGISTRERINGFRA AS "reg_Fra",
		mua.REGISTRERINGTIL AS "reg_Til",
		mua.VIRKNINGFRA AS "virk_Fra",
		mua.VIRKNINGTIL AS "virk_Til",
		mua.VIRKNINGSAKTOER AS "virkAktoer",
		mua.SAGLOKALID AS "senesteSag",
		mua.GEOMETRI,
		mua.SOGNEKODE AS "sognekode",
		mua.SOGNENAVN AS "sognenavn"
FROM MATRIKEL_L1_PREPROD.MATRIKELSOGN mua
WHERE mua.status = 'Gældende' AND mua.REGISTRERINGTIL IS NULL AND mua.VIRKNINGFRA <= @Virkningstid AND (VIRKNINGTIL IS NULL OR @Virkningstid < VIRKNINGTIL);


-- Ejerlejlighed
-- Selektering af Ejerlejlighed som har status Gældende, ikke er afregistreret og hvor virkningen er på tidspunktet angivet ved parameteren @Virkningstid
-- Geometrien til ejerlejlighed hentes via en aggregering af geometrierne fra de ejerlejlighedslodder der hører til ejerlejligheden 
create OR replace view EJERLEJLIGHED (MATRIKEL_GIS.EJERLEJLIGHED_G_MV er en materialisering af MATRIKEL_GIS.EJERLEJLIGHED_G)
AS
SELECT mua.OBJECTID,
       mua.ID_LOKALID AS "lokalid",
       mua.REGISTRERINGFRA AS "reg_Fra",
       mua.REGISTRERINGTIL AS "reg_Til",
       mua.VIRKNINGFRA AS "virk_Fra",
       mua.VIRKNINGTIL AS "virk_Til",
       mua.VIRKNINGSAKTOER AS "virkAktoer",
       mua.FORRETNINGSHAENDELSE AS "haendelse",
       mua.FORRETNINGSPROCES AS "sagskatego",
       mua.SENESTESAGLOKALID AS "senesteSag",
       mua.BFENUMMER AS "BFEnr",
       mua.EJERLEJLIGHEDSKORT AS "ejerlKort",
       mua.EJERLEJLIGHEDSNUMMER AS "ejerlejlNr",
       mua.FORDELINGSTALNAEVNER AS "forNaevner",
       mua.FORDELINGSTALTAELLER AS "forTaeller",
       mua.IBYGNINGPAAFREMMEDGRUND AS "i_BPFG",
       mua.SAMLETAREAL AS "saml_areal",
       mua.SAMLETFASTEJENDOMLOKALID AS "SFEnr",
       mua.B_BYGNINGPAAFREMMEDGRUNDFLADEL AS "BFE_BPFG_F",
       mua.B_BYGNINGPAAFREMMEDGRUNDPUNKTL AS "BFE_BPFG_P",
       sdo_aggr_union ( sdoaggrtype (lf.GEOMETRI, 0.005)) GEOMETRI
  FROM MATRIKEL_L1_PREPROD.ejerlejlighed mua,
       matrikel_l1_preprod.ejerlejlighedslod lf
WHERE     lf.registreringtil IS NULL
       AND lf.status = 'Gældende'
       AND mua.registreringtil IS NULL
       AND mua.status = 'Gældende'
       AND LF.ejerlejlighedLOKALID = mua.id_lokalid
       AND @Virkningstid between MUA.VIRKNINGFRA AND nvl(MUA.VIRKNINGTIL,to_date('2099-12-31 23:59:59','yyyy-mm-dd hh24:mi:ss'))
       AND @Virkningstid between LF.VIRKNINGFRA AND nvl(LF.VIRKNINGTIL,to_date('2099-12-31 23:59:59','yyyy-mm-dd hh24:mi:ss'))
GROUP BY mua.OBJECTID,
       mua.ID_LOKALID,
       mua.REGISTRERINGFRA,
       mua.REGISTRERINGTIL,
       mua.VIRKNINGFRA,
       mua.VIRKNINGTIL,
       mua.VIRKNINGSAKTOER,
       mua.FORRETNINGSHAENDELSE,
       mua.FORRETNINGSPROCES,
       mua.SENESTESAGLOKALID,
       mua.BFENUMMER,
       mua.EJERLEJLIGHEDSKORT,
       mua.EJERLEJLIGHEDSNUMMER,
       mua.FORDELINGSTALNAEVNER,
       mua.FORDELINGSTALTAELLER,
       mua.IBYGNINGPAAFREMMEDGRUND,
       mua.SAMLETAREAL,
       mua.SAMLETFASTEJENDOMLOKALID,
       mua.B_BYGNINGPAAFREMMEDGRUNDFLADEL,
       mua.B_BYGNINGPAAFREMMEDGRUNDPUNKTL


 

-- Ejerlejlighedslod
-- Selektering af Ejerlejlighedslod som har status Gældende, ikke er afregistreret og hvor virkningen er på tidspunktet angivet ved parameteren @Virkningstid
create OR replace view EJERLEJLIGHEDSLOD
AS
SELECT 	mua.OBJECTID,
		mua.ID_LOKALID AS "lokalid",
		mua.REGISTRERINGFRA AS "reg_Fra",
		mua.REGISTRERINGTIL AS "reg_Til",
		mua.VIRKNINGFRA AS "virk_Fra",
		mua.VIRKNINGTIL AS "virk_Til",
		mua.VIRKNINGSAKTOER AS "virkAktoer",
		mua.FORRETNINGSHAENDELSE AS "haendelse",
		mua.FORRETNINGSPROCES AS "sagskatego",
		mua.SENESTESAGLOKALID AS "senesteSag",
		mua.ETAGEBETEGNELSE AS "etage",
		mua.LODAREAL AS "lodAreal",
		mua.LODBELIGGENHEDSTEKST AS "beliggenhe",
		mua.LODLITRA AS "lodLitra",
		mua.GEOMETRI SDO_GEOMETRY,
		mua.EJERLEJLIGHEDLOKALID AS "BFEnr_EJL"
FROM MATRIKEL_L1_PREPROD.EJERLEJLIGHEDSLOD mua
WHERE mua.status = 'Gældende' AND mua.REGISTRERINGTIL IS NULL AND mua.VIRKNINGFRA <= @Virkningstid AND (VIRKNINGTIL IS NULL OR @Virkningstid < VIRKNINGTIL);




-- Jordstykke
-- Selektering af Jordstykke som har status Gældende, ikke er afregistreret og hvor virkningen er på tidspunktet angivet ved parameteren @Virkningstid
-- Via join til Lodflade med samme virkningstidspunkt tilføres geometri.
create or replace view JORDSTYKKE
AS
SELECT 	mua.OBJECTID,
		mua.ID_LOKALID AS "lokalid",
		mua.REGISTRERINGFRA AS "reg_Fra",
		mua.REGISTRERINGTIL AS "reg_Til",
		mua.VIRKNINGFRA*/ AS "virk_Fra",
		mua.VIRKNINGTIL*/ AS "virk_Til",
		mua.VIRKNINGSAKTOER AS "virkAktoer",
		mua.FORRETNINGSHAENDELSE AS "haendelse",
		mua.FORRETNINGSPROCES AS "sagskatego",
		mua.SENESTESAGLOKALID AS "senesteSag",
		mua.AREALBEREGNINGSMETODE AS "beregnmeto",
		mua.AREALBETEGNELSE AS "betegnelse",
		mua.AREALTYPE AS "arealtype",
		mua.BRUGSRETSAREAL AS "brugsret",
		mua.FAELLESLOD AS "faelleslod",
		mua.MATRIKELNUMMER AS "matrikelnr",
		mua.REGISTRERETAREAL AS "reg_areal",
		mua.VANDAREALINKLUDERING AS "vandkode",
		mua.VEJAREAL AS "vejareal",
		mua.VEJAREALBEREGNINGSSTATUS AS "vejberegn",
		mua.FREDSKOV_FREDSKOVSAREAL AS "fredsAreal",
		mua.FREDSKOV_OMFANG AS "fredskOmf",
		mua.JORDRENTE_OMFANG AS "jordrenOmf",
		mua.KLITFREDNING_KLITFREDNINGSAREA AS "klitfAreal",
		mua.KLITFREDNING_OMFANG AS "klitfreOmf",
		mua.MAJORATSSKOV_MAJORATSSKOVSNUMM AS "skovnummer",
		mua.MAJORATSSKOV_OMFANG AS "majoratOmf",
		mua.STRANDBESKYTTELSE_OMFANG AS "strandbOmf",
		mua.STRANDBESKYTTELSE_STRANDBESKYT AS "stranAreal",
		CASE
		  WHEN EXISTS
           (SELECT 1 
			FROM MATRIKEL_L1_PREPROD.JORDSTYKKE_STORMFALD ss
			WHERE ss.JORDSTYKKEOBJECTID = mua.OBJECTID)
          THEN 'true'
          ELSE 'false'
		END
          AS "stormfald",
       mua.SKELFORRETNINGSSAGSLOKALID AS "SFORsagsID",
       mua.STAMMERFRAJORDSTYKKELOKALID AS "ModerJS",
       mua.SUPPLERENDEMAALINGSAGLOKALID AS "SUPMsagsID",
       mua.EJERLAVLOKALID AS "ejlavskode",
       mua.SOGNLOKALID AS "sognekode",
       mua.KOMMUNELOKALID AS "kommunkode",
       mua.REGIONLOKALID AS "regionkode",
       lf.geometri
FROM MATRIKEL_L1_PREPROD.JORDSTYKKE mua LEFT JOIN MATRIKEL_L1_PREPROD.LODFLADE mulod on  (mua.ID_LOKALID = mulod.JORDSTYKKELOKALID)
WHERE mua.status = 'Gældende' AND mua.REGISTRERINGTIL IS NULL AND mua.VIRKNINGFRA <= @Virkningstid AND (mua.VIRKNINGTIL IS NULL OR @Virkningstid < mua.VIRKNINGTIL)
and mulod.status = 'Gældende' AND mulod.REGISTRERINGTIL IS NULL AND mulod.VIRKNINGFRA <= @Virkningstid AND (mulod.VIRKNINGTIL IS NULL OR @Virkningstid < mulod.VIRKNINGTIL);


-- JordstykkeTemaflade
-- Selektering af JordstykkeTemaflade som har status Gældende, hvor tematype er fredskov, ikke er afregistreret og hvor virkningen er på tidspunktet angivet ved parameteren @Virkningstid
create or replace view FREDSKOVFLADE
AS
SELECT	mua.OBJECTID,
		mua.ID_LOKALID AS "lokalid",
		mua.REGISTRERINGFRA AS "reg_Fra",
		mua.REGISTRERINGTIL AS "reg_Til",
		mua.VIRKNINGFRA AS "virk_Fra",
		mua.VIRKNINGTIL AS "virk_Til",
		mua.VIRKNINGSAKTOER AS "virkAktoer",
		mua.FORRETNINGSHAENDELSE AS "haendelse",
		mua.FORRETNINGSPROCES AS "sagskatego",
		mua.SENESTESAGLOKALID AS "senesteSag",
		mua.GEOMETRI,
		mua.JORDSTYKKELOKALID AS "jordstykId"
FROM MATRIKEL_L1_PREPROD.JORDSTYKKETEMAFLADE mua
WHERE mua.status = 'Gældende' AND mua.Tematype = 'fredskov' AND mua.REGISTRERINGTIL IS NULL AND mua.VIRKNINGFRA <= @Virkningstid AND (VIRKNINGTIL IS NULL OR @Virkningstid < VIRKNINGTIL);


-- Selektering af JordstykkeTemaflade som har status Gældende, hvor tematype er klitfredning, ikke er afregistreret og hvor virkningen er på tidspunktet angivet ved parameteren @Virkningstid
create or replace view KLITFREDNINGFLADE
AS
SELECT	mua.OBJECTID,
		mua.ID_LOKALID AS "lokalid",
		mua.REGISTRERINGFRA AS "reg_Fra",
		mua.REGISTRERINGTIL AS "reg_Til",
		mua.VIRKNINGFRA AS "virk_Fra",
		mua.VIRKNINGTIL AS "virk_Til",
		mua.VIRKNINGSAKTOER AS "virkAktoer",
		mua.FORRETNINGSHAENDELSE AS "haendelse",
		mua.FORRETNINGSPROCES AS "sagskatego",
		mua.SENESTESAGLOKALID AS "senesteSag",
		mua.GEOMETRI,
		mua.JORDSTYKKELOKALID AS "jordstykId"
FROM MATRIKEL_L1_PREPROD.JORDSTYKKETEMAFLADE mua
WHERE mua.status = 'Gældende' AND mua.Tematype = 'klitfredning' AND mua.REGISTRERINGTIL IS NULL AND mua.VIRKNINGFRA <= @Virkningstid AND (VIRKNINGTIL IS NULL OR @Virkningstid < VIRKNINGTIL);

-- Selektering af JordstykkeTemaflade som har status Gældende, hvor tematype er strandbeskyttelse, ikke er afregistreret og hvor virkningen er på tidspunktet angivet ved parameteren @Virkningstid
create or replace view STRANDBESKYTTELSEFLADE
AS
SELECT	mua.OBJECTID,
		mua.ID_LOKALID AS "lokalid",
		mua.REGISTRERINGFRA AS "reg_Fra",
		mua.REGISTRERINGTIL AS "reg_Til",
		mua.VIRKNINGFRA AS "virk_Fra",
		mua.VIRKNINGTIL AS "virk_Til",
		mua.VIRKNINGSAKTOER AS "virkAktoer",
		mua.FORRETNINGSHAENDELSE AS "haendelse",
		mua.FORRETNINGSPROCES AS "sagskatego",
		mua.SENESTESAGLOKALID AS "senesteSag",
		mua.GEOMETRI,
		mua.JORDSTYKKELOKALID AS "jordstykId"
FROM MATRIKEL_L1_PREPROD.JORDSTYKKETEMAFLADE mua
WHERE mua.status = 'Gældende' AND mua.Tematype = 'strANDbeskyttelse' AND mua.REGISTRERINGTIL IS NULL AND mua.VIRKNINGFRA <= @Virkningstid AND (VIRKNINGTIL IS NULL OR @Virkningstid < VIRKNINGTIL);


-- Lodflade
-- Selektering af Lodflade som har status Gældende, ikke er afregistreret og hvor virkningen er på tidspunktet angivet ved parameteren @Virkningstid
create OR replace view LODFLADE
AS
SELECT	mua.OBJECTID,
		mua.ID_LOKALID AS "lokalid",
		mua.REGISTRERINGFRA AS "reg_Fra",
		mua.REGISTRERINGTIL AS "reg_Til",
		mua.VIRKNINGFRA AS "virk_Fra",
		mua.VIRKNINGTIL AS "virk_Til",
		mua.VIRKNINGSAKTOER AS "virkAktoer",
		mua.FORRETNINGSHAENDELSE AS "haendelse",
		mua.FORRETNINGSPROCES AS "sagskatego",
		mua.SENESTESAGLOKALID AS "senesteSag",
		mua.GEOMETRI,
		mua.JORDSTYKKELOKALID AS "jordstykId"
FROM MATRIKEL_L1_PREPROD.LODFLADE mua
WHERE mua.status = 'Gældende' AND mua.REGISTRERINGTIL IS NULL AND mua.VIRKNINGFRA <= @Virkningstid AND (VIRKNINGTIL IS NULL OR @Virkningstid < VIRKNINGTIL);


-- Temalinje
-- Selektering af Temalinje som har status Gældende, er af tematypen fredskov, ikke er afregistreret og hvor virkningen er på tidspunktet angivet ved parameteren @Virkningstid
create or replace view FREDSKOVLINJE
AS
SELECT	mua.OBJECTID,
		mua.ID_LOKALID AS "lokalid",
		mua.REGISTRERINGFRA AS "reg_Fra",
		mua.REGISTRERINGTIL AS "reg_Til",
		mua.VIRKNINGFRA AS "virk_Fra",
		mua.VIRKNINGTIL AS "virk_Til",
		mua.VIRKNINGSAKTOER AS "virkAktoer",
		mua.FORRETNINGSHAENDELSE AS "haendelse",
		mua.FORRETNINGSPROCES AS "sagskatego",
		mua.SENESTESAGLOKALID AS "senesteSag",
		mua.GEOMETRI,
		mua.FORLOEB AS "forloeb"
FROM MATRIKEL_L1_PREPROD.TEMALINJE mua
WHERE mua.status = 'Gældende' AND mua.Tematype = 'fredskov' AND mua.REGISTRERINGTIL IS NULL AND mua.VIRKNINGFRA <= @Virkningstid AND (VIRKNINGTIL IS NULL OR @Virkningstid < VIRKNINGTIL);

-- Selektering af Temalinje som har status Gældende, er af tematypen klitfredning, ikke er afregistreret og hvor virkningen er på tidspunktet angivet ved parameteren @Virkningstid
create or replace view KLITFREDNINGLINJE
AS
SELECT	mua.OBJECTID,
		mua.ID_LOKALID AS "lokalid",
		mua.REGISTRERINGFRA AS "reg_Fra",
		mua.REGISTRERINGTIL AS "reg_Til",
		mua.VIRKNINGFRA AS "virk_Fra",
		mua.VIRKNINGTIL AS "virk_Til",
		mua.VIRKNINGSAKTOER AS "virkAktoer",
		mua.FORRETNINGSHAENDELSE AS "haendelse",
		mua.FORRETNINGSPROCES AS "sagskatego",
		mua.SENESTESAGLOKALID AS "senesteSag",
		mua.GEOMETRI,
		mua.FORLOEB AS "forloeb"
FROM MATRIKEL_L1_PREPROD.TEMALINJE mua
WHERE mua.status = 'Gældende' AND mua.Tematype = 'klitfredning' AND mua.REGISTRERINGTIL IS NULL AND mua.VIRKNINGFRA <= @Virkningstid AND (VIRKNINGTIL IS NULL OR @Virkningstid < VIRKNINGTIL);

-- Selektering af Temalinje som har status Gældende, er af tematypen strandbeskyttelse, ikke er afregistreret og hvor virkningen er på tidspunktet angivet ved parameteren @Virkningstid
create or replace view STRANDBESKYTTELSELINJE
AS
SELECT	mua.OBJECTID,
		mua.ID_LOKALID AS "lokalid",
		mua.REGISTRERINGFRA AS "reg_Fra",
		mua.REGISTRERINGTIL AS "reg_Til",
		mua.VIRKNINGFRA AS "virk_Fra",
		mua.VIRKNINGTIL AS "virk_Til",
		mua.VIRKNINGSAKTOER AS "virkAktoer",
		mua.FORRETNINGSHAENDELSE AS "haendelse",
		mua.FORRETNINGSPROCES AS "sagskatego",
		mua.SENESTESAGLOKALID AS "senesteSag",
		mua.GEOMETRI,
		mua.FORLOEB AS "forloeb"
FROM MATRIKEL_L1_PREPROD.TEMALINJE mua
WHERE mua.status = 'Gældende' AND mua.Tematype = 'strANDbeskyttelse' AND mua.REGISTRERINGTIL IS NULL AND mua.VIRKNINGFRA <= @Virkningstid AND (VIRKNINGTIL IS NULL OR @Virkningstid < VIRKNINGTIL);



-- Matrikelskel
-- Selektering af Matrikelskel som har status Gældende, ikke er afregistreret og hvor virkningen er på tidspunktet angivet ved parameteren @Virkningstid
create or replace view MATRIKELSKEL
AS
SELECT	mua.OBJECTID,
		mua.ID_LOKALID AS "lokalid",
		mua.REGISTRERINGFRA AS "reg_Fra",
		mua.REGISTRERINGTIL AS "reg_Til",
		mua.VIRKNINGFRA AS "virk_Fra",
		mua.VIRKNINGTIL AS "virk_Til",
		mua.VIRKNINGSAKTOER AS "virkAktoer",
		mua.FORRETNINGSHAENDELSE AS "haendelse",
		mua.FORRETNINGSPROCES AS "sagskatego",
		mua.SENESTESAGLOKALID AS "senesteSag",
		mua.GEOMETRI,
		mua.SKELFORRETNINGSSAGSLOKALID AS "SFORsagsID",
		mua.ADMINISTRATIVGRAENSEKODE AS "admGraense",
		mua.OPRINDELSESSAGSLOKALID AS "oprindSag",
		mua.OPRINDELSEJOURNALNUMMER AS "oprindJnr",
		mua.PRODUKTIONSMETODE AS "prodMetode", 
		mua.SKELTYPE AS "skeltype",
		mua.TRANSFORMATIONSID AS "transId",
		mua.HOEJREJORDSTYKKELOKALID AS "hoejre_JS",
		mua.VENSTREJORDSTYKKELOKALID AS "venstre_JS",
		mua.SKELPUNKT_1LOKALID AS "skelpunkt_1",
		mua.SKELPUNKT_2LOKALID AS "skelpunkt_2"
FROM MATRIKEL_L1_PREPROD.MATRIKELSKEL mua
WHERE mua.status = 'Gældende' AND mua.REGISTRERINGTIL IS NULL AND mua.VIRKNINGFRA <= @Virkningstid AND (VIRKNINGTIL IS NULL OR @Virkningstid < VIRKNINGTIL);

-- NULLLinje
-- Selektering af NULLLinje som har status Gældende, ikke er afregistreret og hvor virkningen er på tidspunktet angivet ved parameteren @Virkningstid
create or replace view NULLINJE
AS
SELECT	mua.OBJECTID,
		mua.ID_LOKALID AS "lokalid",
		mua.REGISTRERINGFRA AS "reg_Fra",
		mua.REGISTRERINGTIL AS "reg_Til",
		mua.VIRKNINGFRA AS "virk_Fra",
		mua.VIRKNINGTIL AS "virk_Til",
		mua.VIRKNINGSAKTOER AS "virkAktoer",
		mua.FORRETNINGSHAENDELSE AS "haendelse",
		mua.FORRETNINGSPROCES AS "sagskatego",
		mua.SENESTESAGLOKALID AS "senesteSag",
		mua.GEOMETRI
FROM MATRIKEL_L1_PREPROD.NULLINJE mua
WHERE mua.status = 'Gældende' AND mua.REGISTRERINGTIL IS NULL AND mua.VIRKNINGFRA <= @Virkningstid AND (VIRKNINGTIL IS NULL OR @Virkningstid < VIRKNINGTIL);

-- Optagetvej
-- Selektering af Optagetvej som har status Gældende, ikke er afregistreret og hvor virkningen er på tidspunktet angivet ved parameteren @Virkningstid
create or replace view OPTAGETVEJ
AS
SELECT	mua.OBJECTID,
		mua.ID_LOKALID AS "lokalid",
		mua.REGISTRERINGFRA AS "reg_Fra",
		mua.REGISTRERINGTIL AS "reg_Til",
		mua.VIRKNINGFRA AS "virk_Fra",
		mua.VIRKNINGTIL AS "virk_Til",
		mua.VIRKNINGSAKTOER AS "virkAktoer",
		mua.FORRETNINGSHAENDELSE AS "haendelse",
		mua.FORRETNINGSPROCES AS "sagskatego",
		mua.SENESTESAGLOKALID AS "senesteSag",
		mua.GEOMETRI,
		mua.PRODUKTIONSMETODE AS "prodMetode",
		mua.VEJBREDDE AS "vejbredde",
		mua.VEJTYPE AS "vejtype",
		mua.TRANSFORMATIONSID AS "transId"
FROM MATRIKEL_L1_PREPROD.OPTAGETVEJ mua
WHERE mua.status = 'Gældende' AND mua.REGISTRERINGTIL IS NULL AND mua.VIRKNINGFRA <= @Virkningstid AND (VIRKNINGTIL IS NULL OR @Virkningstid < VIRKNINGTIL);


-- SamletFastEjendom
-- Selektering af SamletFastEjendom som har status Gældende, ikke er afregistreret og hvor virkningen er på tidspunktet angivet ved parameteren @Virkningstid
create or replace view SAMLETFASTEJENDOM
AS
SELECT	mua.OBJECTID,
		mua.ID_LOKALID AS "lokalid",
		mua.REGISTRERINGFRA AS "reg_Fra",
		mua.REGISTRERINGTIL AS "reg_Til",
		mua.VIRKNINGFRA AS "virk_Fra",
		mua.VIRKNINGTIL AS "virk_Til",
		mua.VIRKNINGSAKTOER AS "virkAktoer",
		mua.FORRETNINGSHAENDELSE AS "haendelse",
		mua.FORRETNINGSPROCES AS "sagskatego",
		mua.SENESTESAGLOKALID AS "senesteSag",
		mua.GEOMETRI,
		mua.BFENUMMER AS "BFEnr",
		mua.ARBEJDERBOLIG AS "arbejderbo",
		mua.ERFAELLESLOD "faelleslod",
		mua.HOVEDEJENDOMOPDELTIEJERLEJLIGH AS "opdeltIEjl",
		mua.LANDBRUGSNOTERING AS "lANDbrug",
		mua.UDSKILTVEJ AS "udskiltVej"
FROM MATRIKEL_L1_PREPROD.SAMLETFASTEJENDOM mua
WHERE mua.status = 'Gældende' AND mua.REGISTRERINGTIL IS NULL AND mua.VIRKNINGFRA <= @Virkningstid AND (VIRKNINGTIL IS NULL OR @Virkningstid < VIRKNINGTIL);


-- Skelpunkt
-- Selektering af Skelpunkt som har status Gældende, ikke er afregistreret og hvor virkningen er på tidspunktet angivet ved parameteren @Virkningstid
create or replace view SKELPUNKT
AS
SELECT	mua.OBJECTID,
		mua.ID_LOKALID AS "lokalid",
		mua.REGISTRERINGFRA AS "reg_Fra",
		mua.REGISTRERINGTIL AS "reg_Til",
		mua.VIRKNINGFRA AS "virk_Fra",
		mua.VIRKNINGTIL AS "virk_Til",
		mua.VIRKNINGSAKTOER AS "virkAktoer",
		mua.FORRETNINGSHAENDELSE AS "haendelse",
		mua.FORRETNINGSPROCES AS "sagskatego",
		mua.SENESTESAGLOKALID AS "senesteSag",
		mua.GEOMETRI,
		mua.INDLAEGNINGSTYPE AS "indlaegnin",
		mua.OPRINDELSEJOURNALNUMMER AS "oprindJnr",
		mua.PRODUKTIONSMETODE AS "prodMetode",
		mua.PUNKTKLASSE AS "punktKlass",
		mua.TRANSFORMATIONSID AS "transId",
		mua.OPRINDELSESSAGSLOKALID AS "sagsID",
		mua.SUPPLERENDEMAALINGSAGSLOKALID AS "SUPMsagsID"
FROM MATRIKEL_L1_PREPROD.SKELPUNKT mua
WHERE mua.status = 'Gældende' AND mua.REGISTRERINGTIL IS NULL AND mua.VIRKNINGFRA <= @Virkningstid AND (VIRKNINGTIL IS NULL OR @Virkningstid < VIRKNINGTIL);
