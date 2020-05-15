--Al information om SFE'en, inklusivt dens jordstykker og ejerlav og sager og EJL og BPFG'er på den, og EJL'er på BPFG'erne, skal med.
--Sørg for at få sekundære forretningshændelser og al nødvendig data med.
SELECT * 
FROM SAMLETFASTEJENDOM sfe

LEFT JOIN JORDSTYKKE jst ON jst.SAMLETFASTEJENDOMLOKALID = sfe.ID_LOKALID [snippet_bitemp_full(jst)]
LEFT JOIN JORDSTYKKE_SEKUNDAERFORRETNING jstse ON jstse.JORDSTYKKEOBJECTID = jst.OBJECTID
LEFT JOIN JORDSTYKKE_STORMFALD jstsf ON jstsf.JORDSTYKKEOBJECTID = jst.OBJECTID
LEFT JOIN STORMFALD sf ON sf.OBJECTID = jstsf.STORMFALDOBJECTID
INNER JOIN EJERLAV ej ON jst.EJERLAVLOKALID = 
	(SELECT EJERLAVSKODE FROM 
		(SELECT EJERLAVSKODE, 1 AS FILTER FROM EJERLAV ejinner WHERE ejinner.EJERLAVSKODE = ej.EJERLAVSKODE AND STATUS = @Status [snippet_bitemp_full(ejinner)] 
		 UNION
         SELECT EJERLAVSKODE, 2 AS FILTER FROM EJERLAV ejinner WHERE ejinner.EJERLAVSKODE = ej.EJERLAVSKODE [snippet_bitemp_full(ejinner)]
         ORDER BY FILTER)
	WHERE ROWNUM = 1) 
LEFT JOIN CENTROIDE cen ON jst.ID_LOKALID = cen.JORDSTYKKELOKALID  [snippet_bitemp_full(cen)]

--Nogle gagne er der tale om et fælles lod, så SFE og jordstykke bindes sammen af en krydstabel fordi der er flere SFE'er på tilknyttet jordstykket
LEFT JOIN SAMLETFASTEJENDOM_JORDSTYKKE sfejst ON sfejst.SAMLETFASTEJENDOMOBJECTID = sfe.OBJECTID
LEFT JOIN JORDSTYKKE jst2 ON jst2.OBJECTID = sfejst.JORDSTYKKEOBJECTID [snippet_bitemp_full(jst2)]
LEFT JOIN JORDSTYKKE_SEKUNDAERFORRETNING jstse2 ON jstse2.JORDSTYKKEOBJECTID = jst2.OBJECTID
LEFT JOIN JORDSTYKKE_STORMFALD jstsf2 ON jstsf2.JORDSTYKKEOBJECTID = jst2.OBJECTID
LEFT JOIN STORMFALD sf2 ON sf2.OBJECTID = jstsf2.STORMFALDOBJECTID
INNER JOIN EJERLAV ej2 ON jst2.EJERLAVLOKALID = 
	(SELECT EJERLAVSKODE FROM 
		(SELECT EJERLAVSKODE, 1 AS FILTER FROM EJERLAV ejinner WHERE ejinner.EJERLAVSKODE = ej2.EJERLAVSKODE AND STATUS = @Status [snippet_bitemp_full(ejinner)] 
		 UNION
         SELECT EJERLAVSKODE, 2 AS FILTER FROM EJERLAV ejinner WHERE ejinner.EJERLAVSKODE = ej2.EJERLAVSKODE [snippet_bitemp_full(ejinner)]
         ORDER BY FILTER)
	WHERE ROWNUM = 1) 
LEFT JOIN CENTROIDE cen2 ON jst2.ID_LOKALID = cen2.JORDSTYKKELOKALID  [snippet_bitemp_full(cen2)]

