-- Useful for statistics (pivot-table)
select substr(file_extract.metadata_file_name, 1, 3) as register,
       table_name,
       m.value                                       as dato,
       --file_extract.zip_file_name,
       violation_type,
       count(violation_log.id)                       as antal_bitemporale_fejl
from violation_log
         left outer join file_extract on violation_log.file_extract_id = file_extract.id
         left outer join metadata m on file_extract.id = m.file_extract_id and
                                       m.key = 'DatafordelerUdtraekstidspunkt[0].deltavindueSlut'
group by register, table_name, dato, violation_type
;


select register,
       table_name,
       count(*)                                                                          as bitemporal_fejl,
       count(*) - count(coalesce(registreringTil, virkningTil, NULL))                    as 'aktive',
       (count(*) - count(coalesce(registreringTil, virkningTil, NULL)) + 0.0) / count(*) as andel
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
         where 'Adresse' = violation_log.table_name
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
         where 'Adressepunkt' = violation_log.table_name
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
         where 'BBRSag' = violation_log.table_name
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
         where 'Bygning' = violation_log.table_name
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
         where 'Ejendomsrelation' = violation_log.table_name
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
         where 'Enhed' = violation_log.table_name
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
         where 'EnhedEjendomsrelation' = violation_log.table_name
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
         where 'Etage' = violation_log.table_name
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
         where 'FordelingAfFordelingsareal' = violation_log.table_name
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
         where 'Fordelingsareal' = violation_log.table_name
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
         where 'Grund' = violation_log.table_name
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
         where 'Husnummer' = violation_log.table_name
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
         where 'GrundJordstykke' = violation_log.table_name
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
         where 'NavngivenVej' = violation_log.table_name
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
         where 'NavngivenVejKommunedel' = violation_log.table_name
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
         where 'NavngivenVejPostnummer' = violation_log.table_name
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
         where 'NavngivenVejSupplerendeBynavn' = violation_log.table_name
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
         where 'Opgang' = violation_log.table_name
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
         where 'Sagsniveau' = violation_log.table_name
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
         where 'SupplerendeBynavn' = violation_log.table_name
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
         where 'TekniskAnlæg' = violation_log.table_name
     )
where true
--and table_name = 'Etage'
--and registreringTil is null
--and virkningTil is null
group by register, table_name
order by register desc, bitemporal_fejl desc
;
