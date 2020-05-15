SELECT * FROM [TABLE] AS TableSource
WHERE (@VirkningFra = NULL OR TableSource.virkningTil = NULL OR @VirkningFra < TableSource.virkningTil) 
AND (@VirkningTil = NULL OR TableSource.virkningFra = NULL OR @VirkningTil >= TableSource.virkningFra)
AND (@RegistreringFra = NULL OR TableSource.registreringTil = NULL OR @RegistreringFra < TableSource.registreringTil)
AND (@RegistreringTil = NULL OR TableSource.registreringFra = NULL OR @RegistreringTil >= TableSource.registreringFra)
AND (@Status = NULL OR TableSource.status IN @Status) 
