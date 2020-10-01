-- MatrikulaerSag
-- Selektering af igangværende MatrikulaerSag ud fra registrerings- og virkningstider, som ikke har status ('Annulleret', 'Afsluttet', 'Aflyst')
-- Geometrien til en sag, hentes fra hjælpeview SENESTESAG_MBR_F_MV
CREATE OR REPLACE VIEW MATRIKULAERSAG_I
AS
SELECT * FROM MATRIKEL_L1_PREPROD.MATRIKULAERSAG WHERE 1=0;

-- XKLHA, 07-09-2018: MatrikulærSag er midlertidigt deaktiveret
/* SELECT * FROM (
	SELECT mua.OBJECTID,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSOMRAADE,
		mua.JOURNALISERINGSDATO,
		mua.KOMMUNE,
		mua.MATRIKELMYNDIGHEDENSJOURNALNUM,
		mua.REGISTRERINGFRA,
		mua.REKVIRENTREF,
		mua.SAGSTITEL,
		mua.STATUS,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.JORDSTYKKELOKALID,
		mua.EJERLAVLOKALID,
		smm.GEOMETRI,
		mua.GMLID
	FROM MATRIKEL_L1_PREPROD.MATRIKULAERSAG mua, SENESTESAG_MBR_F_MV smm
	WHERE mua.status NOT IN ('Annulleret', 'Afsluttet', 'Aflyst') 
		AND mua.REGISTRERINGTIL IS NULL 
		AND mua.VIRKNINGFRA <= LOCALTIMESTAMP 
		AND (   mua.VIRKNINGTIL IS NULL OR LOCALTIMESTAMP < mua.VIRKNINGTIL)
        AND smm.senestesaglokalid = mua.id_lokalid)
WHERE geometri IS NOT NULL; */

-- Selektering af afsluttede MatrikulaerSag ud fra registrerings- og virkningstider, som har status 'Afsluttet'
-- Geometrien til en sag, hentes fra hjælpeview SENESTESAG_MBR_G_MV
CREATE OR REPLACE VIEW MATRIKULAERSAG_A
AS
   CREATE OR REPLACE VIEW MATRIKULAERSAG_A
   AS
   SELECT * FROM MATRIKEL_L1_PREPROD.MATRIKULAERSAG WHERE 1=0;

-- XKLHA, 07-09-2018: MatrikulærSag er midlertidigt deaktiveret
/* SELECT * FROM (
	SELECT mua.OBJECTID,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSOMRAADE,
		mua.JOURNALISERINGSDATO,
		mua.KOMMUNE,
		mua.MATRIKELMYNDIGHEDENSJOURNALNUM,
		mua.REGISTRERINGFRA,
		mua.REKVIRENTREF,
		mua.SAGSTITEL,
		mua.STATUS,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.JORDSTYKKELOKALID,
		mua.EJERLAVLOKALID,
		smm.GEOMETRI,
		mua.GMLID
	FROM MATRIKEL_L1_PREPROD.MATRIKULAERSAG mua, SENESTESAG_MBR_G_MV smm
	WHERE mua.status='Afsluttet' 
		AND mua.REGISTRERINGTIL IS NULL 
		AND mua.VIRKNINGFRA <= LOCALTIMESTAMP 
		AND (   mua.VIRKNINGTIL IS NULL OR LOCALTIMESTAMP < mua.VIRKNINGTIL)
        AND smm.senestesaglokalid = mua.id_lokalid)
WHERE geometri IS NOT NULL; */



-- View der danner en samlet boundingbox ud fra alle de ikke-afregistrerede Matrikulære elementer der indgår i samme matrikelsag, og hvor status for disse er 'Gældende'
-- Implementeret lidt specielt grundet en Oracle bug der optræder nu og da når man benytter Oracles ”get_mbr”, så vi finder den selv således :


