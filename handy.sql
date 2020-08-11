select * from file_extract
where job_end is null;
;

-- This takes around 20 minutes:
-- Antal forretningsobjekter og forekomster
select 'BBR' as register, 'BBRSag' as table_name, count(distinct id_lokalId) as forretningsobjekter, count(*) as forekomster from BBRSag
union select 'BBR' as register, 'Bygning' as table_name, count(distinct id_lokalId) as forretningsobjekter, count(*) as forekomster from Bygning
union select 'BBR' as register, 'BygningEjendomsrelation' as table_name, count(distinct id_lokalId) as forretningsobjekter, count(*) as forekomster from BygningEjendomsrelation
union select 'BBR' as register, 'Ejendomsrelation' as table_name, count(distinct id_lokalId) as forretningsobjekter, count(*) as forekomster from Ejendomsrelation
union select 'BBR' as register, 'Enhed' as table_name, count(distinct id_lokalId) as forretningsobjekter, count(*) as forekomster from Enhed
union select 'BBR' as register, 'EnhedEjendomsrelation' as table_name, count(distinct id_lokalId) as forretningsobjekter, count(*) as forekomster from EnhedEjendomsrelation
union select 'BBR' as register, 'Etage' as table_name, count(distinct id_lokalId) as forretningsobjekter, count(*) as forekomster from Etage
union select 'BBR' as register, 'FordelingAfFordelingsareal' as table_name, count(distinct id_lokalId) as forretningsobjekter, count(*) as forekomster from FordelingAfFordelingsareal
union select 'BBR' as register, 'Fordelingsareal' as table_name, count(distinct id_lokalId) as forretningsobjekter, count(*) as forekomster from Fordelingsareal
union select 'BBR' as register, 'Grund' as table_name, count(distinct id_lokalId) as forretningsobjekter, count(*) as forekomster from Grund
union select 'BBR' as register, 'GrundJordstykke' as table_name, count(distinct id_lokalId) as forretningsobjekter, count(*) as forekomster from GrundJordstykke
union select 'BBR' as register, 'Opgang' as table_name, count(distinct id_lokalId) as forretningsobjekter, count(*) as forekomster from Opgang
union select 'BBR' as register, 'Sagsniveau' as table_name, count(distinct id_lokalId) as forretningsobjekter, count(*) as forekomster from Sagsniveau
union select 'BBR' as register, 'TekniskAnlæg' as table_name, count(distinct id_lokalId) as forretningsobjekter, count(*) as forekomster from TekniskAnlæg

union select 'DAR' as register, 'Adresse' as table_name, count(distinct id_lokalId) as forretningsobjekter, count(*) as forekomster from Adresse
union select 'DAR' as register, 'Adressepunkt' as table_name, count(distinct id_lokalId) as forretningsobjekter, count(*) as forekomster from Adressepunkt
union select 'DAR' as register, 'Husnummer' as table_name, count(distinct id_lokalId) as forretningsobjekter, count(*) as forekomster from Husnummer
union select 'DAR' as register, 'NavngivenVej' as table_name, count(distinct id_lokalId) as forretningsobjekter, count(*) as forekomster from NavngivenVej
union select 'DAR' as register, 'NavngivenVejKommunedel' as table_name, count(distinct id_lokalId) as forretningsobjekter, count(*) as forekomster from NavngivenVejKommunedel
union select 'DAR' as register, 'NavngivenVejPostnummer' as table_name, count(distinct id_lokalId) as forretningsobjekter, count(*) as forekomster from NavngivenVejPostnummer
union select 'DAR' as register, 'NavngivenVejSupplerendeBynavn' as table_name, count(distinct id_lokalId) as forretningsobjekter, count(*) as forekomster from NavngivenVejSupplerendeBynavn
union select 'DAR' as register, 'Postnummer' as table_name, count(distinct id_lokalId) as forretningsobjekter, count(*) as forekomster from Postnummer
union select 'DAR' as register, 'SupplerendeBynavn' as table_name, count(distinct id_lokalId) as forretningsobjekter, count(*) as forekomster from SupplerendeBynavn
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



