--Find data. Sørg for at få sekundære forretningshændelser og al nødvendig data med.
SELECT * 
FROM EJERLEJLIGHED ejl 
LEFT JOIN EJERLEJLIGHED_SEKUNDAERFORRETN ejlse ON ejlse.EJERLEJLIGHEDOBJECTID = ejl.OBJECTID
LEFT JOIN EJERLEJLIGHEDSLOD ejllod ON ejllod.EJERLEJLIGHEDLOKALID = ejl.ID_LOKALID  [snippet_bitemp_full(ejllod)]
-- Used for searching, not part of output, if Ejerlavskode/Matrikelnr is entered and EJL is on an SFE
LEFT JOIN SAMLETFASTEJENDOM sfe ON ejl.SAMLETFASTEJENDOMLOKALID=sfe.ID_LOKALID [snippet_bitemp_full(sfe)]
LEFT JOIN JORDSTYKKE jst ON jst.SAMLETFASTEJENDOMLOKALID = sfe.ID_LOKALID [snippet_bitemp_full(jst)]
LEFT JOIN SAMLETFASTEJENDOM_JORDSTYKKE sfejst ON sfejst.SAMLETFASTEJENDOMOBJECTID = sfe.OBJECTID --Fælles lod
LEFT JOIN JORDSTYKKE jst2 ON jst2.OBJECTID = sfejst.JORDSTYKKEOBJECTID [snippet_bitemp_full(jst2)]
-- Used for searching, not part of output, if Ejerlavskode/Matrikelnr is entered and EJL is on BPFG Punkt
LEFT JOIN BYGNINGPAAFREMMEDGRUNDPUNKT bpfgp ON bpfgp.ID_LOKALID = ejl.B_BYGNINGPAAFREMMEDGRUNDPUNKTL [snippet_bitemp_full(bpfgp)]
LEFT JOIN SAMLETFASTEJENDOM bpfgpsfe ON bpfgpsfe.ID_LOKALID = bpfgp.SAMLETFASTEJENDOMLOKALID [snippet_bitemp_full(bpfgpsfe)]
LEFT JOIN JORDSTYKKE bpfgpjst on bpfgpjst.SAMLETFASTEJENDOMLOKALID = bpfgpsfe.ID_LOKALID [snippet_bitemp_full(bpfgpjst)]
LEFT JOIN SAMLETFASTEJENDOM_JORDSTYKKE bpfgpsfejst ON bpfgpsfejst.SAMLETFASTEJENDOMOBJECTID = bpfgpsfe.OBJECTID --Fælles lod
LEFT JOIN JORDSTYKKE bpfgpjst2 ON bpfgpjst2.OBJECTID = bpfgpsfejst.JORDSTYKKEOBJECTID [snippet_bitemp_full(bpfgpjst2)]
-- Used for searching, not part of output, if Ejerlavskode/Matrikelnr is entered and EJL is on BPFG Flade
LEFT JOIN BYGNINGPAAFREMMEDGRUNDFLADE bpfgf ON bpfgf.ID_LOKALID = ejl.B_BYGNINGPAAFREMMEDGRUNDFLADEL [snippet_bitemp_full(bpfgf)]
LEFT JOIN SAMLETFASTEJENDOM bpfgfsfe ON bpfgfsfe.ID_LOKALID = bpfgf.SAMLETFASTEJENDOMLOKALID [snippet_bitemp_full(bpfgfsfe)]
LEFT JOIN JORDSTYKKE bpfgfjst on bpfgfjst.SAMLETFASTEJENDOMLOKALID = bpfgfsfe.ID_LOKALID [snippet_bitemp_full(bpfgfjst)]
LEFT JOIN SAMLETFASTEJENDOM_JORDSTYKKE bpfgfsfejst ON bpfgfsfejst.SAMLETFASTEJENDOMOBJECTID = bpfgfsfe.OBJECTID --Fælles lod
LEFT JOIN JORDSTYKKE bpfgfjst2 ON bpfgfjst2.OBJECTID = bpfgfsfejst.JORDSTYKKEOBJECTID [snippet_bitemp_full(bpfgfjst2)]


--Sørg for at en gyldig kombination af inputs er givet
WHERE (@Ejerlejlighednr IS NOT NULL OR @SFEBFEnr IS NOT NULL OR @BPFGBFEnr IS NOT NULL OR @ELBFEnr IS NOT NULL OR (@Ejerlavskode IS NOT NULL AND @Matrikelnr IS NOT NULL) OR @Sagsid IS NOT NULL)
AND ((@Ejerlavskode IS NULL AND @Matrikelnr IS NULL) OR (@Ejerlavskode IS NOT NULL AND @Matrikelnr IS NOT NULL))

--Filtrer på inputs
AND (@SFEBFEnr IS NULL OR sfe.BFENUMMER = @SFEBFEnr OR bpfgpsfe.BFENUMMER = @SFEBFEnr OR bpfgfsfe.BFENUMMER = @SFEBFEnr )
AND (@BPFGBFEnr IS NULL OR ejl.B_BYGNINGPAAFREMMEDGRUNDFLADEL = @BPFGBFEnr OR ejl.B_BYGNINGPAAFREMMEDGRUNDPUNKTL = @BPFGBFEnr )
AND (@ELBFEnr IS NULL OR ejl.BFENUMMER = @ELBFEnr )
AND (@Ejerlejlighednr IS NULL OR ejl.EJERLEJLIGHEDSNUMMER = @Ejerlejlighednr )
AND ((@Ejerlavskode IS NULL OR jst.EJERLAVLOKALID = @Ejerlavskode OR jst2.EJERLAVLOKALID = @Ejerlavskode OR bpfgpjst.EJERLAVLOKALID = @Ejerlavskode OR bpfgpjst2.EJERLAVLOKALID = @Ejerlavskode OR bpfgfjst.EJERLAVLOKALID = @Ejerlavskode OR bpfgfjst2.EJERLAVLOKALID = @Ejerlavskode) 
	AND (@Matrikelnr IS NULL OR jst.MATRIKELNUMMER = @Matrikelnr OR jst2.MATRIKELNUMMER = @Matrikelnr OR bpfgpjst.MATRIKELNUMMER = @Matrikelnr OR bpfgpjst2.MATRIKELNUMMER = @Matrikelnr OR bpfgfjst.MATRIKELNUMMER = @Matrikelnr OR bpfgfjst2.MATRIKELNUMMER = @Matrikelnr))
AND (@SagsId IS NULL OR ejl.SENESTESAGLOKALID = @SagsId )

--Bitemporalitet
[snippet_bitemp_full(ejl)]

--Statussøgning går igennem alle tabeller
AND ((@Status IS NULL OR ejl.STATUS = @Status) AND (@Status IS NULL OR ejllod.STATUS IS NULL OR ejllod.STATUS = @Status))