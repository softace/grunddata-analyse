--Disse SQL queries er taget direkte fra SamletFastEjendom, BygningPaaFremmedGrund, og Ejerlejlighed. Herefter er deres afgrænsning blevet ændret så de passer med logikken 

------------------------
--SQL SamletFastEjendom:
------------------------
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
LEFT JOIN EJERLEJLIGHED ejl ON ejl.SAMLETFASTEJENDOMLOKALID = sfe.ID_LOKALID [snippet_bitemp_full(ejl)]  -- fordi en SFE kan indeholde ejerlejligheder 
LEFT JOIN BYGNINGPAAFREMMEDGRUNDFLADE bpfgf ON bpfgf.SAMLETFASTEJENDOMLOKALID = sfe.ID_LOKALID [snippet_bitemp_full(bpfgf)] 
LEFT JOIN EJERLEJLIGHED ejlbf ON ejlbf.B_BYGNINGPAAFREMMEDGRUNDFLADEL = bpfgf.ID_LOKALID [snippet_bitemp_full(ejlbf)] -- fordi vi har brug for evt. lejligheder i en BPFGFlade 
LEFT JOIN BYGNINGPAAFREMMEDGRUNDPUNKT bpfgp ON bpfgp.SAMLETFASTEJENDOMLOKALID = sfe.ID_LOKALID [snippet_bitemp_full(bpfgp)]
LEFT JOIN EJERLEJLIGHED ejlbp ON ejlbp.B_BYGNINGPAAFREMMEDGRUNDPUNKTL = bpfgp.ID_LOKALID [snippet_bitemp_full(ejlbp)] -- fordi vi har brug for evt. lejligheder i en BPFGFlade 

WHERE (@BFEnr IS NOT NULL AND @SagsId IS NOT NULL)

AND (@BFEnr IS NULL OR sfe.BFENUMMER IN @BFEnr)
AND (@SagsId IS NULL OR sfe.SENESTESAGLOKALID = @SagsId )

--Bitemporalitet ...
[snippet_bitemp_full(sfe)]

--Statussøgning leder efter noget der er historisk et sted i det SFE'en består af.
--Ting der ligger på SFE'en (BPFG'er, EJL'er) får ikke tjekket deres status
AND (@Status IS NULL OR sfe.STATUS = @Status)

OR (@Status IS NULL OR jst.STATUS IS NULL OR jst.STATUS = @Status)
OR (@Status IS NULL OR cen.STATUS IS NULL OR cen.STATUS = @Status)

OR (@Status IS NULL OR jst2.STATUS IS NULL OR jst2.STATUS = @Status)
OR (@Status IS NULL OR cen2.STATUS IS NULL OR cen2.STATUS = @Status)

