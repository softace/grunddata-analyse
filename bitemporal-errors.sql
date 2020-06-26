select * from file_extract
where substr(zip_file_name,1,3) = 'DAR';

select count(*)
from violation_log
;

select violation_log.table_name, count(*)
from violation_log
group by violation_log.table_name
;

select distinct substr(file_extract.metadata_file_name, 1, 3) as register,
       violation_log.id,
       violation_log.table_name,
       violation_log.violation_type,
       ent.id_lokalId,
       ent.registreringFra,
       ent.registreringTil,
       ent.virkningFra,
       ent.virkningTil
from violation_log
         join file_extract on violation_log.file_extract_id = file_extract.id
         join Etage ent on ent.id_lokalId = violation_log.id_lokalId
    and ent.registreringFra_UTC = violation_log.registreringFra_UTC
    and ent.virkningFra_UTC = violation_log.virkningFra_UTC
    and 'Etage' = violation_log.table_name
;
select table_name, count(*) from (
                         select distinct substr(file_extract.metadata_file_name, 1, 3) as register,
                                       violation_log.file_extract_id, violation_log.table_name, violation_log.id_lokalId, violation_log.registreringFra_UTC, violation_log.virkningFra_UTC, violation_log.violation_type, violation_log.violation_text, violation_log.conflicting_registreringFra_UTC, violation_log.conflicting_virkningFra_UTC,
violation_log.table_name,
                                violation_log.violation_type,
                                ent.id_lokalId,
                                ent.registreringFra,
                                ent.registreringTil,
                                ent.virkningFra,
                                ent.virkningTil
                         from violation_log
                                  join file_extract on violation_log.file_extract_id = file_extract.id
                                  join Etage ent on ent.id_lokalId = violation_log.id_lokalId
                             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                             and 'Etage' = violation_log.table_name
                     )
where table_name = 'Etage'
;


