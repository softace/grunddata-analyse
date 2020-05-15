DROP VIEW MATRIKEL_INS_A.INS_AREAMANAGEMENTZONE;

/* Formatted on 22-08-2018 16:22:23 (QP5 v5.269.14213.34769) */
CREATE OR REPLACE FORCE VIEW MATRIKEL_INS_A.INS_AREAMANAGEMENTZONE
(GMLID, INSPIREID_LOKALID, INSPIREID_NAMESPACE, THEMATICID_IDENTIFIER, THEMATICID_IDENTIFIERSCHEME,
 NAME_SPELLING_TEXT, NAME_SPELLING_SCRIPT, GEOMETRY, ZONETYPE, SPECIALISEDZONETYPE,
 DESIGNATIONPERIOD_BEGIN, DESIGNATIONPERIOD_END, ENVIRONMENTALDOMAIN, COMPETENTAUTH_INDIVIDUALNAME, COMPETENTAUTH_ORGANISATIONNAME,
 COMPETENTAUTH_POSITIONNAME, COMPETENTAUTH_CONTACT, COMPETENTAUTH_ROLE, BEGINLIFESPANVERSION, ENDLIFESPANVERSION,
 PLAN, LEGISLATIONNAME, LEGISLATIONSHORTNAME, DATEENTEREDINTOFORCE, DATETYPE,
 LINK, SPECIFICREFERENCE, LEGISLATIONLEVEL)
BEQUEATH DEFINER
AS

(SELECT 'dk.am.forest_coastal.' || jt.ID_LOKALID AS GMLID,
        jt.ID_LOKALID AS inspireid_lokalid,
        'https://geo.data.gov.dk/dataset/9d7161b3-805b-2791-047f-834319916410'
           AS inspireid_namespace,
        jt.TEMAFLADEID AS thematicid_identifier,
        'TemafladeID' AS thematicid_identifierScheme,
        'other:unpopulated' AS name_spelling_text,
        'other:unpopulated' AS name_spelling_script,
        jt.GEOMETRI AS GEOMETRY,
        CASE jt.TEMATYPE
           WHEN 'fredskov'
           THEN
              'http://inspire.ec.europa.eu/codelist/ZoneTypeCode/forestManagementArea'
           WHEN 'strandbeskyttelse'
           THEN
              'http://inspire.ec.europa.eu/codelist/ZoneTypeCode/coastalZoneManagementArea'
           WHEN 'klitfredning'
           THEN
              'http://inspire.ec.europa.eu/codelist/ZoneTypeCode/coastalZoneManagementArea'
        END
           AS ZONETYPE,
        'other:unpopulated' AS specialisedZoneType,
        jt.VIRKNINGFRA AS designationPeriod_begin,
        'other:unpopulated' AS designationPeriod_end,
        'http://inspire.ec.europa.eu/codelist/EnvironmentalDomain/naturalResources'
           AS environmentalDomain,
        'missing' AS competentAuth_individualName,
        'The Danish Geodata Agency' AS competentAuth_organisationName,
        'missing' AS competentAuth_positionName,
        'other:unpopulated' AS competentAuth_contact,
        'http://inspire.ec.europa.eu/codelist/RelatedPartyRoleValue/authority'
           AS competentAuth_role,
        jt.registreringfra AS beginlifespanversion,
        'other:unpopulated' AS endLifespanVersion,
        'other:unpopulated' AS plan,
        CASE jt.tematype
           WHEN 'fredskov'
           THEN
              'Bekendtgørelse af lov om skove'
           WHEN 'strandbeskyttelse'
           THEN
              'Bekendtgørelse af lov om naturbeskyttelse'
           WHEN 'klitfredning'
           THEN
              'Bekendtgørelse af lov om naturbeskyttelse'
        END
           AS legislationName,
        CASE jt.tematype
           WHEN 'fredskov' THEN 'Skovloven'
           WHEN 'strandbeskyttelse' THEN 'Naturbeskyttelsesloven'
           WHEN 'klitfredning' THEN 'Naturbeskyttelsesloven'
        END
           AS legislationShortname,
        CASE jt.tematype
           WHEN 'fredskov' THEN '2017-01-26'
           WHEN 'strandbeskyttelse' THEN '2017-06-27'
           WHEN 'klitfredning' THEN '2017-06-27'
        END
           AS dateEnteredIntoForce,
        'publication' AS dateType,
        CASE jt.tematype
           WHEN 'fredskov'
           THEN
              'http://www.retsinformation.dk/eli/lta/2017/122'
           WHEN 'strandbeskyttelse'
           THEN
              'http://www.retsinformation.dk/eli/lta/2017/934'
           WHEN 'klitfredning'
           THEN
              'http://www.retsinformation.dk/eli/lta/2017/934'
        END
           AS link,
        'other:unpopulated' AS specificReference,
        'http://inspire.ec.europa.eu/codelist/LegislationLevelValue/national'
           AS legislationLevel
   FROM MATRIKEL_A.JORDSTYKKETEMAFLADE jt
  WHERE     jt.status = 'Gældende'
        AND jt.REGISTRERINGTIL IS NULL
        AND jt.VIRKNINGFRA <= LOCALTIMESTAMP
        AND (jt.VIRKNINGTIL IS NULL OR LOCALTIMESTAMP < jt.VIRKNINGTIL));

COMMENT ON TABLE MATRIKEL_INS_A.INS_AREAMANAGEMENTZONE IS 'INSPIRE: View til brug for INSPIRE WMS/WFS/GML-download: mappes til am:AreaManagementRestrictionRegulationZone i http://inspire.ec.europa.eu/schemas/am/4.0/AreaManagementRestrictionRegulationZone.xsd - laers, sdfe, 20. juni 2018. Viewet indeholder temaflader mappet til INSPIRE AM';


GRANT SELECT ON MATRIKEL_INS_A.INS_AREAMANAGEMENTZONE TO EJF_READ;

GRANT SELECT ON MATRIKEL_INS_A.INS_AREAMANAGEMENTZONE TO GEOBANK_READ;

GRANT SELECT ON MATRIKEL_INS_A.INS_AREAMANAGEMENTZONE TO KF_READ;
