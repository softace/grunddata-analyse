--
-- Applies bitemporal point-in-time constraints.
--
-- [table_alias] - The name of the table the constraints are applied to.
--
[def:snippet_bitemp_full(table_alias)]
AND [table_alias].REGISTRERINGFRA <= @Registreringstid AND ([table_alias].REGISTRERINGTIL IS NULL OR [table_alias].REGISTRERINGTIL > @Registreringstid)
AND [table_alias].VIRKNINGFRA <= @Virkningstid AND ([table_alias].VIRKNINGTIL IS NULL OR [table_alias].VIRKNINGTIL > @Virkningstid)

--
-- Applies bitemporal point-in-time constraints if a certain column contains a
-- non-null value. This is used when af table is left joined and the columns may
-- be empty if no relation exists. The check column is a mandotory non-null
-- column, which means that its absence always indicates that there's no
-- relation.
--
-- [table_alias]  - The name of the table the constraints are applied to.
-- [check_column] - The name of a mandatory column used to check existence of 
--                  the relation.
--
[def:snippet_bitemp_full_optional(table_alias, check_column)]
AND ([table_alias].[check_column] IS NULL -- Ignore the following constraints if the check column is NULL.
    OR ([table_alias].REGISTRERINGFRA <= @Registreringstid AND ([table_alias].REGISTRERINGTIL IS NULL OR [table_alias].REGISTRERINGTIL > @Registreringstid)
    AND [table_alias].VIRKNINGFRA <= @Virkningstid AND ([table_alias].VIRKNINGTIL IS NULL OR [table_alias].VIRKNINGTIL > @Virkningstid)))

--
-- Applies bitemporal point-in-time constraints if a certain column contains a
-- non-null value. This only applies constraints for virkning and is used when
-- joining table from CPR, which do not include registrering. This is used when 
-- a table is left joined and the columns may be empty if no relation exists. 
--
-- [table_alias]  - The name of the table the constraints are applied to.
--
[def:snippet_bitemp_virk(table_alias)]
AND [table_alias].VIRKNINGFRA <= @Virkningstid AND ([table_alias].VIRKNINGTIL IS NULL OR [table_alias].VIRKNINGTIL > @Virkningstid)

--
-- Applies bitemporal point-in-time constraints if a certain column contains a
-- non-null value. This only applies constraints for virkning and is used when
-- joining table from CPR, which do not include registrering. This is used when 
-- a table is left joined and the columns may be empty if no relation exists. 
-- The check column is a mandotory non-null column, which means that its absence
-- always indicates that there's no relation.
--
-- [table_alias]  - The name of the table the constraints are applied to.
-- [check_column] - The name of a mandatory column used to check existence of
--                  the relation.
--
[def:snippet_bitemp_virk_optional(table_alias, check_column)]
AND ([table_alias].[check_column] IS NULL -- Ignore the following constraints if the check column is NULL.
    OR ([table_alias].VIRKNINGFRA <= @Virkningstid AND ([table_alias].VIRKNINGTIL IS NULL OR [table_alias].VIRKNINGTIL > @Virkningstid)))

--
-- Applies bitemporal constraints for point-in-time as well as period queries. 
-- If a either period bound (to/from) is set, the point-in-time contraints are 
-- ignored. If neither period bound is set, the period constraints are ignored.
-- This works independently for virkning and registrering, such that a point-in-
-- time registrering (@Registreringstid) can be used with a period for virkning
-- or vice versa.
--
-- [table_alias] - The name of the table the constraints are applied to.
--
[def:snippet_bitemp_full_with_period(table_alias)]
AND ((@RegistreringstidFra IS NOT NULL OR @RegistreringstidTil IS NOT NULL) -- Ignore the following constraints if either @RegistreringstidFra or @RegistreringstidTil is set
    OR ([table_alias].REGISTRERINGFRA <= @Registreringstid AND ([table_alias].REGISTRERINGTIL IS NULL OR [table_alias].REGISTRERINGTIL > @Registreringstid)))
AND ((@VirkningstidFra IS NOT NULL OR @VirkningstidTil IS NOT NULL) -- Ignore the following constraints if either @VirkningstidFra or @VirkningstidTil is set
    OR ([table_alias].VIRKNINGFRA <= @Virkningstid AND ([table_alias].VIRKNINGTIL IS NULL OR [table_alias].VIRKNINGTIL > @Virkningstid)))
AND ((@RegistreringstidFra IS NULL AND @RegistreringstidTil IS NULL) -- Ignore the following constraints if neither @RegistreringstidFra nor @RegistreringstidTil is set
    OR  (@RegistreringstidFra < @RegistreringstidTil -- Return nothing if specified period is invalid (including if either is NULL)
    AND ([table_alias].REGISTRERINGTIL > @RegistreringstidFra OR [table_alias].REGISTRERINGTIL IS NULL)
    AND  [table_alias].REGISTRERINGFRA < @RegistreringstidTil))
AND ((@VirkningstidFra IS NULL AND @VirkningstidTil IS NULL)  -- Ignore the following constraints if neither @RegistreringstidFra nor @RegistreringstidTil is set
    OR  (@VirkningstidFra < @VirkningstidTil -- Return nothing if specified period is invalid (including if either is NULL)
    AND ([table_alias].VIRKNINGTIL > @VirkningstidFra OR [table_alias].VIRKNINGTIL IS NULL)
    AND  [table_alias].VIRKNINGFRA < @VirkningstidTil))