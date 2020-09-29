SELECT DISTINCT * 
FROM EJENDOMSBELIGGENHED eb
-- Work with Matriklen. Note that BFENUMMER = id_LokalId, which is why it won't change over time, 
-- and we only want that number, which is unique for the lifespan of the object.
-- Hence, we can simply take the first occurrance of the object and ignore the rest, ignoring bitemporalitet as well.
INNER JOIN (
SELECT 'SamletFastEjendom' AS Ejendomstype, BFENUMMER FROM Matrikel.SAMLETFASTEJENDOM
UNION
SELECT 'BygningPaaFremmedGrund' AS Ejendomstype, BFENUMMER FROM Matrikel.BYGNINGPAAFREMMEDGRUNDPUNKT
UNION
SELECT 'BygningPaaFremmedGrund' AS Ejendomstype, BFENUMMER FROM Matrikel.BYGNINGPAAFREMMEDGRUNDFLADE
UNION
SELECT 'Ejerlejlighed' AS Ejendomstype, BFENUMMER FROM Matrikel.EJERLEJLIGHED
) bfe ON eb.BESTEMTFASTEJENDOMBFENR = bfe.BFENUMMER

WHERE (@AdresseId is NOT NULL OR @HusnummerId IS NOT NULL)
AND (@AdresseId IS NULL OR eb.ADRESSELOKALID IN @AdresseId)
AND (@HusnummerId IS NULL OR eb.HUSNUMMERLOKALID IN @HusnummerId)

[snippet_bitemp_full(eb)]

AND (@Status IS NULL OR eb.STATUS = @Status)