SELECT * 
FROM EJENDOMSBELIGGENHED eb
WHERE (@EBId IS NULL OR eb.ID_LOKALID IN @EBId) 
AND (@BFEnr IS NOT NULL OR @EBId IS NOT NULL)
AND (@BFEnr IS NULL OR eb.BESTEMTFASTEJENDOMLOKALID IN @BFEnr)

[snippet_bitemp_full_with_period(eb)]

AND (@Status IS NULL OR eb.STATUS = @Status)