--Der skal kun bruges MatrikelKommune tabellen for at give resultatet for denne service
SELECT * FROM MATRIKELKOMMUNE mk
WHERE (@Kommunenavn IS NOT NULL OR @Kommunekode IS NOT NULL)
AND (@Kommunenavn IS NULL OR mk.KOMMUNENAVN LIKE %@Kommunenavn%) --Wildcard på begge sidder af input fx '%Roskil%' vil give Roskilde Kommune
AND (@Kommunekode IS NULL OR mk.KOMMUNEKODE = @Kommunekode)

--Bitemporalitet
[snippet_bitemp_full_with_period(mk)]

--Statussøgning
AND (@Status IS NULL OR mk.STATUS = @Status)