-- XKLHA, 07-09-2018: MatrikulærSag er midlertidigt deaktiveret
/* CREATE MATERIALIZED VIEW SENESTESAG_MBR_G_MV 
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
WITH PRIMARY KEY
AS 
SELECT t.senestesaglokalid,
         MDSYS.SDO_GEOMETRY (2003,
                             25832,
                             NULL,
                             MDSYS.SDO_ELEM_INFO_ARRAY (1, 1003, 3),
                             MDSYS.SDO_ORDINATE_ARRAY (MIN (west),
                                                       MIN (south),
                                                       MAX (east),
                                                       MAX (north)))  -- Lav en 2D-Polygon med 4 koordinater west,south,east,north med srid 28832
            GEOMETRI
    FROM (SELECT senestesaglokalid,
                 west,
                 south,
                 north,
                 east
            FROM (  SELECT lf.senestesaglokalid senestesaglokalid,
                           MIN (t.X) west,
                           MAX (t.X) east,
                           MIN (t.Y) south,
                           MAX (t.Y) north -- Find min og max X og Y fra Jorstykket/Lodfladens koordinater igennem tabellen 't'
                      FROM MATRIKEL_L1_PREPROD.jordstykke js,
                           MATRIKEL_L1_PREPROD.lodflade lf,
                           TABLE (SDO_UTIL.GETVERTICES (lf.geometri)) t -- Lav en inMemory tabel 't' med alle kooridinater for den Lodflade der hører til Jordstykket
                     WHERE     lf.JORDSTYKKELOKALID = js.id_lokalid
                           AND js.registreringtil IS NULL
                           AND lf.status NOT IN ('Ikke Gennemført')
                           AND js.status NOT IN ('Ikke Gennemført')
                           AND js.registreringfra =
                                  (SELECT MAX (bb.registreringfra) -- Vælger den nyeste, ikke afregistrerede og gældende version af et Jordstykket(id_lokalid)
                                     FROM MATRIKEL_L1_PREPROD.jordstykke bb
                                    WHERE     bb.registreringtil IS NULL
                                          AND bb.status = 'Gældende'
                                          AND bb.id_lokalid = js.id_lokalid)
                  GROUP BY lf.senestesaglokalid
                  UNION ALL
                    SELECT el.senestesaglokalid senestesaglokalid, -- Samme opskrift som ovenfor men for Ejerelejlighed
                           MIN (t.X) west,
                           MAX (t.X) east,
                           MIN (t.Y) south,
                           MAX (t.Y) north 
                      FROM MATRIKEL_L1_PREPROD.ejerlejlighed ej,
                           MATRIKEL_L1_PREPROD.ejerlejlighedslod el,
                           TABLE (SDO_UTIL.GETVERTICES (el.geometri)) t
                     WHERE     EL.EJERLEJLIGHEDLOKALID = ej.id_lokalid
                           AND ej.registreringtil IS NULL
                           AND el.status NOT IN ('Ikke Gennemført')
                           AND ej.status NOT IN ('Ikke Gennemført')
                           AND ej.registreringfra =
                                  (SELECT MAX (bb.registreringfra)
                                     FROM MATRIKEL_L1_PREPROD.ejerlejlighed bb
                                    WHERE     bb.registreringtil IS NULL
                                          AND bb.status = 'Gældende'
                                          AND bb.id_lokalid = ej.id_lokalid)
                  GROUP BY el.senestesaglokalid
                  UNION ALL
                    SELECT sf.senestesaglokalid senestesaglokalid, -- Samme opskrift som ovenfor men for Bygningpaafremmedgrundflade
                           MIN (t.X) west,
                           MAX (t.X) east,
                           MIN (t.Y) south,
                           MAX (t.Y) north
                      FROM MATRIKEL_L1_PREPROD.bygningpaafremmedgrundflade sf,
                           TABLE (SDO_UTIL.GETVERTICES (sf.geometri)) t
                     WHERE     sf.registreringtil IS NULL
                           AND sf.status NOT IN ('Ikke Gennemført')
                           AND sf.registreringfra =
                                  (SELECT MAX (bb.registreringfra)
                                     FROM MATRIKEL_L1_PREPROD.bygningpaafremmedgrundflade bb
                                    WHERE     bb.registreringtil IS NULL
                                          AND bb.status  = 'Gældende'
                                          AND bb.id_lokalid = sf.id_lokalid)
                  GROUP BY sf.senestesaglokalid
                  UNION ALL
                    SELECT sf.senestesaglokalid senestesaglokalid, -- Samme opskrift som ovenfor men for Bygningpaafremmedgrundpunkt
                           MIN (t.X) west,
                           MAX (t.X) east,
                           MIN (t.Y) south,
                           MAX (t.Y) north
                      FROM MATRIKEL_L1_PREPROD.bygningpaafremmedgrundpunkt sf,
                           TABLE (SDO_UTIL.GETVERTICES (sf.geometri)) t
                     WHERE     sf.registreringtil IS NULL
                           AND sf.status NOT IN ('Ikke Gennemført')
                           AND sf.registreringfra =
                                  (SELECT MAX (bb.registreringfra)
                                     FROM MATRIKEL_L1_PREPROD.bygningpaafremmedgrundpunkt bb
                                    WHERE     bb.registreringtil IS NULL
                                          AND bb.status = 'Gældende'
                                          AND bb.id_lokalid = sf.id_lokalid)
                  GROUP BY sf.senestesaglokalid
                  UNION ALL
                    SELECT sf.senestesaglokalid senestesaglokalid, -- Samme opskrift som ovenfor men for samletfastejendom
                           MIN (t.X) west,
                           MAX (t.X) east,
                           MIN (t.Y) south,
                           MAX (t.Y) north
                      FROM MATRIKEL_L1_PREPROD.samletfastejendom sf,
                           TABLE (SDO_UTIL.GETVERTICES (sf.geometri)) t
                     WHERE     sf.registreringtil IS NULL
                           AND sf.status NOT IN ('Ikke Gennemført')
                           AND sf.registreringfra =
                                  (SELECT MAX (bb.registreringfra)
                                     FROM MATRIKEL_L1_PREPROD.samletfastejendom bb
                                    WHERE     bb.registreringtil IS NULL
                                          AND bb.status  = 'Gældende'
                                          AND bb.id_lokalid = sf.id_lokalid)
                  GROUP BY sf.senestesaglokalid)) t
GROUP BY senestesaglokalid; */


-- View der danner en samlet boundingbox ud fra alle de ikke-afregistrerede Matrikulære elementer der indgår i samme matrikelsag, og hvor status er 'Foreløbig'

