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
LEFT JOIN EJERLEJLIGHED ejl ON ejl.B_BYGNINGPAAFREMMEDGRUNDFLADEL = bpfg.ID_LOKALID [snippet_bitemp_full(ejl)] -- fordi vi har brug for evt. lejligheder i en BPFGFlade 
LEFT JOIN EJERLEJLIGHED ejl2 ON ejl2.B_BYGNINGPAAFREMMEDGRUNDPUNKTL = bpfg.ID_LOKALID [snippet_bitemp_full(ejl2)] -- fordi vi har brug for evt. lejligheder i en BPFGFlade 
INNER JOIN EBR.EJENDOMSBELIGGENHED eb ON bpfg.ID_LOKALID = eb.BESTEMTFASTEJENDOMBFENR

WHERE (@Kommunekode IS NULL OR eb.KOMMUNEINDDELINGKOMMUNEKODE = @Kommunekode)

--Bitemporalitet
[snippet_bitemp_full(bpfg)]
[snippet_bitemp_full_now(eb)]

--Statussøgning leder efter noget der er historisk et sted i det SFE'en består af.
--Ting der ligger på BPFG'en (EJL'er) får ikke tjekket deres status
AND (@Status IS NULL OR bpfg.STATUS = @Status)