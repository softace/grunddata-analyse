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

--Fill DAR information
LEFT JOIN DAR.Adresse adr ON eb.ADRESSELOKALID = adr.ID_LOKALID [snippet_bitemp_full(adr)]
LEFT JOIN DAR.Adressepunkt doerpkt ON doerpkt.id_lokalId = adr.dørpunkt [snippet_bitemp_full(doerpkt)]
LEFT JOIN DAR.Husnummer husnr ON husnr.id_lokalId = adr.husnummer [snippet_bitemp_full(husnr)]
LEFT JOIN DAR.Adressepunkt Adgangspunkt ON Adgangspunkt.id_lokalId = husnr.adgangspunkt  [snippet_bitemp_full(Adgangspunkt)]
LEFT JOIN DAR.Adressepunkt Vejpunkt ON Vejpunkt.id_lokalId = husnr.vejpunkt  [snippet_bitemp_full(Vejpunkt)]
LEFT JOIN DAR.NavngivenVej NavngivenVej ON NavngivenVej.id_lokalId = husnr.navngivenVej [snippet_bitemp_full(NavngivenVej)]
LEFT JOIN DAR.Postnummer Postnummer ON Postnummer.id_lokalId = husnr.postnummer [snippet_bitemp_full(Postnummer)]
LEFT JOIN DAR.SupplerendeBynavn SupplerendeBynavn ON SupplerendeBynavn.id_lokalId = husnr.supplerendeBynavn [snippet_bitemp_full(SupplerendeBynavn)]
--Fill DAGI information
LEFT JOIN DAGI.Afstemningsomraade Afstemningsomraade ON Afstemningsomraade.id_lokalId = husnr.afstemningsområde [snippet_bitemp_full(Afstemningsomraade)]
LEFT JOIN DAGI.Kommuneinddeling Kommuneinddeling ON Kommuneinddeling.id_lokalId = husnr.kommuneinddeling [snippet_bitemp_full(Kommuneinddeling)]
LEFT JOIN DAGI.MRafstemningsomraade Menighedsrådsafstemningsområde ON Menighedsrådsafstemningsområde.id_lokalId = husnr.menighedsrådsafstemningsområde [snippet_bitemp_full(Menighedsrådsafstemningsområde)]
LEFT JOIN DAGI.Sogneinddeling Sogneinddeling ON Sogneinddeling.id_lokalId = husnr.sogneinddeling [snippet_bitemp_full(Sogneinddeling)]

LEFT JOIN DAR.NavngivenVejKommunedel NavngivenVejKommunedel ON NavngivenVejKommunedel.navngivenVej = NavngivenVej.id_lokalId AND NavngivenVejKommunedel.kommune = Kommuneinddeling.kommunekode [snippet_bitemp_full(NavngivenVejKommunedel)]

--Fill in DAR information again, but this time if ejendom has husnummer relation
LEFT JOIN DAR.Husnummer husnr2 ON eb.HUSNUMMERLOKALID = husnr2.id_lokalId [snippet_bitemp_full(husnr2)]
LEFT JOIN DAR.Adressepunkt Adgangspunkt2 ON Adgangspunkt2.id_lokalId = husnr2.adgangspunkt  [snippet_bitemp_full(Adgangspunkt2)]
LEFT JOIN DAR.Adressepunkt Vejpunkt2 ON Vejpunkt2.id_lokalId = husnr2.vejpunkt  [snippet_bitemp_full(Vejpunkt2)]
LEFT JOIN DAR.Adresse Adresse2 ON Adresse2.husnummer = husnr2.id_lokalId [snippet_bitemp_full(Adresse2)]
LEFT JOIN DAR.Adgangspunkt Dørpunkt2 ON Dørpunkt2.id_lokalId = Adresse2.dørpunkt [snippet_bitemp_full(Dørpunkt2)]
LEFT JOIN DAR.NavngivenVej NavngivenVej2 ON NavngivenVej2.id_lokalId = husnr2.navngivenVej [snippet_bitemp_full(NavngivenVej2)]
LEFT JOIN DAR.Postnummer Postnummer2 ON Postnummer2.id_lokalId = husnr2.postnummer [snippet_bitemp_full(Postnummer2)]
LEFT JOIN DAR.SupplerendeBynavn SupplerendeBynavn2 ON SupplerendeBynavn2.id_lokalId = husnr2.supplerendeBynavn [snippet_bitemp_full(SupplerendeBynavn2)]
--Fill DAGI information
LEFT JOIN DAGI.Afstemningsområde Afstemningsområde2 ON Afstemningsområde2.id_lokalId = husnr2.afstemningsområde [snippet_bitemp_full(Afstemningsområde2)]
LEFT JOIN DAGI.Kommuneinddeling Kommuneinddeling2 ON Kommuneinddeling2.id_lokalId = husnr2.kommuneinddeling [snippet_bitemp_full(Kommuneinddeling2)]
LEFT JOIN DAGI.Menighedsrådsafstemningsområde Menighedsrådsafstemningsområde2 ON Menighedsrådsafstemningsområde2.id_lokalId = husnr2.menighedsrådsafstemningsområde [snippet_bitemp_full(Menighedsrådsafstemningsområde2)]
LEFT JOIN DAGI.Sogneinddeling Sogneinddeling2 ON Sogneinddeling2.id_lokalId = husnr2.sogneinddeling [snippet_bitemp_full(Sogneinddeling2)]

LEFT JOIN DAR.NavngivenVejKommunedel NavngivenVejKommunedel2 ON NavngivenVejKommunedel2.navngivenVej = NavngivenVej2.id_lokalId AND NavngivenVejKommunedel2.kommune = Kommuneinddeling2.kommunekode [snippet_bitemp_full(NavngivenVejKommunedel2)]


WHERE (@EBId is NOT NULL OR @BFEnr IS NOT NULL)
AND (@EBId IS NULL OR eb.id_lokalId IN @EBId)
AND (@BFEnr IS NULL OR eb.BESTEMTFASTEJENDOMBFENR IN @BFEnr)

[snippet_bitemp_full(eb, id_lokalid)]

AND (@Status IS NULL OR eb.STATUS = @Status)
--Status is not carried into DAR or DAGI as 
-- 1) It's not necessary since you don't have to use it to determine a single entity with lokalId+bitemporalitet
-- 2) Their models are different. You cannot search for several or any of their statuses
-- 3) Picking some statuses in EBR could break the search on DAR and DAGI due to reason 2) going the other way
