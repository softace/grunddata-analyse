--Der findes to forskellige tabeller med bygning på fremmed grund. Der er kun en søjle til forskel. De smeltes sammen så at der kun er BPFG med enten en flade eller et puntk defineret.
--Sørg for at få sekundære forretningshændelser og al nødvendig data med.
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
LEFT JOIN EJERLEJLIGHED ejl ON ejl.B_BYGNINGPAAFREMMEDGRUNDFLADEL = bpfg.ID_LOKALID [snippet_bitemp_full_optional(ejl)] -- fordi vi har brug for evt. lejligheder i en BPFGFlade 
LEFT JOIN EJERLEJLIGHED ejl2 ON ejl2.B_BYGNINGPAAFREMMEDGRUNDPUNKTL = bpfg.ID_LOKALID [snippet_bitemp_full_optional(ejl2)] -- fordi vi har brug for evt. lejligheder i en BPFGFlade 
--Ikke med i output, men vi vil søge på SFE'ens geometri og ejerlav/matrikelnr
LEFT JOIN SAMLETFASTEJENDOM sfe ON bpfg.SAMLETFASTEJENDOMLOKALID = sfe.ID_LOKALID [snippet_bitemp_full_optional(sfe)]
LEFT JOIN JORDSTYKKE jst ON jst.SAMLETFASTEJENDOMLOKALID = sfe.ID_LOKALID [snippet_bitemp_full_optional(jst)]
LEFT JOIN SAMLETFASTEJENDOM_JORDSTYKKE sfejst ON sfejst.SAMLETFASTEJENDOMOBJECTID = sfe.OBJECTID --Fælles lod
LEFT JOIN JORDSTYKKE jst2 ON jst2.OBJECTID = sfejst.JORDSTYKKEOBJECTID [snippet_bitemp_full_optional(jst2)]

--Sørg for at en gyldig kombination af inputs er givet
WHERE (@SFEBFEnr IS NOT NULL OR @BPFGBFEnr IS NOT NULL OR (@Ejerlavskode IS NOT NULL AND @Matrikelnr IS NOT NULL) OR @Point IS NOT NULL OR @Sagsid IS NOT NULL)
AND ((@Ejerlavkode IS NULL AND @Matrikelnr IS NULL) OR (@Ejerlavkode IS NOT NULL AND @Matrikelnr IS NOT NULL))

--Filtrer på inputs
AND (@SFEBFEnr IS NULL OR sfe.BFENUMMER = @SFEBFEnr )
AND (@BPFGBFEnr IS NULL OR bpfg.BFENUMMER = @BPFGBFEnr )
AND ((@Ejerlavkode IS NULL OR jst.EJERLAVLOKALID = @Ejerlavkode) AND (@Matrikelnr IS NULL OR jst.MATRIKELNUMMER = @Matrikelnr) )
-- Some kind of fuzzyness is required for the equality and WITHIN comparisons here so that points that are very near the search point can be found.
AND (@Point IS NULL OR (sfe.GEOMETRI IS NOT NULL AND @Point WITHIN sfe.GEOMETRI) OR (bpfg.geometriflade IS NOT NULL AND @Point WITHIN bpfg.geometriflade) OR (bpfg.geometripunkt IS NOT NULL AND @Point WITHIN CIRCLE(bpfg.geometripunkt, 1 meter)))
AND (@SagsId IS NULL OR bpfg.SENESTESAGLOKALID = @SagsId )

--Bitemporalitet
[snippet_bitemp_full(bpfg)]

--Statussøgning leder efter noget der er historisk et sted i det SFE'en består af.
--Ting der ligger på BPFG'en (EJL'er) får ikke tjekket deres status
AND (@Status IS NULL OR bpfg.STATUS = @Status)