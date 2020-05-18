select * from violation_log;

-- Adresse,
-- Adressepunkt,
-- BBRSag,
-- Bygning,
-- Ejendomsrelation,
-- Enhed,
-- EnhedEjendomsrelation,
-- Etage,
-- FordelingAfFordelingsareal,
-- Fordelingsareal,
-- Grund,
-- GrundJordstykke,
-- Husnummer,
-- NavngivenVej,
-- NavngivenVejKommunedel,
-- NavngivenVejPostnummer,
-- NavngivenVejSupplerendeBynavn,
-- Opgang,
-- Sagsniveau,
-- SupplerendeBynavn,
-- TekniskAnlæg,

-- Optælling af fejl
select substr(file_extract.metadata_file_name, 1, 3) as register, violation_log.table_name, violation_log.violation_type, count(*) as antal_fejl
from file_extract
join violation_log on file_extract.id = file_extract_id
group by register, violation_log.table_name, violation_log.violation_type
order by register, violation_type, table_name
;


-- Overlappende forekomster
select ent1.id_lokalId, ent1.registreringFra as ent1_registreringFra, ent1.registreringTil as ent1_registreringTil,
       ent2.registreringFra as ent2_registreringFra, ent2.registreringTil as ent2_registreringTil,
       ent1.virkningFra as ent1_virkningFra, ent1.virkningTil as ent1_virkningTil,
       ent2.virkningFra as ent2_virkningFra, ent2.virkningTil as ent2_virkningTil
from Enhed ent1
join Enhed ent2 on ent1.id_lokalId = ent2.id_lokalId
and ent1.registreringFra < ent2.registreringFra
and ent1.virkningFra != ent2.virkningFra
                       AND ((       ent1.registreringFra_UTC   <= ent2.registreringFra_UTC
                             AND (ent2.registreringFra_UTC <    ent1.registreringTil_UTC   OR   ent1.registreringTil_UTC is NULL))
                         OR (     ent2.registreringFra_UTC <=   ent1.registreringFra_UTC
                             AND (  ent1.registreringFra_UTC   <  ent2.registreringTil_UTC OR ent2.registreringTil_UTC is NULL))
                           )
                       AND ((       ent1.virkningFra_UTC   <= ent2.virkningFra_UTC
                             AND (ent2.virkningFra_UTC <    ent1.virkningTil_UTC   OR   ent1.virkningTil_UTC is NULL))
                         OR (     ent2.virkningFra_UTC <=   ent1.virkningFra_UTC
                             AND (  ent1.virkningFra_UTC   <  ent2.virkningTil_UTC OR ent2.virkningTil_UTC is NULL))
                           )
;



