SELECT DISTINCT * 
FROM EJENDOMSBELIGGENHED eb

WHERE (@Kommunekode IS NULL OR eb.KOMMUNEINDDELINGKOMMUNEKODE = @Kommunekode)

[snippet_bitemp_full_with_period(eb)]

AND (@Status IS NULL OR eb.STATUS = @Status)