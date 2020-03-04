SELECT GrundSource.*, GrundJordstykkeSource.jordstykke, BestemtFastEjendom.* FROM Grund AS GrundSource
LEFT JOIN GrundJordstykke AS GrundJordstykkeSource ON GrundJordstykkeSource.grund = GrundSource.id_lokalId 
LEFT JOIN Ejendomsrelation AS BestemtFastEjendom ON Ejendomsrelation.id_lokalId = GrundSource.bestemtFastEjendom
WHERE (@Id = NULL OR GrundSource.id_lokalId IN @Id)
AND (@VirkningFra = NULL OR GrundSource.virkningTil = NULL OR @VirkningFra < GrundSource.virkningTil) 
AND (@VirkningTil = NULL OR GrundSource.virkningFra = NULL OR @VirkningTil >= GrundSource.virkningFra)
AND (@Virkningsaktoer = NULL OR GrundSource.virkningsaktør = @Virkningsaktoer)
AND (@RegistreringFra = NULL OR GrundSource.registreringTil = NULL OR @RegistreringFra < GrundSource.registreringTil)
AND (@RegistreringTil = NULL OR GrundSource.registreringFra = NULL OR @RegistreringTil >= GrundSource.registreringFra) 
AND (@Registreringsaktoer = NULL OR GrundSource.registreringsaktør = @Registreringsaktoer)
AND (@Status = NULL OR GrundSource.status IN @Status)
AND (@Forretningsproces = NULL OR GrundSource.forretningsproces = @Forretningsproces)
AND (@Forretningsomraade = NULL OR GrundSource.forretningsområde = @Forretningsomraade)
AND (@Forretningshaendelse = NULL OR GrundSource.forretningshændelse = @Forretningshaendelse)
AND (@Kommunekode = NULL OR GrundSource.Kommunekode = @Kommunekode)
AND (@DAFTimestampFra = NULL OR @DAFTimestampFra <= GrundSource.UpdateTimestamp())
AND (@DAFTimestampTil = NULL OR @DAFTimestampTil > GrundSource.UpdateTimestamp())
AND (@Husnummer = NULL OR GrundSource.husnummer IN @Husnummer)
AND (@Jordstykke = NULL OR GrundSource.id_lokalId in (SELECT GrundJordstykkeInner.grund FROM GrundJordstykke AS GrundJordstykkeInner WHERE GrundJordstykkeInner.jordstykke = @Jordstykke))
AND (@Bygning = NULL OR GrundSource.id_lokalId in (SELECT BygningInner.grund FROM Bygning AS BygningInner WHERE BygningInner.id_lokalId = @Bygning))
AND (@TekniskAnlaeg = NULL OR GrundSource.id_lokalId in (SELECT TekniskAnlægInner.grund FROM TekniskAnlæg AS TekniskAnlægInner WHERE TekniskAnlægInner.id_lokalId = @TekniskAnlaeg))
AND (@Ejendomsrelation = NULL OR GrundSource.bestemtFastEjendom = @Ejendomsrelation)
AND (@BFENummer = NULL OR BestemtFastEjendom.bfeNummer = @BFENummer)
AND (
	@PeriodeaendringFra = NULL
	OR
	@PeriodeaendringTil = NULL
	OR (
	GrundSource.id_lokalId IN
	(
		SELECT DISTINCT GrundChanges.id_lokalId FROM Grund AS GrundChanges
		WHERE GrundChanges.id_lokalId IN
		(
			SELECT DISTINCT G.id_lokalId FROM Grund AS G
			WHERE
			(
				(G.registreringFra >= @PeriodeaendringFra AND G.registreringFra <= @PeriodeaendringTil) 
				OR 
				(G.registreringTil >= @PeriodeaendringFra AND G.registreringTil <= @PeriodeaendringTil)
			)
		)
		UNION
		SELECT DISTINCT GrundChanges.id_lokalId FROM Grund AS GrundChanges
		WHERE GrundChanges.BestemtFastEjendom
		IN
		(
			SELECT DISTINCT ER.id_lokalId FROM Ejendomsrelation AS ER
			WHERE 
			(
				(ER.registreringFra >= @PeriodeaendringFra AND ER.registreringFra <= @PeriodeaendringTil)
				OR
				(ER.registreringTil >= @PeriodeaendringFra AND ER.registreringTil <= @PeriodeaendringTil)
			)
		)
		UNION
		SELECT DISTINCT GrundChanges.id_lokalId FROM Grund AS GrundChanges
		WHERE GrundChanges.id_lokalId
		IN
		(
			SELECT DISTINCT GJ.grund FROM GrundJordstykke AS GJ
			WHERE 
			(
				(GJ.registreringFra >= @PeriodeaendringFra AND GJ.registreringFra <= @PeriodeaendringTil)
				OR
				(GJ.registreringTil >= @PeriodeaendringFra AND GJ.registreringTil <= @PeriodeaendringTil)
			)
		)
	)
	AND GrundSource.virkningTil = NULL
	AND 
	(
		(
			@KunNyesteIPeriode = FALSE
			AND 
			GrundSource.registreringFra <= @PeriodeaendringFra AND (GrundSource.registreringTil > @PeriodeaendringFra OR GrundSource.registreringTil = NULL) 
			AND
			(
				BestemtFastEjendom.id_lokalId = NULL OR
				(
					BestemtFastEjendom.virkningTil = NULL AND
					BestemtFastEjendom.registreringFra <= @PeriodeaendringFra AND (BestemtFastEjendom.registreringTil > @PeriodeaendringFra OR BestemtFastEjendom.registreringTil = NULL) 
				)
			)	
			AND
			(
				GrundJordstykkeSource.id_lokalId = NULL OR
				(
					GrundJordstykkeSource.virkningTil = NULL AND
					GrundJordstykkeSource.registreringFra <= @PeriodeaendringFra AND (GrundJordstykkeSource.registreringTil > @PeriodeaendringFra OR GrundJordstykkeSource.registreringTil = NULL) 
				)
			)
		)
		OR
		(
			GrundSource.registreringFra <= @PeriodeaendringTil AND (GrundSource.registreringTil > @PeriodeaendringTil OR GrundSource.registreringTil = NULL) 
			AND
			(
				BestemtFastEjendom.id_lokalId = NULL OR
				(
					BestemtFastEjendom.virkningTil = NULL AND
					BestemtFastEjendom.registreringFra <= @PeriodeaendringTil AND (BestemtFastEjendom.registreringTil > @PeriodeaendringTil OR BestemtFastEjendom.registreringTil = NULL) 
				)
			)	
			AND
			(
				GrundJordstykkeSource.id_lokalId = NULL OR
				(
					GrundJordstykkeSource.virkningTil = NULL AND
					GrundJordstykkeSource.registreringFra <= @PeriodeaendringTil AND (GrundJordstykkeSource.registreringTil > @PeriodeaendringTil OR GrundJordstykkeSource.registreringTil = NULL) 
				)
			)	
		)
	)
))