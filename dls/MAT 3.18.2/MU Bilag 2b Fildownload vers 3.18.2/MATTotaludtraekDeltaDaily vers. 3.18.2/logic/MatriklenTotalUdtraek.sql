--BygningPaaFremmedGrundFladeList [TABEL] = BYGNINGPAAFREMMEDGRUNDFLADE
--BygningPaaFremmedGrundPunktList [TABEL] = BYGNINGPAAFREMMEDGRUNDPUNKT
--CentroideList                   [TABEL] = CENTROIDE
--EjerlavList                     [TABEL] = EJERLAV
--EjerlejlighedList               [TABEL] = EJERLEJLIGHED
--EjerlejlighedslodList           [TABEL] = EJERLEJLIGHEDSLOD
--JordstykkeList                  [TABEL] = JORDSTYKKE
--JordstykkeTemafladeList         [TABEL] = JORDSTYKKETEMAFLADE
--LodfladeList                    [TABEL] = LODFLADE
--MatrikelKommuneList             [TABEL] = MATRIKELKOMMUNE
--MatrikelRegionList              [TABEL] = MATRIKELREGION
--MatrikelSognList                [TABEL] = MATRIKELSOGN
--MatrikelskelList                [TABEL] = MATRIKELSKEL
--MatrikulaerSagList              [TABEL] = MATRIKULAERSAG
--NullinjeList                    [TABEL] = NULLINJE
--SamletFastEjendomList           [TABEL] = SAMLETFASTEJENDOM
--SkelpunktList                   [TABEL] = SKELPUNKT
--TemalinjeList                   [TABEL] = TEMALINJE
--OptagetVejList                  [TABEL] = OPTAGETVEJ

SELECT table.* FROM [TABEL] table

WHERE 1 = 1
[snippet_bitemp_full_with_period(table)]

AND (@Status IS NULL OR table.STATUS = @Status)

--StormfaldList
SELECT table.* FROM STORMFALD table
INNER JOIN JORDSTYKKE_STORMFALD sfjst ON sfjst.STORMFALDOBJECTID = table.OBJECTID
INNER JOIN JORDSTYKKE jst ON jst.OBJECTID = sfjst.JORDSTYKKEOBJECTID [snippet_bitemp_full_with_period(jst)]

AND (@Status IS NULL OR jst.STATUS = @Status)


--Bygningpaafremmedgrundflade_SeList [TABEL] = BYGNINGPAAFREMMEDGRUNDFLADE
--Bygningpaafremmedgrundpunkt_SeList [TABEL] = BYGNINGPAAFREMMEDGRUNDPUNKT
--Centroide_SekundaerforretningsList [TABEL] = CENTROIDE
--Ejerlejlighed_SekundaerforretnList [TABEL] = EJERLEJLIGHED
--Ejerlejlighedslod_SekundaerforList [TABEL] = EJERLEJLIGHEDSLOD
--Jordstykke_SekundaerforretningList [TABEL] = JORDSTYKKE
--Jordstykketemaflade_SekundaerfList [TABEL] = JORDSTYKKETEMAFLADE
--Lodflade_SekundaerforretningshList [TABEL] = LODFLADE
--Matrikelskel_SekundaerforretniList [TABEL] = MATRIKELSKEL
--Nullinje_SekundaerforretningshList [TABEL] = NULLINJE
--Optagetvej_SekundaerforretningList [TABEL] = OPTAGETVEJ
--Skelpunkt_SekundaerforretningsList [TABEL] = SKELPUNKT
--Temalinje_SekundaerforretningsList [TABEL] = TEMALINJE
--Samletfastejendom_SekundaerforList [TABEL] = SAMLETFASTEJENDOM
SELECT seTable.* FROM [TABLE]_SE seTable

WHERE seTable.[TABLE]OBJ IN (SELECT table.OBJECTID FROM [TABEL] table

WHERE 1 = 1
[snippet_bitemp_full_with_period(table)]

AND (@Status IS NULL OR table.STATUS = @Status))


--Optagetvej_JordstykkeList          [LTABEL] = OPTAGETVEJ        [RTABLE] = JORDSTYKKE
--Temalinje_JordstykkeList           [LTABEL] = TEMALINJE         [RTABLE] = JORDSTYKKE
--Samletfastejendom_JordstykkeList   [LTABEL] = SAMLETFASTEJENDOM [RTABLE] = JORDSTYKKE
SELECT xtable.* FROM [LTABEL]_[RTABEL] xtable
WHERE xtable.[LTABEL]OBJECTID IN (SELECT table.OBJECTID FROM [LTABEL] table
	WHERE 1 = 1
	[snippet_bitemp_full_with_period(table)]
	AND (@Status IS NULL OR table.STATUS = @Status))
AND xtable[RTABEL]OBJECTID IN (SELECT table.OBJECTID FROM [RTABEL] table
	WHERE 1 = 1
	[snippet_bitemp_full_with_period(table)]
	AND (@Status IS NULL OR table.STATUS = @Status))


--Jordstykke_StormfaldList           [LTABEL] = JORDSTYKKE        [RTABLE] = STORMFALD
SELECT xtable.* FROM [LTABEL]_[RTABEL] xtable
WHERE xtable.[LTABEL]OBJECTID IN (SELECT table.OBJECTID FROM [LTABEL] table
    WHERE 1 = 1
    [snippet_bitemp_full_with_period(table)]
    AND (@Status IS NULL OR table.STATUS = @Status))

