SELECT * FROM [TABLE] AS TableSource
WHERE (@VirkningFra = NULL OR TableSource.virkningTil = NULL OR @VirkningFra < TableSource.virkningTil) 
AND (@VirkningTil = NULL OR TableSource.virkningFra = NULL OR @VirkningTil >= TableSource.virkningFra)
AND (@RegistreringFra = NULL OR TableSource.registreringTil = NULL OR @RegistreringFra < TableSource.registreringTil)
AND (@RegistreringTil = NULL OR TableSource.registreringFra = NULL OR @RegistreringTil >= TableSource.registreringFra)
AND (@Kommunekode = NULL OR @Kommunekode = TableSource.kommunekode) 
AND (@Status = NULL OR TableSource.status IN @Status) 
AND (
	@PeriodeaendringFra = NULL 
	OR
	@PeriodeaendringTil = NULL
	OR (
		TableSource.id_lokalId IN
		(
			SELECT DISTINCT changes.id_lokalId FROM [TABLE] AS changes
			WHERE
			(
				(changes.registreringFra >= @PeriodeaendringFra AND changes.registreringFra <= @PeriodeaendringTil) 
				OR 
				(changes.registreringTil >= @PeriodeaendringFra AND changes.registreringTil <= @PeriodeaendringTil)
			)
		)
		AND TableSource.virkningTil = NULL
		AND 
		(
			(@KunNyesteIPeriode = FALSE AND TableSource.registreringFra <= @PeriodeaendringFra AND (TableSource.registreringTil > @PeriodeaendringFra OR TableSource.registreringTil = NULL))
			OR 
			(TableSource.registreringFra <= @PeriodeaendringTil AND (TableSource.registreringTil > @PeriodeaendringTil OR TableSource.registreringTil = NULL))
		)
	)
)