-- XKLHA, 07-09-2018: MatrikulærSag er midlertidigt deaktiveret
/* CREATE MATERIALIZED VIEW SENESTESAG_MBR_F_MV (SENESTESAGLOKALID,GEOMETRI)
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
WITH PRIMARY KEY
AS 
SELECT t.senestesaglokalid,
         MDSYS.SDO_GEOMETRY (2003,
                             25832,
                             NULL,
                             MDSYS.SDO_ELEM_INFO_ARRAY (1, 1003, 3),
                             MDSYS.SDO_ORDINATE_ARRAY (MIN (west),
                                                       MIN (south),
                                                       MAX (east),
                                                       MAX (north)))
            GEOMETRI
    FROM (SELECT senestesaglokalid,
                 west,
                 south,
                 north,
                 east
            FROM (  SELECT lf.senestesaglokalid senestesaglokalid,
                           MIN (t.X) west,
                           MAX (t.X) east,
                           MIN (t.Y) south,
                           MAX (t.Y) north
                      FROM MATRIKEL_L1_PREPROD.jordstykke js,
                           MATRIKEL_L1_PREPROD.lodflade lf,
                           TABLE (SDO_UTIL.GETVERTICES (lf.geometri)) t
                     WHERE     LF.JORDSTYKKELOKALID = js.id_lokalid
                           AND js.registreringtil IS NULL
                           AND lf.status NOT IN ('Ikke Gennemført')
                           AND lf.VIRKNINGFRA <= LOCALTIMESTAMP
                           AND lf.registreringtil IS NULL
                           AND (lf.VIRKNINGTIL IS NULL OR LOCALTIMESTAMP < lf.VIRKNINGTIL)                                                      
                           AND js.status NOT IN ('Ikke Gennemført')
                           AND js.registreringfra =
                                  (SELECT MAX (bb.registreringfra)
                                     FROM MATRIKEL_L1_PREPROD.jordstykke bb
                                    WHERE     bb.registreringtil IS NULL
                                          AND bb.status = 'Foreløbig'
                                          AND bb.id_lokalid = js.id_lokalid)
                  GROUP BY lf.senestesaglokalid
                  UNION ALL
                    SELECT el.senestesaglokalid senestesaglokalid,
                           MIN (t.X) west,
                           MAX (t.X) east,
                           MIN (t.Y) south,
                           MAX (t.Y) north
                      FROM MATRIKEL_L1_PREPROD.ejerlejlighed ej,
                           MATRIKEL_L1_PREPROD.ejerlejlighedslod el,
                           TABLE (SDO_UTIL.GETVERTICES (el.geometri)) t
                     WHERE     EL.EJERLEJLIGHEDLOKALID = ej.id_lokalid
                           AND ej.registreringtil IS NULL
                           AND el.status NOT IN ('Ikke Gennemført')
                           AND el.VIRKNINGFRA <= LOCALTIMESTAMP
                           AND el.registreringtil IS NULL
                           AND (el.VIRKNINGTIL IS NULL OR LOCALTIMESTAMP < el.VIRKNINGTIL)                             
                           AND ej.status NOT IN ('Ikke Gennemført')
                           AND ej.registreringfra =
                                  (SELECT MAX (bb.registreringfra)
                                     FROM MATRIKEL_L1_PREPROD.ejerlejlighed bb
                                    WHERE     bb.registreringtil IS NULL
                                          AND bb.status = 'Foreløbig'
                                          AND bb.id_lokalid = ej.id_lokalid)
                  GROUP BY el.senestesaglokalid
                  UNION ALL
                    SELECT sf.senestesaglokalid senestesaglokalid,
                           MIN (t.X) west,
                           MAX (t.X) east,
                           MIN (t.Y) south,
                           MAX (t.Y) north
                      FROM MATRIKEL_L1_PREPROD.bygningpaafremmedgrundflade sf,
                           TABLE (SDO_UTIL.GETVERTICES (sf.geometri)) t
                     WHERE     sf.registreringtil IS NULL
                           AND sf.VIRKNINGFRA <= LOCALTIMESTAMP
                           AND (sf.VIRKNINGTIL IS NULL OR LOCALTIMESTAMP < sf.VIRKNINGTIL)                      
                           AND sf.status NOT IN ('Ikke Gennemført')
                           AND sf.registreringfra =
                                  (SELECT MAX (bb.registreringfra)
                                     FROM MATRIKEL_L1_PREPROD.bygningpaafremmedgrundflade bb
                                    WHERE     bb.registreringtil IS NULL
                                          AND bb.status = 'Foreløbig'
                                          AND bb.id_lokalid = sf.id_lokalid)
                  GROUP BY sf.senestesaglokalid
                  UNION ALL
                    SELECT sf.senestesaglokalid senestesaglokalid,
                           MIN (t.X) west,
                           MAX (t.X) east,
                           MIN (t.Y) south,
                           MAX (t.Y) north
                      FROM MATRIKEL_L1_PREPROD.bygningpaafremmedgrundpunkt sf,
                           TABLE (SDO_UTIL.GETVERTICES (sf.geometri)) t
                     WHERE     sf.registreringtil IS NULL
                           AND sf.status NOT IN ('Ikke Gennemført')
                           AND sf.VIRKNINGFRA <= LOCALTIMESTAMP
                           AND (sf.VIRKNINGTIL IS NULL OR LOCALTIMESTAMP < sf.VIRKNINGTIL)                            
                           AND sf.registreringfra =
                                  (SELECT MAX (bb.registreringfra)
                                     FROM MATRIKEL_L1_PREPROD.bygningpaafremmedgrundpunkt bb
                                    WHERE     bb.registreringtil IS NULL
                                          AND bb.status = 'Foreløbig'
                                          AND bb.id_lokalid = sf.id_lokalid)
                  GROUP BY sf.senestesaglokalid
                  UNION ALL
                    SELECT sf.senestesaglokalid senestesaglokalid,
                           MIN (t.X) west,
                           MAX (t.X) east,
                           MIN (t.Y) south,
                           MAX (t.Y) north
                      FROM MATRIKEL_L1_PREPROD.samletfastejendom sf,
                           TABLE (SDO_UTIL.GETVERTICES (sf.geometri)) t
                     WHERE     sf.registreringtil IS NULL
                           AND sf.status NOT IN ('Ikke Gennemført')
                           AND sf.VIRKNINGFRA <= LOCALTIMESTAMP
                           AND (sf.VIRKNINGTIL IS NULL OR LOCALTIMESTAMP < sf.VIRKNINGTIL)                            
                           AND sf.registreringfra =
                                  (SELECT MAX (bb.registreringfra)
                                     FROM MATRIKEL_L1_PREPROD.samletfastejendom bb
                                    WHERE     bb.registreringtil IS NULL
                                          AND bb.status = 'Foreløbig'
                                          AND bb.id_lokalid = sf.id_lokalid)
                  GROUP BY sf.senestesaglokalid)) t
GROUP BY senestesaglokalid; */




-- BygningPaaFremmedGrundFlade
-- Selektering af BygningPaaFremmedGrundFlade som har status Gældende, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW BYGNINGPAAFREMMEDGRUNDFLADE_G
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.BFENUMMER,
		mua.OPDELTIEJERLEJLIGHEDER,
		mua.GEOMETRI,
		mua.OPRINDELSE,
		mua.PAAHAVET,
		mua.RIDS,
		mua.SAMLETFASTEJENDOMLOKALID,
		mua.SENESTESAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.BYGNINGPAAFREMMEDGRUNDFLADE mua
where mua.status = 'Gældende' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Selektering af BygningPaaFremmedGrundFlade som har status Foreløbig, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW BYGNINGPAAFREMMEDGRUNDFLADE_F
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.PAATAENKTHANDLING,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.BFENUMMER,
		mua.OPDELTIEJERLEJLIGHEDER,
		mua.GEOMETRI,
		mua.OPRINDELSE,
		mua.PAAHAVET,
		mua.RIDS,
		mua.SAMLETFASTEJENDOMLOKALID,
		mua.SENESTESAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.BYGNINGPAAFREMMEDGRUNDFLADE mua
where mua.status = 'Foreløbig' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- BygningPaaFremmedGrundPunkt
-- Selektering af BygningPaaFremmedGrundPunkt som har status Gældende, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW BYGNINGPAAFREMMEDGRUNDPUNKT_G
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.BFENUMMER,
		mua.OPDELTIEJERLEJLIGHEDER,
		mua.GEOMETRI,
		mua.OPRINDELSE,
		mua.PAAHAVET,
		mua.RIDS,
		mua.SAMLETFASTEJENDOMLOKALID,
		mua.SENESTESAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.BYGNINGPAAFREMMEDGRUNDPUNKT mua
where mua.status = 'Gældende' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Selektering af BygningPaaFremmedGrundPunkt som har status Foreløbig, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW BYGNINGPAAFREMMEDGRUNDPUNKT_F
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.PAATAENKTHANDLING,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.BFENUMMER,
		mua.OPDELTIEJERLEJLIGHEDER,
		mua.GEOMETRI,
		mua.OPRINDELSE,
		mua.PAAHAVET,
		mua.RIDS,
		mua.SAMLETFASTEJENDOMLOKALID,
		mua.SENESTESAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.BYGNINGPAAFREMMEDGRUNDPUNKT mua
