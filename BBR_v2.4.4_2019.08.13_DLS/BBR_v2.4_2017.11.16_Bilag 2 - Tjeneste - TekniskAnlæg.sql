SELECT TekniskAnlægSource.*, BygningPåFremmedGrund.*, Ejerlejlighed.* FROM TekniskAnlæg AS TekniskAnlægSource
LEFT JOIN Ejendomsrelation AS Ejerlejlighed ON TekniskAnlægSource.ejerlejlighed = Ejerlejlighed.id_lokalId
LEFT JOIN Ejendomsrelation AS BygningPåFremmedGrund ON TekniskAnlægSource.bygningPåFremmedGrund = BygningPåFremmedGrund.id_lokalId   
WHERE (@Id = NULL OR TekniskAnlægSource.id_lokalId IN @Id)
AND (@VirkningFra = NULL OR TekniskAnlægSource.virkningTil = NULL OR @VirkningFra < TekniskAnlægSource.virkningTil) 
AND (@VirkningTil = NULL OR TekniskAnlægSource.virkningFra = NULL OR @VirkningTil >= TekniskAnlægSource.virkningFra)
AND (@Virkningsaktoer = NULL OR TekniskAnlægSource.virkningsaktør = @Virkningsaktoer)
AND (@RegistreringFra = NULL OR TekniskAnlægSource.registreringTil = NULL OR @RegistreringFra < TekniskAnlægSource.registreringTil)
AND (@RegistreringTil = NULL OR TekniskAnlægSource.registreringFra = NULL OR @RegistreringTil >= TekniskAnlægSource.registreringFra) 
AND (@Registreringsaktoer = NULL OR TekniskAnlægSource.registreringsaktør = @Registreringsaktoer)
AND (@Status = NULL OR TekniskAnlægSource.status IN @Status)
AND (@Forretningsproces = NULL OR TekniskAnlægSource.forretningsproces = @Forretningsproces)
AND (@Forretningsomraade = NULL OR TekniskAnlægSource.forretningsområde = @Forretningsomraade)
AND (@Forretningshaendelse = NULL OR TekniskAnlægSource.forretningshændelse = @Forretningshaendelse)
AND (@Kommunekode = NULL OR TekniskAnlægSource.Kommunekode = @Kommunekode)
AND (@DAFTimestampFra = NULL OR @DAFTimestampFra <= TekniskAnlægSource.UpdateTimestamp())
AND (@DAFTimestampTil = NULL OR @DAFTimestampTil > TekniskAnlægSource.UpdateTimestamp())
AND (@Nord = NULL OR @Syd = NULL OR @Oest = NULL OR @Vest = NULL OR Point(TekniskAnlægSource.tek109Koordinat) WITHIN boundingbox(@Vest,@Nord,@Oest,@Syd))
AND (@Jordstykke = NULL OR TekniskAnlægSource.jordstykke = @Jordstykke)
AND (@Grund = NULL OR TekniskAnlægSource.grund = @Grund)
AND (@Enhed = NULL OR TekniskAnlægSource.enhed = @Enhed)
AND (@Bygning = NULL OR TekniskAnlægSource.bygning = @Bygning)
AND (@Husnummer = NULL OR TekniskAnlægSource.husnummer = @Husnummer)
AND (@Ejendomsrelation = NULL OR TekniskAnlægSource.bygningPåFremmedGrund = @Ejendomsrelation OR TekniskAnlægSource.ejerlejlighed = @Ejendomsrelation)
AND (@BFENummer = NULL OR Ejerlejlighed.bfeNummer = @BFENummer OR BygningPåFremmedGrund.bfeNummer = @BFENummer)
AND (
	@PeriodeaendringFra = NULL 
	OR
	@PeriodeaendringTil = NULL
	OR (
	TekniskAnlægSource.id_lokalId IN
	(
		SELECT DISTINCT TekniskAnlægChanges.id_lokalId FROM TekniskAnlæg AS TekniskAnlægChanges
		WHERE TekniskAnlægChanges.Id
		IN 
		(
			SELECT DISTINCT TA.id_lokalId FROM TekniskAnlæg AS TA
			WHERE
			(
				(TA.registreringFra >= @PeriodeaendringFra AND TA.registreringFra <= @PeriodeaendringTil) 
				OR 
				(TA.registreringTil >= @PeriodeaendringFra AND TA.registreringTil <= @PeriodeaendringTil)
			)
		)
		UNION
		SELECT DISTINCT TekniskAnlægChanges.id_lokalId FROM TekniskAnlæg AS TekniskAnlægChanges
		WHERE TekniskAnlægChanges.Ejerlejlighed
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
		SELECT DISTINCT TekniskAnlægChanges.id_lokalId FROM TekniskAnlæg AS TekniskAnlægChanges
		WHERE TekniskAnlægChanges.BygningPåFremmedGrund
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
	AND TekniskAnlægSource.virkningTil = NULL 
	AND
	(
		(
			@KunNyesteIPeriode = FALSE
			AND 
			TekniskAnlægSource.registreringFra <= @PeriodeaendringFra AND (TekniskAnlægSource.registreringTil > @PeriodeaendringFra OR TekniskAnlægSource.registreringTil = NULL) 
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
				BygningPåFremmedGrund.id_lokalId = NULL OR
				(
					BygningPåFremmedGrund.virkningTil = NULL AND
					BygningPåFremmedGrund.registreringFra <= @PeriodeaendringFra AND (BygningPåFremmedGrund.registreringTil > @PeriodeaendringFra OR BygningPåFremmedGrund.registreringTil = NULL) 
				)
			)
		)
		OR
		(
			TekniskAnlægSource.registreringFra <= @PeriodeaendringTil AND (TekniskAnlægSource.registreringTil > @PeriodeaendringTil OR TekniskAnlægSource.registreringTil = NULL)
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
				BygningPåFremmedGrund.id_lokalId = NULL OR
				(
					BygningPåFremmedGrund.virkningTil = NULL AND
					BygningPåFremmedGrund.registreringFra <= @PeriodeaendringTil AND (BygningPåFremmedGrund.registreringTil > @PeriodeaendringTil OR BygningPåFremmedGrund.registreringTil = NULL)
				)
			)
		)
	)
))