-------------------------------
--SQL Bygning på fremmed grund:
-------------------------------
SELECT * 
FROM 
(
SELECT bpfgflade.OBJECTID ,
bpfgflade.FORRETNINGSHAENDELSE ,
bpfgflade.FORRETNINGSOMRAADE ,
bpfgflade.FORRETNINGSPROCES ,
bpfgflade.ID_NAMESPACE ,
bpfgflade.ID_LOKALID ,
bpfgflade.PAATAENKTHANDLING ,
bpfgflade.REGISTRERINGFRA ,
bpfgflade.REGISTRERINGSAKTOER ,
bpfgflade.REGISTRERINGTIL ,
bpfgflade.STATUS ,
bpfgflade.VIRKNINGFRA ,
bpfgflade.VIRKNINGSAKTOER ,
bpfgflade.VIRKNINGTIL ,
bpfgflade.BFENUMMER ,
bpfgflade.OPDELTIEJERLEJLIGHEDER ,
bpfgflade.OPRINDELSE ,
bpfgflade.PAAHAVET ,
bpfgflade.RIDS ,
bpfgflade.GEOMETRI geometriflade,
null as geometripunkt,
bpfgflade.SENESTESAGLOKALID ,
bpfgflade.AFREGISTRERINGSSAGLOKALID ,
bpfgflade.SAMLETFASTEJENDOMLOKALID ,
bpfgflade.GMLID ,
bpfgfladese.SEKUNDAERFORRETNINGSHAENDELSE
FROM BYGNINGPAAFREMMEDGRUNDFLADE bpfgflade
LEFT JOIN BYGNINGPAAFREMMEDGRUNDFLADE_SE bpfgfladese ON bpfgfladese.BYGNINGPAAFREMMEDGRUNDFLADEOBJ = bpfgflade.OBJECTID
UNION ALL --Sørg for at der ikke bliver sammenlignet for at sortere duplikater væk. Kan ikke lade sig gøre pga. geometrierne.
SELECT bpfgpunkt.OBJECTID ,
bpfgpunkt.FORRETNINGSHAENDELSE ,
bpfgpunkt.FORRETNINGSOMRAADE ,
bpfgpunkt.FORRETNINGSPROCES ,
bpfgpunkt.ID_NAMESPACE ,
bpfgpunkt.ID_LOKALID ,
bpfgpunkt.PAATAENKTHANDLING ,
bpfgpunkt.REGISTRERINGFRA ,
bpfgpunkt.REGISTRERINGSAKTOER ,
bpfgpunkt.REGISTRERINGTIL ,
bpfgpunkt.STATUS ,
bpfgpunkt.VIRKNINGFRA ,
bpfgpunkt.VIRKNINGSAKTOER ,
bpfgpunkt.VIRKNINGTIL ,
bpfgpunkt.BFENUMMER ,
bpfgpunkt.OPDELTIEJERLEJLIGHEDER ,
bpfgpunkt.OPRINDELSE ,
bpfgpunkt.PAAHAVET ,
bpfgpunkt.RIDS ,
null as geometriflade,
bpfgpunkt.GEOMETRI geometripunkt,
bpfgpunkt.SENESTESAGLOKALID ,
bpfgpunkt.AFREGISTRERINGSSAGLOKALID ,
bpfgpunkt.SAMLETFASTEJENDOMLOKALID ,
bpfgpunkt.GMLID ,
bpfgpunktse.SEKUNDAERFORRETNINGSHAENDELSE
FROM BYGNINGPAAFREMMEDGRUNDPUNKT bpfgpunkt
LEFT JOIN BYGNINGPAAFREMMEDGRUNDPUNKT_SE bpfgpunktse ON bpfgpunktse.BYGNINGPAAFREMMEDGRUNDPUNKTOBJ = bpfgpunkt.OBJECTID
) bpfg
LEFT JOIN EJERLEJLIGHED ejl ON ejl.B_BYGNINGPAAFREMMEDGRUNDFLADEL = bpfg.ID_LOKALID [snippet_bitemp_full(ejl)] -- fordi vi har brug for evt. lejligheder i en BPFGFlade 
LEFT JOIN EJERLEJLIGHED ejl2 ON ejl2.B_BYGNINGPAAFREMMEDGRUNDPUNKTL = bpfg.ID_LOKALID [snippet_bitemp_full(ejl2)] -- fordi vi har brug for evt. lejligheder i en BPFGFlade 

WHERE (@BFEnr IS NOT NULL AND @SagsId IS NOT NULL)

AND (@BFEnr IS NULL OR bpfg.BFENUMMER IN @BFEnr)
AND (@SagsId IS NULL OR bpfg.SENESTESAGLOKALID = @SagsId )

--Bitemporalitet
[snippet_bitemp_full(bpfg)]



--Statussøgning går igennem alle tabeller
AND (@Status IS NULL OR bpfg.STATUS = @Status)

--------------------
--SQL Ejerlejlighed:
--------------------
SELECT * 
FROM EJERLEJLIGHED ejl 
LEFT JOIN EJERLEJLIGHED_SEKUNDAERFORRETN ejlse ON ejlse.EJERLEJLIGHEDOBJECTID = ejl.OBJECTID
LEFT JOIN EJERLEJLIGHEDSLOD ejllod ON ejllod.EJERLEJLIGHEDLOKALID = ejl.ID_LOKALID [snippet_bitemp_full(ejllod)]

WHERE (@BFEnr IS NOT NULL AND @SagsId IS NOT NULL)

AND (@BFEnr IS NULL OR ejl.BFENUMMER IN @BFEnr)
AND (@SagsId IS NULL OR ejl.SENESTESAGLOKALID = @SagsId )

--Bitemporalitet
[snippet_bitemp_full(ejl)]


--Statussøgning går igennem alle tabeller
AND (@Status IS NULL OR ejl.STATUS = @Status)
OR (@Status IS NULL OR ejllod.STATUS IS NULL OR ejllod.STATUS = @Status)