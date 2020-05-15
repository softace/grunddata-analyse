DROP VIEW MATRIKEL_INS_A.INS_CADASTRALZONING;

/* Formatted on 06-08-2018 12:41:47 (QP5 v5.269.14213.34769) */
CREATE OR REPLACE FORCE VIEW MATRIKEL_INS_A.INS_CADASTRALZONING
(INSPIREID_LOCALID, INSPIREID_NAMESPACE, BEGINLIFESPANVERSION, ENDLIFESPANVERSION_NILREASON, CADASTALZONINGREFERENCE,
 LABEL, SPELLINGOFNAME_NILREASON, ESTIMATEDACCURACY_NILREASON, ESTACCURACY_UOM_NILREASON, ORIGINALMAPSCALEDENOMINATOR,
 LEVEL_HREF, LEVELNAME, NAMESPACE_LOCALID, REFERENCEPOINT, VALIDFROM,
 VALIDTO_NILREASON, GMLID, REFPOINT_GML_ID, GEOMETRI, UPPERLEVELUNIT_NILREASON)
BEQUEATH DEFINER
AS

(SELECT e.ID_LOKALID AS INSPIREID_LOCALID,
        'http://data.gov.dk/inspire-cp/CadastralZoning'
           AS INSPIREID_NAMESPACE,
        e.REGISTRERINGFRA AS BEGINLIFESPANVERSION,
        'other:unpopulated' AS ENDLIFESPANVERSION_NILREASON,
        e.EJERLAVSKODE AS CADASTALZONINGREFERENCE,
        e.EJERLAVSNAVN AS LABEL,
        'other:unpopulated' AS SPELLINGOFNAME_NILREASON,
        'other:unpopulated' AS ESTIMATEDACCURACY_NILREASON,
        'other:unpopulated' AS ESTACCURACY_UOM_NILREASON,
        '4000' AS originalMapScaleDenominator,
        'http://inspire.ec.europa.eu/codelist/CadastralZoningLevelValue/1stOrder'
           AS LEVEL_HREF,
        'Ejerlav' AS LEVELNAME,
           'http://data.gov.dk/inspire-cp/CadastralZoning'
        || '/'
        || e.ID_LOKALID
           AS NAMESPACE_LOCALID,
           ROUND (
              SDO_GEOM.SDO_MIN_MBR_ORDINATE (
                 SDO_GEOM.SDO_CENTROID (e.GEOMETRI, 0.005),
                 1))
        || ' '
        || ROUND (
              SDO_GEOM.SDO_MIN_MBR_ORDINATE (
                 SDO_GEOM.SDO_CENTROID (e.GEOMETRI, 0.005),
                 2))
           AS REFERENCEPOINT,
        e.VIRKNINGFRA AS VALIDFROM,
        'other:unpopulated' AS validto_nilreason,
        'dk.cp.zone' || '.' || e.ID_LOKALID || '.geom' AS GMLID,
        'dk.cp.cen' || '.' || e.ID_LOKALID AS REFPOINT_GML_ID,
        GEOMETRI AS GEOMETRI,
        'other:unpopulated' AS upperLevelUnit_NILREASON

   FROM MATRIKEL_A.EJERLAV e 
   WHERE e.status = 'Gældende' 
   AND e.REGISTRERINGTIL IS NULL
   AND e.VIRKNINGFRA <= LOCALTIMESTAMP
   AND (e.VIRKNINGTIL IS NULL OR LOCALTIMESTAMP < e.VIRKNINGTIL)

);

COMMENT ON TABLE MATRIKEL_INS_A.INS_CADASTRALZONING IS 'INSPIRE: View til brug for INSPIRE WFS/GML-download: mappes til cp:CadastralParcels i http://inspire.ec.europa.eu/schemas/cp/4.0/CadastralParcels.xsd - laers, sdfe, 28. februar 2018. Viewet indeholder ejerlav';


GRANT SELECT ON MATRIKEL_INS_A.INS_CADASTRALZONING TO EJF_READ;

GRANT SELECT ON MATRIKEL_INS_A.INS_CADASTRALZONING TO GEOBANK_READ;

GRANT SELECT ON MATRIKEL_INS_A.INS_CADASTRALZONING TO KF_READ;
