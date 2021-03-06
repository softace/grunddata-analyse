SELECT TekniskAnl�gSource.*, BygningP�FremmedGrund.*, Ejerlejlighed.* FROM TekniskAnl�g AS TekniskAnl�gSource
LEFT JOIN Ejendomsrelation AS Ejerlejlighed ON TekniskAnl�gSource.ejerlejlighed = Ejerlejlighed.id_lokalId
LEFT JOIN Ejendomsrelation AS BygningP�FremmedGrund ON TekniskAnl�gSource.bygningP�FremmedGrund = BygningP�FremmedGrund.id_lokalId   
WHERE (@Id = NULL OR TekniskAnl�gSource.id_lokalId IN @Id)
AND (@VirkningFra = NULL OR TekniskAnl�gSource.virkningTil = NULL OR @VirkningFra < TekniskAnl�gSource.virkningTil) 
AND (@VirkningTil = NULL OR TekniskAnl�gSource.virkningFra = NULL OR @VirkningTil >= TekniskAnl�gSource.virkningFra)
AND (@Virkningsaktoer = NULL OR TekniskAnl�gSource.virkningsakt�r = @Virkningsaktoer)
AND (@RegistreringFra = NULL OR TekniskAnl�gSource.registreringTil = NULL OR @RegistreringFra < TekniskAnl�gSource.registreringTil)
AND (@RegistreringTil = NULL OR TekniskAnl�gSource.registreringFra = NULL OR @RegistreringTil >= TekniskAnl�gSource.registreringFra) 
AND (@Registreringsaktoer = NULL OR TekniskAnl�gSource.registreringsakt�r = @Registreringsaktoer)
AND (@Status = NULL OR TekniskAnl�gSource.status IN @Status)
AND (@Forretningsproces = NULL OR TekniskAnl�gSource.forretningsproces = @Forretningsproces)
AND (@Forretningsomraade = NULL OR TekniskAnl�gSource.forretningsomr�de = @Forretningsomraade)
AND (@Forretningshaendelse = NULL OR TekniskAnl�gSource.forretningsh�ndelse = @Forretningshaendelse)
AND (@Kommunekode = NULL OR TekniskAnl�gSource.Kommunekode = @Kommunekode)
AND (@DAFTimestampFra = NULL OR @DAFTimestampFra <= TekniskAnl�gSource.UpdateTimestamp())
AND (@DAFTimestampTil = NULL OR @DAFTimestampTil > TekniskAnl�gSource.UpdateTimestamp())
AND (@Nord = NULL OR @Syd = NULL OR @Oest = NULL OR @Vest = NULL OR Point(TekniskAnl�gSource.tek109Koordinat) WITHIN boundingbox(@Vest,@Nord,@Oest,@Syd))
AND (@Jordstykke = NULL OR TekniskAnl�gSource.jordstykke = @Jordstykke)
AND (@Grund = NULL OR TekniskAnl�gSource.grund = @Grund)
AND (@Enhed = NULL OR TekniskAnl�gSource.enhed = @Enhed)
AND (@Bygning = NULL OR TekniskAnl�gSource.bygning = @Bygning)
AND (@Husnummer = NULL OR TekniskAnl�gSource.husnummer = @Husnummer)
AND (@Ejendomsrelation = NULL OR TekniskAnl�gSource.bygningP�FremmedGrund = @Ejendomsrelation OR TekniskAnl�gSource.ejerlejlighed = @Ejendomsrelation)
AND (@BFENummer = NULL OR Ejerlejlighed.bfeNummer = @BFENummer OR BygningP�FremmedGrund.bfeNummer = @BFENummer)
AND (
	@PeriodeaendringFra = NULL 
	OR
	@PeriodeaendringTil = NULL
	OR (
	TekniskAnl�gSource.id_lokalId IN
	(
		SELECT DISTINCT TekniskAnl�gChanges.id_lokalId FROM TekniskAnl�g AS TekniskAnl�gChanges
		WHERE TekniskAnl�gChanges.Id
		IN 
		(
			SELECT DISTINCT TA.id_lokalId FROM TekniskAnl�g AS TA
			WHERE
			(
				(TA.registreringFra >= @PeriodeaendringFra AND TA.registreringFra <= @PeriodeaendringTil) 
				OR 
				(TA.registreringTil >= @PeriodeaendringFra AND TA.registreringTil <= @PeriodeaendringTil)
			)
		)
		UNION
		SELECT DISTINCT TekniskAnl�gChanges.id_lokalId FROM TekniskAnl�g AS TekniskAnl�gChanges
		WHERE TekniskAnl�gChanges.Ejerlejlighed
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
		SELECT DISTINCT TekniskAnl�gChanges.id_lokalId FROM TekniskAnl�g AS TekniskAnl�gChanges
		WHERE TekniskAnl�gChanges.BygningP�FremmedGrund
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
	)
	AND TekniskAnl�gSource.virkningTil = NULL 
	AND
	(
		(
			@KunNyesteIPeriode = FALSE
			AND 
			TekniskAnl�gSource.registreringFra <= @PeriodeaendringFra AND (TekniskAnl�gSource.registreringTil > @PeriodeaendringFra OR TekniskAnl�gSource.registreringTil = NULL) 
			AND
			(
				Ejerlejlighed.id_lokalId = NULL OR
				(
					Ejerlejlighed.virkningTil = NULL AND
					Ejerlejlighed.registreringFra <= @PeriodeaendringFra AND (Ejerlejlighed.registreringTil > @PeriodeaendringFra OR Ejerlejlighed.registreringTil = NULL) 
				)
			)
			AND
			(
				BygningP�FremmedGrund.id_lokalId = NULL OR
				(
					BygningP�FremmedGrund.virkningTil = NULL AND
					BygningP�FremmedGrund.registreringFra <= @PeriodeaendringFra AND (BygningP�FremmedGrund.registreringTil > @PeriodeaendringFra OR BygningP�FremmedGrund.registreringTil = NULL) 
				)
			)
		)
		OR
		(
			TekniskAnl�gSource.registreringFra <= @PeriodeaendringTil AND (TekniskAnl�gSource.registreringTil > @PeriodeaendringTil OR TekniskAnl�gSource.registreringTil = NULL)
			AND
			(
				Ejerlejlighed.id_lokalId = NULL OR
				(
					Ejerlejlighed.virkningTil = NULL AND
					Ejerlejlighed.registreringFra <= @PeriodeaendringTil AND (Ejerlejlighed.registreringTil > @PeriodeaendringTil OR Ejerlejlighed.registreringTil = NULL)
				)
			)
			AND
			(
				BygningP�FremmedGrund.id_lokalId = NULL OR
				(
					BygningP�FremmedGrund.virkningTil = NULL AND
					BygningP�FremmedGrund.registreringFra <= @PeriodeaendringTil AND (BygningP�FremmedGrund.registreringTil > @PeriodeaendringTil OR BygningP�FremmedGrund.registreringTil = NULL)
				)
			)
		)
	)
))