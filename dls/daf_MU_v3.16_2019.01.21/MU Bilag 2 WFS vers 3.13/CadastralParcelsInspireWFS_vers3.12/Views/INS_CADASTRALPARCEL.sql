DROP VIEW MATRIKEL_INS_A.INS_CADASTRALPARCEL;

/* Formatted on 06-08-2018 12:38:24 (QP5 v5.269.14213.34769) */
CREATE OR REPLACE FORCE VIEW MATRIKEL_INS_A.INS_CADASTRALPARCEL
(AREAVALUE, BEGINLIFESPANVERSION, ENDLIFESPANVERSION_NILREASON, GEOMETRI, INSPIREID_NAMESPACE,
 INSPIREID_LOCALID, LABEL, NATIONALCADASTRALREFERENCE, REFERENCEPOINT, VALIDFROM,
 VALIDTO_NILREASON, BASICPROPERTYUNIT, ADMINISTRATIVEUNIT, ZONING, REFPOINT_GML_ID,
 GMLID)
BEQUEATH DEFINER
AS

(SELECT j.REGISTRERETAREAL AS AREAVALUE,
        j.REGISTRERINGFRA AS BEGINLIFESPANVERSION,
        'other:unpopulated' AS ENDLIFESPANVERSION_NILREASON,
        l.GEOMETRI AS GEOMETRI,
        'http://data.gov.dk/inspire-cp/CadastralParcel'
           AS INSPIREID_NAMESPACE,
        j.ID_LOKALID AS INSPIREID_LOCALID,
        j.MATRIKELNUMMER AS LABEL,
        j.EJERLAVLOKALID || ',' || j.MATRIKELNUMMER
           AS NATIONALCADASTRALREFERENCE,
           ROUND (SDO_GEOM.SDO_MIN_MBR_ORDINATE (c.GEOMETRI, 1))
        || ' '
        || ROUND (SDO_GEOM.SDO_MIN_MBR_ORDINATE (c.GEOMETRI, 2))
           AS REFERENCEPOINT,
        j.VIRKNINGFRA AS VALIDFROM,
        'other:unpopulated' AS VALIDTO_NILREASON,
           'http://data.gov.dk/inspire-cp/BasicPropertyUnit'
        || '/'
        || j.SAMLETFASTEJENDOMLOKALID
           AS BASICPROPERTYUNIT,
        'http://data.gov.dk/inspire-au' || '/' || j.KOMMUNELOKALID
           AS ADMINISTRATIVEUNIT,
           'http://data.gov.dk/inspire-cp/CadastralZoning'
        || '/'
        || j.EJERLAVLOKALID
           AS ZONING,
        'dk.cp.' || 'cen.' || c.ID_LOKALID AS REFPOINT_GML_ID,
        'dk.cp.' || j.ID_LOKALID AS GMLID
   
   FROM MATRIKEL_A.JORDSTYKKE j
        
        JOIN MATRIKEL_A.CENTROIDE c
           ON (    j.ID_LOKALID = c.JORDSTYKKELOKALID
               AND c.REGISTRERINGTIL IS NULL
               AND c.status = 'G�ldende'
               AND c.VIRKNINGFRA <= LOCALTIMESTAMP
               AND (c.VIRKNINGTIL IS NULL OR LOCALTIMESTAMP < c.VIRKNINGTIL))
        
        JOIN MATRIKEL_A.LODFLADE l
           ON (    j.ID_LOKALID = l.JORDSTYKKELOKALID
               AND l.REGISTRERINGTIL IS NULL
               AND l.status = 'G�ldende'
               AND l.VIRKNINGFRA <= LOCALTIMESTAMP
               AND (l.VIRKNINGTIL IS NULL OR LOCALTIMESTAMP < l.VIRKNINGTIL))
  
  WHERE j.REGISTRERINGTIL IS NULL
  AND j.status = 'G�ldende'
  AND j.VIRKNINGFRA <= LOCALTIMESTAMP
  AND (j.VIRKNINGTIL IS NULL OR LOCALTIMESTAMP < j.VIRKNINGTIL)
);
COMMENT ON TABLE MATRIKEL_INS_A.INS_CADASTRALPARCEL IS 'INSPIRE: View til brug for INSPIRE WFS/GML-download: mappes til cp:CadastralParcels i http://inspire.ec.europa.eu/schemas/cp/4.0/CadastralParcels.xsd - laers, sdfe, 28. februar 2018. Viewet indeholder jordstykker';

GRANT SELECT ON MATRIKEL_INS_A.INS_CADASTRALPARCEL TO EJF_READ;

GRANT SELECT ON MATRIKEL_INS_A.INS_CADASTRALPARCEL TO GEOBANK_READ;

GRANT SELECT ON MATRIKEL_INS_A.INS_CADASTRALPARCEL TO KF_READ;
