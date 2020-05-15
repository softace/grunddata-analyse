SELECT EnhedSource.*, FordelingsarealSource.*, Ejerlejlighed.* FROM Enhed AS EnhedSource
LEFT JOIN FordelingAfFordelingsareal AS FordelingAfFordelingsarealSource ON FordelingAfFordelingsarealSource.enhed = EnhedSource.id_lokalId
LEFT JOIN Fordelingsareal AS FordelingsarealSource ON FordelingAfFordelingsarealSource.fordelingsareal = FordelingsarealSource.id_lokalId
LEFT JOIN EnhedEjendomsrelation AS EnhedEjendomsrelationSource ON EnhedEjendomsrelationSource.enhed = EnhedSource.id_lokalId
LEFT JOIN Ejendomsrelation AS Ejerlejlighed ON EnhedEjendomsrelationSource.ejerlejlighed = Ejendomsrelation.id_lokalId
WHERE (@Id = NULL OR EnhedSource.id_lokalId IN @Id)
AND (@VirkningFra = NULL OR EnhedSource.virkningTil = NULL OR @VirkningFra < EnhedSource.virkningTil) 
AND (@VirkningTil = NULL OR EnhedSource.virkningFra = NULL OR @VirkningTil >= EnhedSource.virkningFra)
AND (@Virkningsaktoer = NULL OR EnhedSource.virkningsaktør = @Virkningsaktoer)
AND (@RegistreringFra = NULL OR EnhedSource.registreringTil = NULL OR @RegistreringFra < EnhedSource.registreringTil)
AND (@RegistreringTil = NULL OR EnhedSource.registreringFra = NULL OR @RegistreringTil >= EnhedSource.registreringFra) 
AND (@Registreringsaktoer = NULL OR EnhedSource.registreringsaktør = @Registreringsaktoer)
AND (@Status = NULL OR EnhedSource.status IN @Status)
AND (@Forretningsproces = NULL OR EnhedSource.forretningsproces = @Forretningsproces)
AND (@Forretningsomraade = NULL OR EnhedSource.forretningsområde = @Forretningsomraade)
AND (@Forretningshaendelse = NULL OR EnhedSource.forretningshændelse = @Forretningshaendelse)
AND (@Kommunekode = NULL OR EnhedSource.Kommunekode = @Kommunekode)
AND (@DAFTimestampFra = NULL OR @DAFTimestampFra <= EnhedSource.UpdateTimestamp())
AND (@DAFTimestampTil = NULL OR @DAFTimestampTil > EnhedSource.UpdateTimestamp())
AND (@Ejendomsrelation = NULL OR EnhedSource.id_lokalId in (SELECT EnhedEjendomsrelationInner.enhed FROM EnhedEjendomsrelation AS EnhedEjendomsrelationInner WHERE EnhedEjendomsrelationInner.ejerlejlighed = @Ejendomsrelation))
AND (@Opgang = NULL OR EnhedSource.opgang IN @Opgang)
AND (@AdresseIdentificerer = NULL OR EnhedSource.adresseIdentificerer = @AdresseIdentificerer)
AND (@Etage = NULL OR EnhedSource.etage IN @Etage)
AND (@Fordelingsareal = NULL OR EnhedSource.id_lokalId IN (SELECT FordelingAfFordelingsarealInner.enhed FROM FordelingAfFordelingsareal AS FordelingAfFordelingsarealInner WHERE FordelingAfFordelingsarealInner.fordelingsareal = @Fordelingsareal))
AND (@TekniskAnlaeg = NULL OR EnhedSource.id_lokalId IN (SELECT TekniskAnlægInner.enhed FROM TekniskAnlæg AS TekniskAnlægInner WHERE TekniskAnlægInner.id_lokalId IN @TekniskAnlaeg))
AND (@BFENummer = NULL OR Ejerlejlighed.bfeNummer = @BFENummer)
AND (@Bygning = NULL OR EnhedSource.Opgang IN (SELECT Opgang.id_lokalId FROM Opgang WHERE Opgang.Bygning IN @Bygning)
AND (
	@PeriodeaendringFra = NULL
	OR
	@PeriodeaendringTil = NULL
	OR (
	EnhedSource.id_lokalId In 
	(
		SELECT DISTINCT EnhedChanges.id_lokalId FROM Enhed AS EnhedChanges
		WHERE EnhedChanges.id_lokalId IN
		(
			SELECT DISTINCT E.id_lokalId FROM Enhed AS E
			WHERE
			(
				(E.registreringFra >= @PeriodeaendringFra AND E.registreringFra <= @PeriodeaendringTil) 
				OR 
				(E.registreringTil >= @PeriodeaendringFra AND E.registreringTil <= @PeriodeaendringTil)
			)
		)
		UNION 
		SELECT DISTINCT FordelingAfFordelingsarealChanges.enhed FROM FordelingAfFordelingsareal AS FordelingAfFordelingsarealChanges
		WHERE FordelingAfFordelingsarealChanges.id_lokalId IN
		(
			SELECT DISTINCT FFA.id_lokalId FROM FordelingAfFordelingsareal FFA
			WHERE 
			(
				(FFA.registreringFra >= @PeriodeaendringFra AND FFA.registreringFra <= @PeriodeaendringTil) 
				OR 
				(FFA.registreringTil >= @PeriodeaendringFra AND FFA.registreringTil <= @PeriodeaendringTil)
			)
		)
		UNION
		SELECT DISTINCT FordelingAfFordelingsarealChanges.enhed FROM FordelingAfFordelingsareal AS FordelingAfFordelingsarealChanges
		WHERE FordelingAfFordelingsarealChanges.Fordelingsareal IN
		(
			SELECT DISTINCT FA.id_lokalId FROM Fordelingsareal FA
			WHERE 
			(
				(FA.registreringFra >= @PeriodeaendringFra AND FA.registreringFra <= @PeriodeaendringTil) 
				OR 
				(FA.registreringTil >= @PeriodeaendringFra AND FA.registreringTil <= @PeriodeaendringTil)
			)
		)
		UNION
		SELECT DISTINCT EnhedEjendomsRelationRelationChanges.enhed FROM EnhedEjendomsRelationRelation AS EnhedEjendomsRelationRelationChanges
		WHERE EnhedEjendomsRelationRelationChanges.id_lokalId IN
		(
			SELECT DISTINCT EER.id_lokalId FROM EnhedEjendomsRelationRelation AS EER
			WHERE 
			(
				(EER.registreringFra >= @PeriodeaendringFra AND EER.registreringFra <= @PeriodeaendringTil) 
				OR 
				(EER.registreringTil >= @PeriodeaendringFra AND EER.registreringTil <= @PeriodeaendringTil)
			)
		)
		UNION
		SELECT DISTINCT EnhedEjendomsRelationRelationChanges.enhed FROM EnhedEjendomsRelationRelation AS EnhedEjendomsRelationRelationChanges
		WHERE EnhedEjendomsRelationRelationChanges.EjendomsRelation IN
		(
			SELECT DISTINCT ER.id_lokalId FROM EjendomsRelation AS ER
			WHERE 
			(
				(ER.registreringFra >= @PeriodeaendringFra AND ER.registreringFra <= @PeriodeaendringTil) 
				OR 
				(ER.registreringTil >= @PeriodeaendringFra AND ER.registreringTil <= @PeriodeaendringTil)
			)
		)
	)
	AND EnhedSource.virkningTil = NULL
	AND
	(
		(
			@KunNyesteIPeriode = FALSE
			AND 
			EnhedSource.registreringFra <= @PeriodeaendringFra AND (EnhedSource.registreringTil > @PeriodeaendringFra OR EnhedSource.registreringTil = NULL) 
			AND
			(
				FordelingAfFordelingsarealSource.id_lokalId = NULL OR
				(
					FordelingAfFordelingsarealSource.virkningTil = NULL AND
					FordelingAfFordelingsarealSource.registreringFra <= @PeriodeaendringFra AND (FordelingAfFordelingsarealSource.registreringTil > @PeriodeaendringFra OR FordelingAfFordelingsarealSource.registreringTil = NULL) 
				)
			)	
			AND
			(
				FordelingsarealSource.id_lokalId = NULL OR
				(
					FordelingsarealSource.virkningTil = NULL AND
					FordelingsarealSource.registreringFra <= @PeriodeaendringFra AND (FordelingsarealSource.registreringTil > @PeriodeaendringFra OR FordelingsarealSource.registreringTil = NULL) 
				)
			)	
			AND
			(
				EnhedEjendomsrelationSource.id_lokalId = NULL OR
				(
					EnhedEjendomsrelationSource.virkningTil = NULL AND
					EnhedEjendomsrelationSource.registreringFra <= @PeriodeaendringFra AND (EnhedEjendomsrelationSource.registreringTil > @PeriodeaendringFra OR EnhedEjendomsrelationSource.registreringTil = NULL) 
				)
			)	
			AND
			(
				Ejerlejlighed.id_lokalId = NULL OR
				(
					Ejerlejlighed.virkningTil = NULL AND
					Ejerlejlighed.registreringFra <= @PeriodeaendringFra AND (Ejerlejlighed.registreringTil > @PeriodeaendringFra OR Ejerlejlighed.registreringTil = NULL) 
				)
			)	
		)
		OR
		(
			EnhedSource.registreringFra <= @PeriodeaendringTil AND (EnhedSource.registreringTil > @PeriodeaendringTil OR EnhedSource.registreringTil = NULL) 
			AND
			(
				FordelingAfFordelingsarealSource.id_lokalId = NULL OR
				(
					FordelingAfFordelingsarealSource.virkningTil = NULL AND
					FordelingAfFordelingsarealSource.registreringFra <= @PeriodeaendringTil AND (FordelingAfFordelingsarealSource.registreringTil > @PeriodeaendringTil OR FordelingAfFordelingsarealSource.registreringTil = NULL) 
				)
			)	
			AND
			(
				FordelingsarealSource.id_lokalId = NULL OR
				(
					FordelingsarealSource.virkningTil = NULL AND
					FordelingsarealSource.registreringFra <= @PeriodeaendringTil AND (FordelingsarealSource.registreringTil > @PeriodeaendringTil OR FordelingsarealSource.registreringTil = NULL) 
				)
			)	
			AND
			(
				EnhedEjendomsrelationSource.id_lokalId = NULL OR
				(
					EnhedEjendomsrelationSource.virkningTil = NULL AND
					EnhedEjendomsrelationSource.registreringFra <= @PeriodeaendringTil AND (EnhedEjendomsrelationSource.registreringTil > @PeriodeaendringTil OR EnhedEjendomsrelationSource.registreringTil = NULL) 
				)
			)	
			AND
			(
				Ejerlejlighed.id_lokalId = NULL OR
				(
					Ejerlejlighed.virkningTil = NULL AND
					Ejerlejlighed.registreringFra <= @PeriodeaendringTil AND (Ejerlejlighed.registreringTil > @PeriodeaendringTil OR Ejerlejlighed.registreringTil = NULL) 
				)
			)	
		)
	)
))
