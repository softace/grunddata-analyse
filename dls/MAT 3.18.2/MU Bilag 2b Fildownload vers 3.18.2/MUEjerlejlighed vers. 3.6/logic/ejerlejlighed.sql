--Find data. Sørg for at få sekundære forretningshændelser og al nødvendig data med.
SELECT * 
FROM EJERLEJLIGHED ejl 
LEFT JOIN EJERLEJLIGHED_SEKUNDAERFORRETN ejlse ON ejlse.EJERLEJLIGHEDOBJECTID = ejl.ID_LOKALID
LEFT JOIN EJERLEJLIGHEDSLOD ejllod ON ejllod.EJERLEJLIGHEDLOKALID = ejl.ID_LOKALID [snippet_bitemp_full(ejllod)]
INNER JOIN EBR.EJENDOMSBELIGGENHED eb ON ejl.ID_LOKALID = eb.BESTEMTFASTEJENDOMBFENR

WHERE (@Kommunekode IS NULL OR eb.KOMMUNEINDDELINGKOMMUNEKODE = @Kommunekode)

--Bitemporalitet
[snippet_bitemp_full(ejl)]

[snippet_bitemp_full_now(eb)]

--Statussøgning går igennem alle tabeller
AND ((@Status IS NULL OR ejl.STATUS = @Status) AND (@Status IS NULL OR ejllod.STATUS IS NULL OR ejllod.STATUS = @Status))