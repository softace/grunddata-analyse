DROP VIEW MATRIKEL_INS_A.INS_CADASTRALBOUNDARY;

/* Formatted on 06-08-2018 12:24:52 (QP5 v5.269.14213.34769) */
CREATE VIEW MATRIKEL_INS_A.INS_CADASTRALBOUNDARY 
(INSPIREID_LOCALID, INSPIREID_NAMESPACE, BEGINLIFESPANVERSION, ENDLIFESPANVERSION_NILREASON, ESTIMATEDACCURACY,
 ESTIMATEDACCURACY_UOM, VALIDFROM, VALIDTO_NILREASON, PARCEL_L_OWNS, HREF_L,
 PARCEL_R_OWNS, HREF_R, GMLID, GEOMETRI)
BEQUEATH DEFINER
AS

SELECT m.ID_LOKALID AS INSPIREID_LOCALID,
        'http://data.gov.dk/inspire-cp/CadastralBoundary'
           AS INSPIREID_NAMESPACE,
        m.REGISTRERINGFRA AS BEGINLIFESPANVERSION,
        'other:unpopulated' AS ENDLIFESPANVERSION_nilreason,
        CASE
           WHEN m.PRODUKTIONSMETODE =
                   'Indlagt med koordinaterne fra en skelmåling - MI'
           THEN
              '0,2'
           WHEN m.PRODUKTIONSMETODE =
                   'Indlagt vha. et måleblad, der er digitaliseret - MD'
           THEN
              '0,5'
           WHEN m.PRODUKTIONSMETODE =
                   'Indlagt vha. digitalisering af et rammekort i målforhold 1:500 til 1:2000 - RS'
           THEN
              '1'
           WHEN m.PRODUKTIONSMETODE =
                   'Indlagt vha. digitalisering af et rammekort i målforhold >1:2000 - RL'
           THEN
              '2'
           WHEN m.PRODUKTIONSMETODE =
                   'Indlagt vha. digitalisering af et økort - MK'
           THEN
              '4'
           WHEN m.PRODUKTIONSMETODE =
                   'Indlagt vha. digitalisering af et skelkort eller en konstruktion - SK'
           THEN
              'other:unpopulated'
           WHEN m.PRODUKTIONSMETODE = 'Ukendt - UK'
           THEN
              'other:unpopulated'
        END
           AS ESTIMATEDACCURACY,
        'm' AS ESTIMATEDACCURACY_UOM,
        m.VIRKNINGFRA AS VALIDFROM,
        'other:unpopulated' AS VALIDTO_nilreason,
        DECODE (m.VENSTREJORDSTYKKELOKALID, NULL, NULL, 'false')
           AS PARCEL_L_OWNS,
        CASE
           WHEN m.VENSTREJORDSTYKKELOKALID IS NOT NULL
           THEN
                 'http://data.gov.dk/inspire-cp/CadastralParcel'
              || '/'
              || m.VENSTREJORDSTYKKELOKALID
           ELSE
              NULL
        END
           AS HREF_L,
        DECODE (m.HOEJREJORDSTYKKELOKALID, NULL, NULL, 'false')
           AS PARCEL_R_OWNS,
        CASE
           WHEN m.HOEJREJORDSTYKKELOKALID IS NOT NULL
           THEN
                 'http://data.gov.dk/inspire-cp/CadastralParcel'
              || '/'
              || m.HOEJREJORDSTYKKELOKALID
           ELSE
              NULL
        END
           AS HREF_R,
        'dk.cp.boundary.' || m.ID_LOKALID AS GMLID,
        m.GEOMETRI AS GEOMETRI
        
        FROM MATRIKEL_A.MATRIKELSKEL m
        LEFT JOIN MATRIKEL_A.JORDSTYKKE HJS
           ON (    m.HOEJREJORDSTYKKELOKALID = HJS.ID_LOKALID
               AND SYS_EXTRACT_UTC (HJS.REGISTRERINGTIL) IS NULL
               AND HJS.status = 'Gældende'
               AND HJS.VIRKNINGFRA <= LOCALTIMESTAMP
               AND (HJS.VIRKNINGTIL IS NULL OR LOCALTIMESTAMP < HJS.VIRKNINGTIL))
        LEFT JOIN MATRIKEL_A.JORDSTYKKE VJS
           ON (    m.VENSTREJORDSTYKKELOKALID = VJS.ID_LOKALID
               AND SYS_EXTRACT_UTC (VJS.REGISTRERINGTIL) IS NULL
               AND VJS.status = 'Gældende'
               AND VJS.VIRKNINGFRA <= LOCALTIMESTAMP
               AND (VJS.VIRKNINGTIL IS NULL OR LOCALTIMESTAMP < VJS.VIRKNINGTIL))
  
  WHERE m.REGISTRERINGTIL IS NULL
   AND m.status = 'Gældende'
   AND m.VIRKNINGFRA <= LOCALTIMESTAMP
   AND (m.VIRKNINGTIL IS NULL OR LOCALTIMESTAMP < m.VIRKNINGTIL)
;

COMMENT ON TABLE MATRIKEL_INS_A.INS_CADASTRALBOUNDARY IS 'INSPIRE: View til brug for INSPIRE WFS/GML-download: mappes til cp:CadastralParcels i http://inspire.ec.europa.eu/schemas/cp/4.0/CadastralParcels.xsd - laers, sdfe, 28. februar 2018. Viewet indeholder matrikelskel';


GRANT SELECT ON MATRIKEL_INS_A.INS_CADASTRALBOUNDARY TO EJF_READ;

GRANT SELECT ON MATRIKEL_INS_A.INS_CADASTRALBOUNDARY TO GEOBANK_READ;

GRANT SELECT ON MATRIKEL_INS_A.INS_CADASTRALBOUNDARY TO KF_READ;