where mua.status = 'Foreløbig' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Centroide
-- Selektering af Centroide som har status Gældende, ikke er afregistreret og som er i virkning.
-- Yderligere hentes matrikelnummer og ejerlavskode via et join til jordstykke
create OR REPLACE VIEW CENTROIDE_G
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.JORDSTYKKELOKALID,
		muj.EJERLAVLOKALID as EJERLAVSKODE,
		muj.MATRIKELNUMMER,
		mua.SENESTESAGLOKALID,
		mua.GEOMETRI,
		mua.GMLID
  FROM MATRIKEL_L1_PREPROD.CENTROIDE mua,
       (select distinct MATRIKELNUMMER , ID_LOKALID, EJERLAVLOKALID from MATRIKEL_L1_PREPROD.JORDSTYKKE) muj
WHERE     mua.status = 'Gældende'
       AND mua.REGISTRERINGTIL IS NULL
       AND mua.VIRKNINGFRA <= LOCALTIMESTAMP
       AND (mua.VIRKNINGTIL IS NULL OR LOCALTIMESTAMP < mua.VIRKNINGTIL)
       and muj.ID_LOKALID = mua.JORDSTYKKELOKALID;

-- Selektering af Centroide som har status Foreløbig, ikke er afregistreret og som er i virkning
-- Yderligere hentes matrikelnummer og ejerlavskode via et join til jordstykke
create OR REPLACE VIEW CENTROIDE_F
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.PAATAENKTHANDLING,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.JORDSTYKKELOKALID,
		muj.EJERLAVLOKALID as EJERLAVSKODE,
		muj.MATRIKELNUMMER,
		mua.SENESTESAGLOKALID,
		mua.GEOMETRI,
		mua.GMLID
  FROM MATRIKEL_L1_PREPROD.CENTROIDE mua,
       (select distinct MATRIKELNUMMER , ID_LOKALID, EJERLAVLOKALID from MATRIKEL_L1_PREPROD.JORDSTYKKE) muj
WHERE     mua.status = 'Foreløbig'
       AND mua.REGISTRERINGTIL IS NULL
       AND mua.VIRKNINGFRA <= LOCALTIMESTAMP
       AND (mua.VIRKNINGTIL IS NULL OR LOCALTIMESTAMP < mua.VIRKNINGTIL)
       and muj.ID_LOKALID = mua.JORDSTYKKELOKALID; 


-- Ejerlav
-- Selektering af Ejerlav som har status Gældende, ikke er afregistreret og som er i virkning.
create OR REPLACE VIEW EJERLAV_G
AS
select mua.OBJECTID,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.EJERLAVSKODE,
		mua.EJERLAVSNAVN,
		mua.GEOMETRI,
		mua.SAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.EJERLAV mua
where mua.status = 'Gældende' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Selektering af Ejerlav som har status Foreløbig, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW EJERLAV_F
AS
select mua.OBJECTID,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.EJERLAVSKODE,
		mua.EJERLAVSNAVN,
		mua.GEOMETRI,
		mua.SAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.EJERLAV mua
where mua.status = 'Foreløbig' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);


-- Matrikelkommune
-- Selektering af Matrikelkommune som har status Gældende, ikke er afregistreret og som er i virkning.
create OR REPLACE VIEW MATRIKELKOMMUNE_G
AS
select mua.OBJECTID,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.KOMMUNEKODE,
		mua.KOMMUNENAVN,
		mua.GEOMETRI,
		mua.SAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.MATRIKELKOMMUNE mua
where mua.status = 'Gældende' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Selektering af Matrikelkommune som har status Foreløbig, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW MATRIKELKOMMUNE_F
AS
select mua.OBJECTID,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.KOMMUNEKODE,
		mua.KOMMUNENAVN,
		mua.GEOMETRI,
		mua.SAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.MATRIKELKOMMUNE mua
where mua.status = 'Foreløbig' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);


-- Matrikelsogn
-- Selektering af Matrikelsogn som har status Gældende, ikke er afregistreret og som er i virkning.
create OR REPLACE VIEW MATRIKELSOGN_G
AS
select mua.OBJECTID,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.SOGNEKODE,
		mua.SOGNENAVN,
		mua.GEOMETRI,
		mua.SAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.MATRIKELSOGN mua
where mua.status = 'Gældende' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Selektering af Matrikelsogn som har status Foreløbig, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW MATRIKELSOGN_F
AS
select mua.OBJECTID,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.SOGNEKODE,
		mua.SOGNENAVN,
		mua.GEOMETRI,
		mua.SAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.MATRIKELSOGN mua
where mua.status = 'Foreløbig' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);


-- Ejerlejlighed
-- Selektering af Ejerlejlighed som har status Gældende, ikke er afregistreret og som er i virkning
-- Geometrien til ejerlejlighed hentes via en aggregering af geometrierne fra de ejerlejlighedslodder der hører til ejerlejligheden 
create OR REPLACE VIEW EJERLEJLIGHED_G (MATRIKEL_GIS.EJERLEJLIGHED_G_MV er en materialisering af MATRIKEL_GIS.EJERLEJLIGHED_G)
AS
select * from (
SELECT mua.OBJECTID,
       mua.FORRETNINGSHAENDELSE,
       mua.FORRETNINGSPROCES,
       mua.ID_NAMESPACE,
       mua.ID_LOKALID,
       mua.PAATAENKTHANDLING,
       mua.REGISTRERINGFRA,
       mua.VIRKNINGFRA,
       mua.VIRKNINGSAKTOER,
       mua.BFENUMMER,
       mua.EJERLEJLIGHEDSKORT,
       mua.EJERLEJLIGHEDSNUMMER,
       mua.FORDELINGSTALNAEVNER,
       mua.FORDELINGSTALTAELLER,
       mua.IBYGNINGPAAFREMMEDGRUND,
       mua.SAMLETAREAL,
       mua.SAMLETFASTEJENDOMLOKALID,
       mua.B_BYGNINGPAAFREMMEDGRUNDFLADEL,
       mua.B_BYGNINGPAAFREMMEDGRUNDPUNKTL,
       mua.SENESTESAGLOKALID,
       (select sdo_aggr_union (sdoaggrtype (mulod.GEOMETRI, 0.005)) 
			from MATRIKEL_L1_PREPROD.EJERLEJLIGHEDSLOD mulod 
			where mua.ID_LOKALID = mulod.EJERLEJLIGHEDLOKALID
			AND mulod.status = 'Gældende'
			AND mulod.REGISTRERINGTIL IS NULL
			AND mulod.VIRKNINGFRA <= CURRENT_TIMESTAMP
			AND (   mulod.VIRKNINGTIL IS NULL
				OR CURRENT_TIMESTAMP < mulod.VIRKNINGTIL)        
        ) GEOMETRI,
       mua.GMLID
	   FROM MATRIKEL_L1_PREPROD.EJERLEJLIGHED mua
	   WHERE mua.status = 'Gældende'
	   AND mua.REGISTRERINGTIL IS NULL
	   AND mua.VIRKNINGFRA <= CURRENT_TIMESTAMP
	   AND (mua.VIRKNINGTIL IS NULL OR CURRENT_TIMESTAMP < mua.VIRKNINGTIL))
 WHERE geometri is not null;


