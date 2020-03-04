SELECT BygningSource.*, OpgangSource.*, EtageSource.*, FordelingsarealSource.*, BygningPÂFremmedGrund.*, Ejerlejlighed.* FROM Bygning AS BygningSource
LEFT JOIN Opgang AS OpgangSource ON OpgangSource.bygning = BygningSource.id_lokalId
LEFT JOIN Etage AS EtageSource ON EtageSource.bygning = BygningSource.id_lokalId
LEFT JOIN Fordelingsareal AS FordelingsarealSource ON FordelingsarealSource.bygning = BygningSource.id_lokalId
LEFT JOIN BygningEjendomsrelation AS BygningEjendomsrelationSource ON BygningSource.id_lokalId = BygningEjendomsrelationSource.bygning
LEFT JOIN Ejendomsrelation AS BygningPÂFremmedGrund ON BygningEjendomsrelationSource.bygningPÂFremmedGrund =  BygningPÂFremmedGrund.id_lokalId 
LEFT JOIN Ejendomsrelation AS Ejerlejlighed ON BygningSource.ejerlejlighed = Ejerlejlighed.id_lokalId
WHERE (@Id = NULL OR BygningSource.id_lokalId IN @Id)
AND (@VirkningFra = NULL OR BygningSource.virkningTil = NULL OR @VirkningFra < BygningSource.virkningTil) 
AND (@VirkningTil = NULL OR BygningSource.virkningFra = NULL OR @VirkningTil >= BygningSource.virkningFra)
AND (@Virkningsaktoer = NULL OR BygningSource.virkningsakt¯r = @Virkningsaktoer)
AND (@RegistreringFra = NULL OR BygningSource.registreringTil = NULL OR @RegistreringFra < BygningSource.registreringTil)
AND (@RegistreringTil = NULL OR BygningSource.registreringFra = NULL OR @RegistreringTil >= BygningSource.registreringFra) 
AND (@Registreringsaktoer = NULL OR BygningSource.registreringsakt¯r = @Registreringsaktoer)
AND (@Status = NULL OR BygningSource.status IN @Status)
AND (@Forretningsproces = NULL OR BygningSource.forretningsproces = @Forretningsproces)
AND (@Forretningsomraade = NULL OR BygningSource.forretningsomrÂde = @Forretningsomraade)
AND (@Forretningshaendelse = NULL OR BygningSource.forretningshÊndelse = @Forretningshaendelse)
AND (@Kommunekode = NULL OR BygningSource.Kommunekode = @Kommunekode)
AND (@DAFTimestampFra = NULL OR @DAFTimestampFra <= BygningSource.UpdateTimestamp())
AND (@DAFTimestampTil = NULL OR @DAFTimestampTil > BygningSource.UpdateTimestamp())
AND (@Grund = NULL OR BygningSource.grund = @Grund)
AND (@Jordstykke = NULL OR BygningSource.jordstykke = @Jordstykke)
AND (@Husnummer = NULL OR BygningSource.husnummer = @Husnummer)
AND (@Husnummer = NULL OR BygningSource.husnummer = @Husnummer)
AND (@BFENummer = NULL OR Ejerlejlighed.bfeNummer = @BFENummer OR BygningPÂFremmedGrund.bfeNummer = @BFENummer)
AND (@Nord = NULL OR @Syd = NULL OR @Oest = NULL OR @Vest = NULL OR Point(Bygning.byg404Koordinat) WITHIN boundingbox(@Vest,@Nord,@Oest,@Syd))
AND (@Ejendomsrelation = NULL OR BygningEjendomsrelationSource.bygningPÂFremmedGrund = @Ejendomsrelation OR BygningSource.ejerlejlighed = @Ejendomsrelation)
AND (@TekniskAnlaeg = NULL OR BygningSource.id_lokalId in (SELECT TekniskAnlÊgInner.bygning FROM TekniskAnlÊg AS TekniskAnlÊgInner WHERE TekniskAnlÊgInner.id_lokalId = @TekniskAnlaeg))
AND (@Opgang = NULL OR BygningSource.id_lokalId in (SELECT OpgangInner.bygning FROM Opgang AS OpgangInner WHERE OpgangInner.id_lokalId IN @Opgang))
AND (@Fordelingsareal = NULL OR BygningSource.id_lokalId in (SELECT FordelingsarealInner.bygning FROM Fordelingsareal AS FordelingsarealInner WHERE FordelingsarealInner.id_lokalId = @Fordelingsareal))
AND (@Etage = NULL OR BygningSource.id_lokalId in (SELECT EtageInner.bygning FROM Etage AS EtageInner WHERE EtageInner.id_lokalId IN @Etage))
AND (
	@PeriodeaendringFra = NULL
	OR
	@PeriodeaendringTil = NULL
	OR (
	BygningSource.id_lokalId IN 
		(
			SELECT DISTINCT BygningChanges.id_lokalId FROM Bygning AS BygningChanges
			WHERE BygningChanges.id_lokalId IN
			(
				SELECT B.id_lokalId FROM Bygning AS B
				WHERE
				(B.registreringFra >= @PeriodeaendringFra AND B.registreringFra <= @PeriodeaendringTil) 
				OR 
				(B.registreringTil >= @PeriodeaendringFra AND B.registreringTil <= @PeriodeaendringTil)
			)
			UNION 
			SELECT DISTINCT OpgangChanges.bygning FROM Opgang AS OpgangChanges
			WHERE OpgangChanges.id_lokalId IN
			(
				SELECT O.id_lokalId FROM Opgang AS O
				WHERE
				(O.registreringFra >= @PeriodeaendringFra AND O.registreringFra <= @PeriodeaendringTil) 
				OR 
				(O.registreringTil >= @PeriodeaendringFra AND O.registreringTil <= @PeriodeaendringTil)
			) 
			UNION 
			SELECT DISTINCT EtageChanges.bygning FROM Etage AS EtageChanges
			WHERE EtageChanges.id_lokalId IN
			(
				SELECT E.id_lokalId FROM Etage AS E
				WHERE
				(E.registreringFra >= @PeriodeaendringFra AND E.registreringFra <= @PeriodeaendringTil) 
				OR 
				(E.registreringTil >= @PeriodeaendringFra AND E.registreringTil <= @PeriodeaendringTil)
			) 
			UNION 
			SELECT DISTINCT FordelingsarealChanges.bygning FROM Fordelingsareal AS FordelingsarealChanges
			WHERE FordelingsarealChanges.id_lokalId IN
			(
				SELECT FA.id_lokalId FROM Fordelingsareal AS FA
				WHERE
				(FA.registreringFra >= @PeriodeaendringFra AND FA.registreringFra <= @PeriodeaendringTil) 
				OR 
				(FA.registreringTil >= @PeriodeaendringFra AND FA.registreringTil <= @PeriodeaendringTil)
			) 
			UNION 
			SELECT DISTINCT BygningEjendomsRelationChanges.bygning FROM BygningEjendomsRelation AS BygningEjendomsRelationChanges
			WHERE BygningEjendomsRelationChanges.id_lokalId IN
			(
				SELECT BER.id_lokalId FROM BygningEjendomsRelation AS BER
				WHERE
				(BER.registreringFra >= @PeriodeaendringFra AND BER.registreringFra <= @PeriodeaendringTil) 
				OR 
				(BER.registreringTil >= @PeriodeaendringFra AND BER.registreringTil <= @PeriodeaendringTil)
			)
			UNION 
			SELECT DISTINCT BygningEjendomsRelation.bygning FROM BygningEjendomsRelation AS BygningEjendomsRelationChanges
			WHERE BygningEjendomsRelation.bygningPÂFremmedGrund IN
			(
				SELECT ER.id_lokalId FROM EjendomsRelation AS ER
				WHERE
				(ER.registreringFra >= @PeriodeaendringFra AND ER.registreringFra <= @PeriodeaendringTil) 
				OR 
				(ER.registreringTil >= @PeriodeaendringFra AND ER.registreringTil <= @PeriodeaendringTil)
			)
			UNION 
			SELECT DISTINCT BygningChanges.Ejerlejlighed FROM Bygning AS BygningChanges
			WHERE BygningChanges.Ejerlejlighed IN
			(
				SELECT ER.id_lokalId FROM EjendomsRelation AS ER
				WHERE
				(ER.registreringFra >= @PeriodeaendringFra AND ER.registreringFra <= @PeriodeaendringTil) 
				OR 
				(ER.registreringTil >= @PeriodeaendringFra AND ER.registreringTil <= @PeriodeaendringTil)
			)
		)
	AND BygningSource.virkningTil = NULL
	AND 
	(
		(
			@KunNyesteIPeriode = FALSE
			AND 
			BygningSource.registreringFra <= @PeriodeaendringFra AND (BygningSource.registreringTil > @PeriodeaendringFra OR BygningSource.registreringTil = NULL) 
			AND
			(
				OpgangSource.id_lokalId = NULL OR
				(
					OpgangSource.virkningTil = NULL AND
					OpgangSource.registreringFra <= @PeriodeaendringFra AND (OpgangSource.registreringTil > @PeriodeaendringFra OR OpgangSource.registreringTil = NULL) 
				)
			)	
			AND
			(
				EtageSource.id_lokalId = NULL OR
				(
					EtageSource.virkningTil = NULL AND
					EtageSource.registreringFra <= @PeriodeaendringFra AND (EtageSource.registreringTil > @PeriodeaendringFra OR EtageSource.registreringTil = NULL) 
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
				BygningEjendomsRelationSource.id_lokalId = NULL OR
				(
					BygningEjendomsRelationSource.virkningTil = NULL AND
					BygningEjendomsRelationSource.registreringFra <= @PeriodeaendringFra AND (BygningEjendomsRelationSource.registreringTil > @PeriodeaendringFra OR BygningEjendomsRelationSource.registreringTil = NULL) 
				)
			)	
			AND
			(
				BygningPÂFremmedGrund.id_lokalId = NULL OR
				(
					BygningPÂFremmedGrund.virkningTil = NULL AND
					BygningPÂFremmedGrund.registreringFra <= @PeriodeaendringFra AND (BygningPÂFremmedGrund.registreringTil > @PeriodeaendringFra OR BygningPÂFremmedGrund.registreringTil = NULL) 
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
			BygningSource.registreringFra <= @PeriodeaendringTil AND (BygningSource.registreringTil > @PeriodeaendringTil OR BygningSource.registreringTil = NULL) 
			AND
			(
				OpgangSource.id_lokalId = NULL OR
				(
					OpgangSource.virkningTil = NULL AND
					OpgangSource.registreringFra <= @PeriodeaendringTil AND (OpgangSource.registreringTil > @PeriodeaendringTil OR OpgangSource.registreringTil = NULL) 
				)
			)	
			AND
			(
				EtageSource.id_lokalId = NULL OR
				(
					EtageSource.virkningTil = NULL AND
					EtageSource.registreringFra <= @PeriodeaendringTil AND (EtageSource.registreringTil > @PeriodeaendringTil OR EtageSource.registreringTil = NULL) 
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
				BygningEjendomsRelationSource.id_lokalId = NULL OR
				(
					BygningEjendomsRelationSource.virkningTil = NULL AND
					BygningEjendomsRelationSource.registreringFra <= @PeriodeaendringTil AND (BygningEjendomsRelationSource.registreringTil > @PeriodeaendringTil OR BygningEjendomsRelationSource.registreringTil = NULL) 
				)
			)	
			AND
			(
				BygningPÂFremmedGrund.id_lokalId = NULL OR
				(
					BygningPÂFremmedGrund.virkningTil = NULL AND
					BygningPÂFremmedGrund.registreringFra <= @PeriodeaendringTil AND (BygningPÂFremmedGrund.registreringTil > @PeriodeaendringTil OR BygningPÂFremmedGrund.registreringTil = NULL) 
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