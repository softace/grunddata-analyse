SELECT BBRSagSource.*, SagsniveauSource.* FROM BBRSag AS BBRSagSource
LEFT JOIN Sagsniveau AS SagsniveauSource ON SagsniveauSource.byggesag = BBRSagSource.id_lokalId
WHERE (@Id = NULL OR BBRSagSource.id_lokalId In @Id)
AND (@VirkningFra = NULL OR BBRSagSource.virkningTil = NULL OR @VirkningFra < BBRSagSource.virkningTil) 
AND (@VirkningTil = NULL OR BBRSagSource.virkningFra = NULL OR @VirkningTil >= BBRSagSource.virkningFra)
AND (@Virkningsaktoer = NULL OR BBRSagSource.virkningsaktør = @Virkningsaktoer)
AND (@RegistreringFra = NULL OR BBRSagSource.registreringTil = NULL OR @RegistreringFra < BBRSagSource.registreringTil)
AND (@RegistreringTil = NULL OR BBRSagSource.registreringFra = NULL OR @RegistreringTil >= BBRSagSource.registreringFra) 
AND (@Registreringsaktoer = NULL OR BBRSagSource.registreringsaktør = @Registreringsaktoer)
AND (@Status = NULL OR BBRSagSource.status IN @Status)
AND (@Forretningsproces = NULL OR BBRSagSource.forretningsproces = @Forretningsproces)
AND (@Forretningsomraade = NULL OR BBRSagSource.forretningsområde = @Forretningsomraade)
AND (@Forretningshaendelse = NULL OR BBRSagSource.forretningshændelse = @Forretningshaendelse)
AND (@Kommunekode = NULL OR BBRSagSource.Kommunekode = @Kommunekode)
AND (@DAFTimestampFra = NULL OR @DAFTimestampFra <= BBRSagSource.UpdateTimestamp())
AND (@DAFTimestampTil = NULL OR @DAFTimestampTil > BBRSagSource.UpdateTimestamp())
AND (@Bygning = NULL OR SagsniveauSource.stamdataBygning = @Bygning OR SagsniveauSource.sagsdataBygning = @Bygning)
AND (@Enhed = NULL OR SagsniveauSource.stamdataEnhed = @Enhed OR SagsniveauSource.sagsdataEnhed = @Enhed)
AND (@Etage = NULL OR SagsniveauSource.stamdataEtage = @Etage OR SagsniveauSource.sagsdataEtage = @Etage)
AND (@Grund = NULL OR SagsniveauSource.stamdataGrund = @Grund OR SagsniveauSource.sagsdataGrund = @Grund)
AND (@Opgang = NULL OR SagsniveauSource.stamdataOpgang = @Opgang OR SagsniveauSource.sagsdataOpgang = @Opgang)
AND (@TekniskAnlaeg = NULL OR SagsniveauSource.stamdataTekniskAnlæg = @TekniskAnlæg OR SagsniveauSource.sagsdataTekniskAnlæg = @TekniskAnlaeg)
AND (
	@PeriodeaendringFra = NULL
	OR
	@PeriodeaendringTil = NULL
	OR (
	BBRSagSource.Id_lokalId IN
	(
		SELECT DISTINCT BBRSagChanges.Id_lokalId FROM BBRSag AS BBRSagChanges
		WHERE BBRSagChanges.Id_lokalId IN 
		(
			SELECT DISTINCT BS.Id_lokalId FROM BBRSag AS BS
			WHERE
				(BS.registreringFra >= @PeriodeaendringFra AND BS.registreringFra <= @PeriodeaendringTil) 
				OR 
				(BS.registreringTil >= @PeriodeaendringFra AND BS.registreringTil <= @PeriodeaendringTil)
		)
		UNION
		SELECT DISTINCT SagsniveauChanges.byggesag FROM Sagsniveau AS SagsniveauChanges
		WHERE SagsniveauChanges.Id_lokalId IN
		(
			SELECT DISTINCT SN.id_lokalId FROM Sagsniveau AS SN
			WHERE 
				(SN.registreringFra >= @PeriodeaendringFra AND SN.registreringFra <= @PeriodeaendringTil)
				OR
				(SN.registreringTil >= @PeriodeaendringFra AND SN.registreringTil <= @PeriodeaendringTil)
		)
	)
	AND BBRSagSource.virkningTil = NULL
	AND
	(
		(
			@KunNyesteIPeriode = FALSE
			AND 
			BBRSagSource.registreringFra <= @PeriodeaendringFra AND (BBRSagSource.registreringTil > @PeriodeaendringFra OR BBRSagSource.registreringTil = NULL) 
			AND
			(
				SagsniveauSource.id_lokalId = NULL OR
				(
					SagsniveauSource.virkningTil = NULL AND
					SagsniveauSource.registreringFra <= @PeriodeaendringFra AND (SagsniveauSource.registreringTil > @PeriodeaendringFra OR SagsniveauSource.registreringTil = NULL) 
				)
			)	
		)
		OR
		(
			BBRSagSource.registreringFra <= @PeriodeaendringTil AND (BBRSagSource.registreringTil > @PeriodeaendringTil OR BBRSagSource.registreringTil = NULL) 
			AND 
			(
				SagsniveauSource.id_lokalId = NULL OR
				(
					SagsniveauSource.virkningTil = NULL AND
					SagsniveauSource.registreringFra <= @PeriodeaendringTil AND (SagsniveauSource.registreringTil > @PeriodeaendringTil OR SagsniveauSource.registreringTil = NULL)
				)
			)
		)
	)
))