-- Selektering af Ejerlejlighed som har status Foreløbig, ikke er afregistreret og som er i virkning
-- Geometrien til ejerlejlighed hentes via en aggregering af geometrierne fra de ejerlejlighedslodder der hører til ejerlejligheden
create OR REPLACE VIEW EJERLEJLIGHED_F (MATRIKEL_GIS.EJERLEJLIGHED_F_MV er en materialisering af MATRIKEL_GIS.EJERLEJLIGHED_F)
AS
select * from (
SELECT mua.OBJECTID,
       mua.FORRETNINGSHAENDELSE,
       mua.FORRETNINGSPROCES,
       mua.ID_NAMESPACE,
       mua.ID_LOKALID,
       mua.PAATAENKTHANDLING,
       mua.REGISTRERINGFRA,
       mua.VIRKNINGFRA,
       mua.VIRKNINGSAKTOER,
       mua.BFENUMMER,
       mua.EJERLEJLIGHEDSKORT,
       mua.EJERLEJLIGHEDSNUMMER,
       mua.FORDELINGSTALNAEVNER,
       mua.FORDELINGSTALTAELLER,
       mua.IBYGNINGPAAFREMMEDGRUND,
       mua.SAMLETAREAL,
       mua.SAMLETFASTEJENDOMLOKALID,
       mua.B_BYGNINGPAAFREMMEDGRUNDFLADEL,
       mua.B_BYGNINGPAAFREMMEDGRUNDPUNKTL,
       mua.SENESTESAGLOKALID,
       (select sdo_aggr_union (sdoaggrtype (mulod.GEOMETRI, 0.005)) 
			from MATRIKEL_L1_PREPROD.EJERLEJLIGHEDSLOD mulod 
			where mua.ID_LOKALID = mulod.EJERLEJLIGHEDLOKALID			
			AND (mulod.id_lokalid, mulod.registreringfra) in (select B.id_lokalid,max(B.registreringfra) from MATRIKEL_L1_PREPROD.EJERLEJLIGHEDSLOD B where b.REGISTRERINGTIL is null group by B.id_lokalid)
			AND mulod.REGISTRERINGTIL IS NULL
			AND mulod.VIRKNINGFRA <= CURRENT_TIMESTAMP
			AND (   mulod.VIRKNINGTIL IS NULL
				OR CURRENT_TIMESTAMP < mulod.VIRKNINGTIL)
        ) GEOMETRI,
       mua.GMLID
	   FROM MATRIKEL_L1_PREPROD.EJERLEJLIGHED mua
	   WHERE mua.status = 'Foreløbig'
	   AND mua.REGISTRERINGTIL IS NULL
	   AND mua.VIRKNINGFRA <= CURRENT_TIMESTAMP
	   AND (mua.VIRKNINGTIL IS NULL OR CURRENT_TIMESTAMP < mua.VIRKNINGTIL))
 WHERE geometri is not null;
 

-- Ejerlejlighedslod
-- Selektering af Ejerlejlighedslod som har status Gældende, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW EJERLEJLIGHEDSLOD_G
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.ETAGEBETEGNELSE,
		mua.LODAREAL,
		mua.LODBELIGGENHEDSTEKST,
		mua.LODLITRA,
		mua.GEOMETRI SDO_GEOMETRY,
		mua.EJERLEJLIGHEDLOKALID,
		mua.SENESTESAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.EJERLEJLIGHEDSLOD mua
where mua.status = 'Gældende' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Selektering af Ejerlejlighedslod som har status Foreløbig, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW EJERLEJLIGHEDSLOD_F
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.PAATAENKTHANDLING,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.ETAGEBETEGNELSE,
		mua.LODAREAL,
		mua.LODBELIGGENHEDSTEKST,
		mua.LODLITRA,
		mua.GEOMETRI SDO_GEOMETRY,
		mua.EJERLEJLIGHEDLOKALID,
		mua.SENESTESAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.EJERLEJLIGHEDSLOD mua
where mua.status = 'Foreløbig' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Jordstykke
-- Selektering af Jordstykke som har status Gældende, ikke er afregistreret og som er i virkning
-- Via join til Lodflade hentes geometri til Jordstykke fra et gældende Lodflade 
create OR REPLACE VIEW JORDSTYKKE_G
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.AREALBEREGNINGSMETODE,
		mua.AREALBETEGNELSE,
		mua.AREALTYPE,
		mua.BRUGSRETSAREAL,
		mua.DELNUMMER,
		mua.FAELLESLOD,
		mua.MATRIKELNUMMER,
		mua.REGISTRERETAREAL,
		mua.VANDAREALINKLUDERING,
		mua.VEJAREAL,
		mua.VEJAREALBEREGNINGSSTATUS,
		mua.FREDSKOV_FREDSKOVSAREAL,
		mua.FREDSKOV_OMFANG,
		mua.JORDRENTE_OMFANG,
		mua.KLITFREDNING_KLITFREDNINGSAREA,
		mua.KLITFREDNING_OMFANG,
		mua.MAJORATSSKOV_MAJORATSSKOVSNUMM,
		mua.MAJORATSSKOV_OMFANG,
		mua.STRANDBESKYTTELSE_OMFANG,
		mua.STRANDBESKYTTELSE_STRANDBESKYT,
        CASE
          WHEN exists (select 1 from MATRIKEL_L1_PREPROD.JORDSTYKKE_STORMFALD  ss
                       where ss.JORDSTYKKEOBJECTID=mua.OBJECTID) then
                        'true'
          ELSE 'false'
        END AS STORMFALDSNOTERING,
		mua.SAMLETFASTEJENDOMLOKALID,
		mua.SKELFORRETNINGSSAGSLOKALID,
		mua.STAMMERFRAJORDSTYKKELOKALID,
		mua.SUPPLERENDEMAALINGSAGLOKALID,
		mua.EJERLAVLOKALID as EJERLAVSKODE,
		mua.SOGNLOKALID as SOGNEKODE,
		mua.KOMMUNELOKALID as KOMMUNEKODE,
		mua.REGIONLOKALID as REGIONSKODE,
		mua.SENESTESAGLOKALID,
		mulod.GEOMETRI,
		mua.GMLID