-- Fælles joins
LEFT JOIN SAMLETFASTEJENDOM_SEKUNDAERFOR sfese ON sfese.SAMLETFASTEJENDOMOBJECTID = sfe.OBJECTID
LEFT JOIN EJERLEJLIGHED ejl ON ejl.SAMLETFASTEJENDOMLOKALID = sfe.ID_LOKALID  [snippet_bitemp_full(ejl)] -- fordi en SFE kan indeholde ejerlejligheder 
LEFT JOIN BYGNINGPAAFREMMEDGRUNDFLADE bpfgf ON bpfgf.SAMLETFASTEJENDOMLOKALID = sfe.ID_LOKALID  [snippet_bitemp_full(bpfgf)]
LEFT JOIN EJERLEJLIGHED ejlbf ON ejlbf.B_BYGNINGPAAFREMMEDGRUNDFLADEL = bpfgf.ID_LOKALID [snippet_bitemp_full(ejlbf)] -- fordi vi har brug for evt. lejligheder i en BPFGFlade 
LEFT JOIN BYGNINGPAAFREMMEDGRUNDPUNKT bpfgp ON bpfgp.SAMLETFASTEJENDOMLOKALID = sfe.ID_LOKALID [snippet_bitemp_full(bpfgp)]
LEFT JOIN EJERLEJLIGHED ejlbp ON ejlbp.B_BYGNINGPAAFREMMEDGRUNDPUNKTL = bpfgp.ID_LOKALID [snippet_bitemp_full(ejlbp)] -- fordi vi har brug for evt. lejligheder i en BPFGFlade 

WHERE --Sørg for at en gyldig kombination af inputs er givet 
(
(@SagsId IS NOT NULL
AND @SFEBFEnr IS NULL AND @Ejerlavskode IS NULL AND @Matrikelnr IS NULL AND @Point IS NULL AND @JordstykkeId IS NULL) -- Matcher tilfældet hvor @SagsId står alene (samt kombineret med tidsparametre og statusparameter)
OR
(@SFEBFEnr IS NOT NULL
AND @Ejerlavskode IS NULL AND @Matrikelnr IS NULL AND @Point IS NULL AND @JordstykkeId IS NULL) --Tillader @SagsId som optionel ekstra parameter
OR
(@Ejerlavskode IS NOT NULL AND @Matrikelnr IS NOT NULL
AND @SFEBFEnr IS NULL AND @Point IS NULL AND @JordstykkeId IS NULL) --Tillader @SagsId som optionel ekstra parameter
OR
(@Point IS NOT NULL AND
@SFEBFEnr IS NULL AND @Ejerlavskode IS NULL AND @Matrikelnr IS NULL AND @JordstykkeId IS NULL) --Tillader @SagsId som optionel ekstra parameter
OR
(@JordstykkeId IS NOT NULL AND
@SFEBFEnr IS NULL AND @Ejerlavskode IS NULL AND @Matrikelnr IS NULL AND @Point IS NULL) --Tillader @SagsId som optionel ekstra parameter
)

--Filtrer på inputs
AND (@SFEBFEnr IS NULL OR sfe.BFENUMMER = @SFEBFEnr )
AND ((@Ejerlavskode IS NULL OR jst.EJERLAVLOKALID = @Ejerlavskode OR jst2.EJERLAVLOKALID = @Ejerlavskode) AND (@Matrikelnr IS NULL OR jst.MATRIKELNUMMER = @Matrikelnr OR jst2.MATRIKELNUMMER = @Matrikelnr) )
AND (@Point IS NULL OR @Point WITHIN sfe.GEOMETRI)
AND (@SagsId IS NULL OR sfe.SENESTESAGLOKALID = @SagsId)
AND (@JordstykkeId IS NULL OR jst.ID_LOKALID = @JordstykkeId OR jst2.ID_LOKALID = @JordstykkeId)

--Bitemporalitet ...
[snippet_bitemp_full(sfe)]

--Statussøgning leder efter noget der er historisk et sted i det SFE'en består af.
--Ting der ligger på SFE'en (BPFG'er, EJL'er) får ikke tjekket deres status
AND (@Status IS NULL OR sfe.STATUS = @Status)

OR (@Status IS NULL OR jst.STATUS IS NULL OR jst.STATUS = @Status)
OR (@Status IS NULL OR cen.STATUS IS NULL OR cen.STATUS = @Status)

OR (@Status IS NULL OR jst2.STATUS IS NULL OR jst2.STATUS = @Status)
OR (@Status IS NULL OR cen2.STATUS IS NULL OR cen2.STATUS = @Status)