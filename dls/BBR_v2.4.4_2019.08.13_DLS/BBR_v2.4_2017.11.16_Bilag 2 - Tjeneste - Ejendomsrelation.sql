SELECT EjendomsrelationSource.* FROM Ejendomsrelation AS EjendomsrelationSource
WHERE (@Id = NULL OR EjendomsrelationSource.id_lokalId IN @Id)
AND (@VirkningFra = NULL OR EjendomsrelationSource.virkningTil = NULL OR @VirkningFra < EjendomsrelationSource.virkningTil) 
AND (@VirkningTil = NULL OR EjendomsrelationSource.virkningFra = NULL OR @VirkningTil >= EjendomsrelationSource.virkningFra)
AND (@Virkningsaktoer = NULL OR EjendomsrelationSource.virkningsaktør = @Virkningsaktoer)
AND (@RegistreringFra = NULL OR EjendomsrelationSource.registreringTil = NULL OR @RegistreringFra < EjendomsrelationSource.registreringTil)
AND (@RegistreringTil = NULL OR EjendomsrelationSource.registreringFra = NULL OR @RegistreringTil >= EjendomsrelationSource.registreringFra) 
AND (@Registreringsaktoer = NULL OR EjendomsrelationSource.registreringsaktør = @Registreringsaktoer)
AND (@Status = NULL OR EjendomsrelationSource.status IN @Status)
AND (@Forretningsproces = NULL OR EjendomsrelationSource.forretningsproces = @Forretningsproces)
AND (@Forretningsomraade = NULL OR EjendomsrelationSource.forretningsområde = @Forretningsomraade)
AND (@Forretningshaendelse = NULL OR EjendomsrelationSource.forretningshændelse = @Forretningshaendelse)
AND (@Kommunekode = NULL OR EjendomsrelationSource.Kommunekode = @Kommunekode)
AND (@DAFTimestampFra = NULL OR @DAFTimestampFra <= EjendomsrelationSource.UpdateTimestamp())
AND (@DAFTimestampTil = NULL OR @DAFTimestampTil > EjendomsrelationSource.UpdateTimestamp())
AND (@BFENummer = NULL OR EjendomsrelationSource.bfeNummer = @BFENummer)
AND (@BPFG = NULL OR EjendomsrelationSource.bygningPåFremmedGrund = @BPFG)
AND (@Ejerforholdskode = NULL OR EjendomsrelationSource.ejendommensEjerforholdskode = @Ejerforholdskode)
AND (@Ejerlejlighed = NULL OR EjendomsrelationSource.ejerlejlighed = @Ejerlejlighed)
AND (@Ejendomsnummer = NULL OR EjendomsrelationSource.ejendomsnummer = @Ejendomsnummer)
AND (@SamletFastEjendom = NULL OR EjendomsrelationSource.samletFastEjendom = @SamletFastEjendom)
AND (@Vurderingsejendomsnummer = NULL OR EjendomsrelationSource.vurderingsejendomsnummer = @Vurderingsejendomsnummer)
AND (
	@PeriodeaendringFra = NULL 
	OR
	@PeriodeaendringTil = NULL
	OR (
	EjendomsrelationSource.id_lokalId IN
	(
		SELECT DISTINCT ER.id_lokalId FROM EjendomsRelation AS ER
		WHERE
		(
			(ER.registreringFra >= @PeriodeaendringFra AND ER.registreringFra <= @PeriodeaendringTil) 
			OR 
			(ER.registreringTil >= @PeriodeaendringFra AND ER.registreringTil <= @PeriodeaendringTil)
		)
	)
	AND EjendomsrelationSource.virkningTil = NULL
	AND 
	(
		(@KunNyesteIPeriode = FALSE AND EjendomsrelationSource.registreringFra <= @PeriodeaendringFra AND (EjendomsrelationSource.registreringTil > @PeriodeaendringFra OR EjendomsrelationSource.registreringTil = NULL))
		OR 
		(EjendomsrelationSource.registreringFra <= @PeriodeaendringTil AND (EjendomsrelationSource.registreringTil > @PeriodeaendringTil OR EjendomsrelationSource.registreringTil = NULL))
	)
))