from MATRIKEL_L1_PREPROD.JORDSTYKKE mua LEFT JOIN MATRIKEL_L1_PREPROD.LODFLADE mulod on  (mua.ID_LOKALID = mulod.JORDSTYKKELOKALID)
where mua.status = 'Gældende' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (mua.VIRKNINGTIL is NULL or LOCALTIMESTAMP < mua.VIRKNINGTIL)
and mulod.status = 'Gældende' and mulod.REGISTRERINGTIL is NULL and mulod.VIRKNINGFRA <= LOCALTIMESTAMP and (mulod.VIRKNINGTIL is NULL or LOCALTIMESTAMP < mulod.VIRKNINGTIL);

-- Selektering af Jordstykke som har status Foreløbig, ikke er afregistreret og som er i virkning
-- Via join til Lodflade hentes geometri til Jordstykke fra den nyeste ikke afregistrerede lodflade der referere til Jordstykket
 CREATE OR REPLACE FORCE EDITIONABLE VIEW "MATRIKEL_GIS"."JORDSTYKKE_F" ("OBJECTID", "FORRETNINGSHAENDELSE", "FORRETNINGSPROCES", "ID_NAMESPACE", "ID_LOKALID", "PAATAENKTHANDLING", "REGISTRERINGFRA", "VIRKNINGFRA", "VIRKNINGSAKTOER", "AREALBEREGNINGSMETODE", "AREALBETEGNELSE", "AREALTYPE", "BRUGSRETSAREAL", "DELNUMMER", "FAELLESLOD", "MATRIKELNUMMER", "REGISTRERETAREAL", "VANDAREALINKLUDERING", "VEJAREAL", "VEJAREALBEREGNINGSSTATUS", "FREDSKOV_FREDSKOVSAREAL", "FREDSKOV_OMFANG", "JORDRENTE_OMFANG", "KLITFREDNING_KLITFREDNINGSAREA", "KLITFREDNING_OMFANG", "MAJORATSSKOV_MAJORATSSKOVSNUMM", "MAJORATSSKOV_OMFANG", "STRANDBESKYTTELSE_OMFANG", "STRANDBESKYTTELSE_STRANDBESKYT", "STORMFALDSNOTERING", "SAMLETFASTEJENDOMLOKALID", "SKELFORRETNINGSSAGSLOKALID", "STAMMERFRAJORDSTYKKELOKALID", "SUPPLERENDEMAALINGSAGLOKALID", "EJERLAVSKODE", "SOGNEKODE", "KOMMUNEKODE", "REGIONSKODE", "SENESTESAGLOKALID", "GEOMETRI", "GMLID") AS 
  SELECT mua.OBJECTID,
       mua.FORRETNINGSHAENDELSE,
       mua.FORRETNINGSPROCES,
       mua.ID_NAMESPACE,
       mua.ID_LOKALID,
       mua.PAATAENKTHANDLING,
       mua.REGISTRERINGFRA,
       mua.VIRKNINGFRA,
       mua.VIRKNINGSAKTOER,
       mua.AREALBEREGNINGSMETODE,
       mua.AREALBETEGNELSE,
       mua.AREALTYPE,
       mua.BRUGSRETSAREAL,
       mua.DELNUMMER,
       mua.FAELLESLOD,
       mua.MATRIKELNUMMER,
       mua.REGISTRERETAREAL,
       mua.VANDAREALINKLUDERING,
       mua.VEJAREAL,
       mua.VEJAREALBEREGNINGSSTATUS,
       mua.FREDSKOV_FREDSKOVSAREAL,
       mua.FREDSKOV_OMFANG,
       mua.JORDRENTE_OMFANG,
       mua.KLITFREDNING_KLITFREDNINGSAREA,
       mua.KLITFREDNING_OMFANG,
       mua.MAJORATSSKOV_MAJORATSSKOVSNUMM,
       mua.MAJORATSSKOV_OMFANG,
       mua.STRANDBESKYTTELSE_OMFANG,
       mua.STRANDBESKYTTELSE_STRANDBESKYT,
       CASE
          WHEN exists (select 1 from MATRIKEL_L1_PREPROD.JORDSTYKKE_STORMFALD  ss
                       where ss.JORDSTYKKEOBJECTID=mua.OBJECTID) then
                        'true'
          ELSE 'false'
       END
          AS STORMFALDSNOTERING,
       mua.SAMLETFASTEJENDOMLOKALID,
       mua.SKELFORRETNINGSSAGSLOKALID,
       mua.STAMMERFRAJORDSTYKKELOKALID,
       mua.SUPPLERENDEMAALINGSAGLOKALID,
       mua.EJERLAVLOKALID AS EJERLAVSKODE,
       mua.SOGNLOKALID AS SOGNEKODE,
       mua.KOMMUNELOKALID AS KOMMUNEKODE,
       mua.REGIONLOKALID AS REGIONSKODE,
       mua.SENESTESAGLOKALID,
       mulod.GEOMETRI,
       mua.GMLID
  FROM MATRIKEL_L1_PREPROD.JORDSTYKKE mua,
       MATRIKEL_L1_PREPROD.LODFLADE mulod
 WHERE     mua.status = 'Foreløbig'
       and MULOD.JORDSTYKKELOKALID = mua.id_lokalid
       and mulod.status  in ( 'Foreløbig','Gældende')
       AND mulod.REGISTRERINGTIL IS NULL
       AND mulod.VIRKNINGFRA <= LOCALTIMESTAMP
       AND (mulod.VIRKNINGTIL IS NULL
                               OR LOCALTIMESTAMP < mulod.VIRKNINGTIL)
       and mulod.registreringfra = (SELECT MAX (bb.registreringfra)
                                     FROM MATRIKEL_L1_PREPROD.LODFLADE bb
                                    WHERE     bb.registreringtil IS NULL
                                          AND bb.status in ( 'Foreløbig','Gældende')
                                          AND bb.id_lokalid = mulod.id_lokalid)                                 
       AND mua.REGISTRERINGTIL IS NULL
       AND mua.VIRKNINGFRA <= LOCALTIMESTAMP
       AND (mua.VIRKNINGTIL IS NULL OR LOCALTIMESTAMP < mua.VIRKNINGTIL);