select register, table_name, count(*) as bitemporal_fejl , count(*) - count(coalesce(registreringTil, virkningTil, NULL)) as 'aktive', (count(*) - count(coalesce(registreringTil, virkningTil, NULL)) + 0.0)/count(*) as andel
         from (
                  select substr(file_extract.metadata_file_name, 1, 3) as register,
                         violation_log.table_name,
                         violation_log.violation_type,
                         violation_log.conflicting_registreringFra_UTC,
                         violation_log.conflicting_virkningFra_UTC,
                         ent.id_lokalId,
                         ent.registreringFra,
                         ent.registreringTil,
                         ent.virkningFra,
                         ent.virkningTil
                  from violation_log
                           join file_extract on violation_log.file_extract_id = file_extract.id
                           join Adresse ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                      and 'Adresse' = violation_log.table_name
                  union
                  select substr(file_extract.metadata_file_name, 1, 3) as register,
                         violation_log.table_name,
                         violation_log.violation_type,
                         violation_log.conflicting_registreringFra_UTC,
                         violation_log.conflicting_virkningFra_UTC,
                         ent.id_lokalId,
                         ent.registreringFra,
                         ent.registreringTil,
                         ent.virkningFra,
                         ent.virkningTil
                  from violation_log
                           join file_extract on violation_log.file_extract_id = file_extract.id
                           join Adressepunkt ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                      and 'Adressepunkt' = violation_log.table_name
                  union
                  select substr(file_extract.metadata_file_name, 1, 3) as register,
                         violation_log.table_name,
                         violation_log.violation_type,
                         violation_log.conflicting_registreringFra_UTC,
                         violation_log.conflicting_virkningFra_UTC,
                         ent.id_lokalId,
                         ent.registreringFra,
                         ent.registreringTil,
                         ent.virkningFra,
                         ent.virkningTil
                  from violation_log
                           join file_extract on violation_log.file_extract_id = file_extract.id
                           join BBRSag ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                      and 'BBRSag' = violation_log.table_name
                  union
                  select substr(file_extract.metadata_file_name, 1, 3) as register,
                         violation_log.table_name,
                         violation_log.violation_type,
                         violation_log.conflicting_registreringFra_UTC,
                         violation_log.conflicting_virkningFra_UTC,
                         ent.id_lokalId,
                         ent.registreringFra,
                         ent.registreringTil,
                         ent.virkningFra,
                         ent.virkningTil
                  from violation_log
                           join file_extract on violation_log.file_extract_id = file_extract.id
                           join Bygning ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                      and 'Bygning' = violation_log.table_name
                  union
                  select substr(file_extract.metadata_file_name, 1, 3) as register,
                         violation_log.table_name,
                         violation_log.violation_type,
                         violation_log.conflicting_registreringFra_UTC,
                         violation_log.conflicting_virkningFra_UTC,
                         ent.id_lokalId,
                         ent.registreringFra,
                         ent.registreringTil,
                         ent.virkningFra,
                         ent.virkningTil
                  from violation_log
                           join file_extract on violation_log.file_extract_id = file_extract.id
                           join Ejendomsrelation ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                      and 'Ejendomsrelation' = violation_log.table_name
                  union
                  select substr(file_extract.metadata_file_name, 1, 3) as register,
                         violation_log.table_name,
                         violation_log.violation_type,
                         violation_log.conflicting_registreringFra_UTC,
                         violation_log.conflicting_virkningFra_UTC,
                         ent.id_lokalId,
                         ent.registreringFra,
                         ent.registreringTil,
                         ent.virkningFra,
                         ent.virkningTil
                  from violation_log
                           join file_extract on violation_log.file_extract_id = file_extract.id
                           join Enhed ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                      and 'Enhed' = violation_log.table_name
                  union
                  select substr(file_extract.metadata_file_name, 1, 3) as register,
                         violation_log.table_name,
                         violation_log.violation_type,
                         violation_log.conflicting_registreringFra_UTC,
                         violation_log.conflicting_virkningFra_UTC,
                         ent.id_lokalId,
                         ent.registreringFra,
                         ent.registreringTil,
                         ent.virkningFra,
                         ent.virkningTil
                  from violation_log
                           join file_extract on violation_log.file_extract_id = file_extract.id
                           join EnhedEjendomsrelation ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                      and 'EnhedEjendomsrelation' = violation_log.table_name
                  union
                  select substr(file_extract.metadata_file_name, 1, 3) as register,
                         violation_log.table_name,
                         violation_log.violation_type,
                         violation_log.conflicting_registreringFra_UTC,
                         violation_log.conflicting_virkningFra_UTC,
                         ent.id_lokalId,
                         ent.registreringFra,
                         ent.registreringTil,
                         ent.virkningFra,
                         ent.virkningTil
                  from violation_log
                           join file_extract on violation_log.file_extract_id = file_extract.id
                           join Etage ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                      and 'Etage' = violation_log.table_name
                  union
                  select substr(file_extract.metadata_file_name, 1, 3) as register,
                         violation_log.table_name,
                         violation_log.violation_type,
                         violation_log.conflicting_registreringFra_UTC,
                         violation_log.conflicting_virkningFra_UTC,
                         ent.id_lokalId,
                         ent.registreringFra,
                         ent.registreringTil,
                         ent.virkningFra,
                         ent.virkningTil
                  from violation_log
                           join file_extract on violation_log.file_extract_id = file_extract.id
                           join FordelingAfFordelingsareal ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                      and 'FordelingAfFordelingsareal' = violation_log.table_name
                  union
                  select substr(file_extract.metadata_file_name, 1, 3) as register,
                         violation_log.table_name,
                         violation_log.violation_type,
                         violation_log.conflicting_registreringFra_UTC,
                         violation_log.conflicting_virkningFra_UTC,
                         ent.id_lokalId,
                         ent.registreringFra,
                         ent.registreringTil,
                         ent.virkningFra,
                         ent.virkningTil
                  from violation_log
                           join file_extract on violation_log.file_extract_id = file_extract.id
                           join Fordelingsareal ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                      and 'Fordelingsareal' = violation_log.table_name
                  union
                  select substr(file_extract.metadata_file_name, 1, 3) as register,
                         violation_log.table_name,
                         violation_log.violation_type,
                         violation_log.conflicting_registreringFra_UTC,
                         violation_log.conflicting_virkningFra_UTC,
                         ent.id_lokalId,
                         ent.registreringFra,
                         ent.registreringTil,
                         ent.virkningFra,
                         ent.virkningTil
                  from violation_log
                           join file_extract on violation_log.file_extract_id = file_extract.id
                           join Grund ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                      and 'Grund' = violation_log.table_name
                  union
                  select substr(file_extract.metadata_file_name, 1, 3) as register,
                         violation_log.table_name,
                         violation_log.violation_type,
                         violation_log.conflicting_registreringFra_UTC,
                         violation_log.conflicting_virkningFra_UTC,
                         ent.id_lokalId,
                         ent.registreringFra,
                         ent.registreringTil,
                         ent.virkningFra,
                         ent.virkningTil
                  from violation_log
                           join file_extract on violation_log.file_extract_id = file_extract.id
                           join Husnummer ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                      and 'Husnummer' = violation_log.table_name
                  union
                  select substr(file_extract.metadata_file_name, 1, 3) as register,
                         violation_log.table_name,
                         violation_log.violation_type,
                         violation_log.conflicting_registreringFra_UTC,
                         violation_log.conflicting_virkningFra_UTC,
                         ent.id_lokalId,
                         ent.registreringFra,
                         ent.registreringTil,
                         ent.virkningFra,
                         ent.virkningTil
                  from violation_log
                           join file_extract on violation_log.file_extract_id = file_extract.id
                           join GrundJordstykke ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                      and 'GrundJordstykke' = violation_log.table_name
                  union
                  select substr(file_extract.metadata_file_name, 1, 3) as register,
                         violation_log.table_name,
                         violation_log.violation_type,
                         violation_log.conflicting_registreringFra_UTC,
                         violation_log.conflicting_virkningFra_UTC,
                         ent.id_lokalId,
                         ent.registreringFra,
                         ent.registreringTil,
                         ent.virkningFra,
                         ent.virkningTil
                  from violation_log
                           join file_extract on violation_log.file_extract_id = file_extract.id
                           join NavngivenVej ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                      and 'NavngivenVej' = violation_log.table_name
                  union
                  select substr(file_extract.metadata_file_name, 1, 3) as register,
                         violation_log.table_name,
                         violation_log.violation_type,
                         violation_log.conflicting_registreringFra_UTC,
                         violation_log.conflicting_virkningFra_UTC,
                         ent.id_lokalId,
                         ent.registreringFra,
                         ent.registreringTil,
                         ent.virkningFra,
                         ent.virkningTil
                  from violation_log
                           join file_extract on violation_log.file_extract_id = file_extract.id
                           join NavngivenVejKommunedel ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                      and 'NavngivenVejKommunedel' = violation_log.table_name
                  union
                  select substr(file_extract.metadata_file_name, 1, 3) as register,
                         violation_log.table_name,
                         violation_log.violation_type,
                         violation_log.conflicting_registreringFra_UTC,
                         violation_log.conflicting_virkningFra_UTC,
                         ent.id_lokalId,
                         ent.registreringFra,
                         ent.registreringTil,
                         ent.virkningFra,
                         ent.virkningTil
                  from violation_log
                           join file_extract on violation_log.file_extract_id = file_extract.id
                           join NavngivenVejPostnummer ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                      and 'NavngivenVejPostnummer' = violation_log.table_name
                  union
                  select substr(file_extract.metadata_file_name, 1, 3) as register,
                         violation_log.table_name,
                         violation_log.violation_type,
                         violation_log.conflicting_registreringFra_UTC,
                         violation_log.conflicting_virkningFra_UTC,
                         ent.id_lokalId,
                         ent.registreringFra,
                         ent.registreringTil,
                         ent.virkningFra,
                         ent.virkningTil
                  from violation_log
                           join file_extract on violation_log.file_extract_id = file_extract.id
                           join NavngivenVejSupplerendeBynavn ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                      and 'NavngivenVejSupplerendeBynavn' = violation_log.table_name
                  union
                  select substr(file_extract.metadata_file_name, 1, 3) as register,
                         violation_log.table_name,
                         violation_log.violation_type,
                         violation_log.conflicting_registreringFra_UTC,
                         violation_log.conflicting_virkningFra_UTC,
                         ent.id_lokalId,
                         ent.registreringFra,
                         ent.registreringTil,
                         ent.virkningFra,
                         ent.virkningTil
                  from violation_log
                           join file_extract on violation_log.file_extract_id = file_extract.id
                           join Opgang ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                      and 'Opgang' = violation_log.table_name
                  union
                  select substr(file_extract.metadata_file_name, 1, 3) as register,
                         violation_log.table_name,
                         violation_log.violation_type,
                         violation_log.conflicting_registreringFra_UTC,
                         violation_log.conflicting_virkningFra_UTC,
                         ent.id_lokalId,
                         ent.registreringFra,
                         ent.registreringTil,
                         ent.virkningFra,
                         ent.virkningTil
                  from violation_log
                           join file_extract on violation_log.file_extract_id = file_extract.id
                           join Sagsniveau ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                      and 'Sagsniveau' = violation_log.table_name
                  union
                  select substr(file_extract.metadata_file_name, 1, 3) as register,
                         violation_log.table_name,
                         violation_log.violation_type,
                         violation_log.conflicting_registreringFra_UTC,
                         violation_log.conflicting_virkningFra_UTC,
                         ent.id_lokalId,
                         ent.registreringFra,
                         ent.registreringTil,
                         ent.virkningFra,
                         ent.virkningTil
                  from violation_log
                           join file_extract on violation_log.file_extract_id = file_extract.id
                           join SupplerendeBynavn ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                      and 'SupplerendeBynavn' = violation_log.table_name
                  union
                  select substr(file_extract.metadata_file_name, 1, 3) as register,
                         violation_log.table_name,
                         violation_log.violation_type,
                         violation_log.conflicting_registreringFra_UTC,
                         violation_log.conflicting_virkningFra_UTC,
                         ent.id_lokalId,
                         ent.registreringFra,
                         ent.registreringTil,
                         ent.virkningFra,
                         ent.virkningTil
                  from violation_log
                           join file_extract on violation_log.file_extract_id = file_extract.id
                           join TekniskAnlæg ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                      and 'TekniskAnlæg' = violation_log.table_name
              )
where true
--and table_name = 'Etage'
--and registreringTil is null
--and virkningTil is null
group by register, table_name
order by register desc, bitemporal_fejl desc
;