-- JordstykkeTemaflade
-- Selektering af JordstykkeTemaflade som har status Gældende, hvor tematype er fredskov, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW FREDSKOVFLADE_G
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.TEMAFLADEID,
		mua.TEMATYPE,
		mua.GEOMETRI,
		mua.JORDSTYKKELOKALID,
		mua.SENESTESAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.JORDSTYKKETEMAFLADE mua
where mua.status = 'Gældende' and mua.Tematype = 'fredskov' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Selektering af JordstykkeTemaflade som har status Foreløbig, hvor tematype er fredskov, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW FREDSKOVFLADE_F
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.PAATAENKTHANDLING,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.TEMAFLADEID,
		mua.TEMATYPE,
		mua.GEOMETRI,
		mua.JORDSTYKKELOKALID,
		mua.SENESTESAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.JORDSTYKKETEMAFLADE mua
where mua.status = 'Foreløbig' and mua.Tematype = 'fredskov' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Selektering af JordstykkeTemaflade som har status Gældende, hvor tematype er klitfredning, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW KLITFREDNINGFLADE_G
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.TEMAFLADEID,
		mua.TEMATYPE,
		mua.GEOMETRI,
		mua.JORDSTYKKELOKALID,
		mua.SENESTESAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.JORDSTYKKETEMAFLADE mua
where mua.status = 'Gældende' and mua.Tematype = 'klitfredning' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Selektering af JordstykkeTemaflade som har status Foreløbig, hvor tematype er klitfredning, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW KLITFREDNINGFLADE_F
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.PAATAENKTHANDLING,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.TEMAFLADEID,
		mua.TEMATYPE,
		mua.GEOMETRI,
		mua.JORDSTYKKELOKALID,
		mua.SENESTESAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.JORDSTYKKETEMAFLADE mua
where mua.status = 'Foreløbig' and mua.Tematype = 'klitfredning' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Selektering af JordstykkeTemaflade som har status Gældende, hvor tematype er strandbeskyttelse, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW STRANDBESKYTTELSEFLADE_G
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.TEMAFLADEID,
		mua.TEMATYPE,
		mua.GEOMETRI,
		mua.JORDSTYKKELOKALID,
		mua.SENESTESAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.JORDSTYKKETEMAFLADE mua
where mua.status = 'Gældende' and mua.Tematype = 'strandbeskyttelse' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Selektering af JordstykkeTemaflade som har status Foreløbig, hvor tematype er strandbeskyttelse, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW STRANDBESKYTTELSEFLADE_F
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.PAATAENKTHANDLING,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.TEMAFLADEID,
		mua.TEMATYPE,
		mua.GEOMETRI,
		mua.JORDSTYKKELOKALID,
		mua.SENESTESAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.JORDSTYKKETEMAFLADE mua
where mua.status = 'Foreløbig' and mua.Tematype = 'strandbeskyttelse' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);



-- Lodflade
-- Selektering af Lodflade som har status Gældende, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW LODFLADE_G
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.GEOMETRI,
		mua.JORDSTYKKELOKALID,
		mua.SENESTESAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.LODFLADE mua
where mua.status = 'Gældende' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Selektering af Lodflade som har status Foreløbig, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW LODFLADE_F
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.PAATAENKTHANDLING,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.GEOMETRI,
		mua.JORDSTYKKELOKALID,
		mua.SENESTESAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.LODFLADE mua
where mua.status = 'Foreløbig' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);


-- Temalinje
-- Selektering af Temalinje som har status Gældende, er af tematypen fredskov, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW FREDSKOVLINJE_G
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.GEOMETRI,
		mua.SENESTESAGLOKALID,
		mua.FORLOEB,
		mua.ORIGINALTEMAFLADEID,
		mua.TEMATYPE,
		mua.GMLID
from MATRIKEL_L1_PREPROD.TEMALINJE mua
where mua.status = 'Gældende' and mua.Tematype = 'fredskov' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Selektering af Temalinje som har status Foreløbig, er af tematypen fredskov, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW FREDSKOVLINJE_F
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.PAATAENKTHANDLING,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.GEOMETRI,
		mua.SENESTESAGLOKALID,
		mua.FORLOEB,
		mua.ORIGINALTEMAFLADEID,
		mua.TEMATYPE,
		mua.GMLID
from MATRIKEL_L1_PREPROD.TEMALINJE mua
where mua.status = 'Foreløbig' and mua.Tematype = 'fredskov' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Selektering af Temalinje som har status Gældende, er af tematypen klitfredning, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW KLITFREDNINGLINJE_G
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.GEOMETRI,
		mua.SENESTESAGLOKALID,
		mua.FORLOEB,
		mua.ORIGINALTEMAFLADEID,
		mua.TEMATYPE,
		mua.GMLID
from MATRIKEL_L1_PREPROD.TEMALINJE mua
where mua.status = 'Gældende' and mua.Tematype = 'klitfredning' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Selektering af Temalinje som har status Foreløbig, er af tematypen klitfredning, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW KLITFREDNINGLINJE_F
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.PAATAENKTHANDLING,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.GEOMETRI,
		mua.SENESTESAGLOKALID,
		mua.FORLOEB,
		mua.ORIGINALTEMAFLADEID,
		mua.TEMATYPE,
		mua.GMLID
from MATRIKEL_L1_PREPROD.TEMALINJE mua
where mua.status = 'Foreløbig' and mua.Tematype = 'klitfredning' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Selektering af Temalinje som har status Gældende, er af tematypen strandbeskyttelse, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW STRANDBESKYTTELSELINJE_G
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.GEOMETRI,
		mua.SENESTESAGLOKALID,
		mua.FORLOEB,
		mua.ORIGINALTEMAFLADEID,
		mua.TEMATYPE,
		mua.GMLID
from MATRIKEL_L1_PREPROD.TEMALINJE mua
where mua.status = 'Gældende' and mua.Tematype = 'strandbeskyttelse' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Selektering af Temalinje som har status Foreløbig, er af tematypen strandbeskyttelse, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW STRANDBESKYTTELSELINJE_F
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.PAATAENKTHANDLING,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.GEOMETRI,
		mua.SENESTESAGLOKALID,
		mua.FORLOEB,
		mua.ORIGINALTEMAFLADEID,
		mua.TEMATYPE,
		mua.GMLID
from MATRIKEL_L1_PREPROD.TEMALINJE mua
where mua.status = 'Foreløbig' and mua.Tematype = 'strandbeskyttelse' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);



-- Matrikelskel
-- Selektering af Matrikelskel som har status Gældende, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW MATRIKELSKEL_G
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.ADMINISTRATIVGRAENSEKODE,
		mua.OPRINDELSEJOURNALNUMMER,
		mua.PRODUKTIONSMETODE,
		mua.SKELTYPE,
		mua.TRANSFORMATIONSID,
		mua.GEOMETRI,
		mua.SENESTESAGLOKALID,
		mua.SKELFORRETNINGSSAGSLOKALID,
		mua.OPRINDELSESSAGSLOKALID,
		mua.HOEJREJORDSTYKKELOKALID,
		mua.VENSTREJORDSTYKKELOKALID,
		mua.SKELPUNKT_1LOKALID,
		mua.SKELPUNKT_2LOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.MATRIKELSKEL mua
where mua.status = 'Gældende' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Selektering af Matrikelskel som har status Foreløbig, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW MATRIKELSKEL_F
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.PAATAENKTHANDLING,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.ADMINISTRATIVGRAENSEKODE,
		mua.OPRINDELSEJOURNALNUMMER,
		mua.PRODUKTIONSMETODE,
		mua.SKELTYPE,
		mua.TRANSFORMATIONSID,
		mua.GEOMETRI,
		mua.SENESTESAGLOKALID,
		mua.SKELFORRETNINGSSAGSLOKALID,
		mua.OPRINDELSESSAGSLOKALID,
		mua.HOEJREJORDSTYKKELOKALID,
		mua.VENSTREJORDSTYKKELOKALID,
		mua.SKELPUNKT_1LOKALID,
		mua.SKELPUNKT_2LOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.MATRIKELSKEL mua
where mua.status = 'Foreløbig' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- NULLLinje
-- Selektering af NULLLinje som har status Gældende, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW NULLINJE_G
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.GEOMETRI,
		mua.PAATAENKTHANDLING,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.SENESTESAGLOKALID,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.GMLID
from MATRIKEL_L1_PREPROD.NULLINJE mua
where mua.status = 'Gældende' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Selektering af NULLLinje som har status Foreløbig, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW NULLINJE_F
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.GEOMETRI,
		mua.PAATAENKTHANDLING,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.SENESTESAGLOKALID,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.GMLID
from MATRIKEL_L1_PREPROD.NULLINJE mua
where mua.status = 'Foreløbig' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Optagetvej
-- Selektering af Optagetvej som har status Gældende, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW OPTAGETVEJ_G
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.PRODUKTIONSMETODE,
		mua.VEJBREDDE,
		mua.VEJTYPE,
		mua.TRANSFORMATIONSID,
		mua.GEOMETRI,
		mua.SENESTESAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.OPTAGETVEJ mua
where mua.status = 'Gældende' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Selektering af Optagetvej som har status Foreløbig, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW OPTAGETVEJ_F
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.PAATAENKTHANDLING,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.PRODUKTIONSMETODE,
		mua.VEJBREDDE,
		mua.VEJTYPE,
		mua.TRANSFORMATIONSID,
		mua.GEOMETRI,
		mua.SENESTESAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.OPTAGETVEJ mua
where mua.status = 'Foreløbig' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);


-- SamletFastEjendom
-- Selektering af SamletFastEjendom som har status Gældende, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW SAMLETFASTEJENDOM_G
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.BFENUMMER,
		mua.ARBEJDERBOLIG,
		mua.ERFAELLESLOD,
		mua.HOVEDEJENDOMOPDELTIEJERLEJLIGH,
		mua.LANDBRUGSNOTERING,
		mua.UDSKILTVEJ,
		mua.GEOMETRI,
		mua.SENESTESAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.SAMLETFASTEJENDOM mua
where mua.status = 'Gældende' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Selektering af SamletFastEjendom som har status Foreløbig, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW SAMLETFASTEJENDOM_F
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.PAATAENKTHANDLING,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.BFENUMMER,
		mua.ARBEJDERBOLIG,
		mua.ERFAELLESLOD,
		mua.HOVEDEJENDOMOPDELTIEJERLEJLIGH,
		mua.LANDBRUGSNOTERING,
		mua.UDSKILTVEJ,
		mua.GEOMETRI,
		mua.SENESTESAGLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.SAMLETFASTEJENDOM mua
where mua.status = 'Foreløbig' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);


-- Skelpunkt
-- Selektering af Skelpunkt som har status Gældende, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW SKELPUNKT_G
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.INDLAEGNINGSTYPE,
		mua.OPRINDELSEJOURNALNUMMER,
		mua.PRODUKTIONSMETODE,
		mua.PUNKTKLASSE,
		mua.TRANSFORMATIONSID,
		mua.GEOMETRI,
		mua.SENESTESAGLOKALID,
		mua.OPRINDELSESSAGSLOKALID,
		mua.SUPPLERENDEMAALINGSAGSLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.SKELPUNKT mua
where mua.status = 'Gældende' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);

-- Selektering af Skelpunkt som har status Foreløbig, ikke er afregistreret og som er i virkning
create OR REPLACE VIEW SKELPUNKT_F
AS
select mua.OBJECTID,
		mua.FORRETNINGSHAENDELSE,
		mua.FORRETNINGSPROCES,
		mua.ID_NAMESPACE,
		mua.ID_LOKALID,
		mua.PAATAENKTHANDLING,
		mua.REGISTRERINGFRA,
		mua.VIRKNINGFRA,
		mua.VIRKNINGSAKTOER,
		mua.INDLAEGNINGSTYPE,
		mua.OPRINDELSEJOURNALNUMMER,
		mua.PRODUKTIONSMETODE,
		mua.PUNKTKLASSE,
		mua.TRANSFORMATIONSID,
		mua.GEOMETRI,
		mua.SENESTESAGLOKALID,
		mua.OPRINDELSESSAGSLOKALID,
		mua.SUPPLERENDEMAALINGSAGSLOKALID,
		mua.GMLID
from MATRIKEL_L1_PREPROD.SKELPUNKT mua
where mua.status = 'Foreløbig' and mua.REGISTRERINGTIL is NULL and mua.VIRKNINGFRA <= LOCALTIMESTAMP and (VIRKNINGTIL is NULL or LOCALTIMESTAMP < VIRKNINGTIL);