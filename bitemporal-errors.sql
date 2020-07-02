-- Useful for statistics (pivot-table)
select substr(file_extract.metadata_file_name, 1, 3) as register,
       table_name,
       deltavindueSlut.value                         as dato,
       --file_extract.zip_file_name,
       violation_type,
       count(violation_log.id)                       as bitemporale_fejl
from violation_log
         left outer join file_extract on violation_log.file_extract_id = file_extract.id
         left outer join metadata deltavindueSlut on file_extract.id = deltavindueSlut.file_extract_id and
                                                     deltavindueSlut.key = 'DatafordelerUdtraekstidspunkt[0].deltavindueSlut'
group by register, table_name, dato, violation_type
order by register desc, bitemporale_fejl desc
;

-- Even more Useful for statistics (pivot-table)
select substr(file_extract.metadata_file_name, 1, 3) as register,
       table_name,
       deltavindueSlut.value                         as dato,
       violation_type,
       count(extended_violation_log.id)              as bitemporale_fejl,
       count(distinct id_lokalId)                    as unikke_id_lokalId,
       sum(correctable)                              as antal_retbare
from (
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join Adresse ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Adresse other on other.id_lokalId = violation_log.id_lokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'Adresse' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join Adressepunkt ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Adressepunkt other on other.id_lokalId = violation_log.id_lokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'Adressepunkt' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join BBRSag ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join BBRSag other on other.id_lokalId = violation_log.id_lokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'BBRSag' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join Bygning ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Bygning other on other.id_lokalId = violation_log.id_lokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'Bygning' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join Ejendomsrelation ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Ejendomsrelation other on other.id_lokalId = violation_log.id_lokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'Ejendomsrelation' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join Enhed ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Enhed other on other.id_lokalId = violation_log.id_lokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'Enhed' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join EnhedEjendomsrelation ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join EnhedEjendomsrelation other on other.id_lokalId = violation_log.id_lokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'EnhedEjendomsrelation' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join Etage ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Etage other on other.id_lokalId = violation_log.id_lokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'Etage' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join FordelingAfFordelingsareal ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join FordelingAfFordelingsareal other on other.id_lokalId = violation_log.id_lokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'FordelingAfFordelingsareal' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join Fordelingsareal ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Fordelingsareal other on other.id_lokalId = violation_log.id_lokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'Fordelingsareal' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join Grund ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Grund other on other.id_lokalId = violation_log.id_lokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'Grund' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join Husnummer ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Husnummer other on other.id_lokalId = violation_log.id_lokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'Husnummer' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join GrundJordstykke ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join GrundJordstykke other on other.id_lokalId = violation_log.id_lokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'GrundJordstykke' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join NavngivenVej ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join NavngivenVej other on other.id_lokalId = violation_log.id_lokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'NavngivenVej' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join NavngivenVejKommunedel ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join NavngivenVejKommunedel other on other.id_lokalId = violation_log.id_lokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'NavngivenVejKommunedel' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join NavngivenVejPostnummer ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join NavngivenVejPostnummer other on other.id_lokalId = violation_log.id_lokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'NavngivenVejPostnummer' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join NavngivenVejSupplerendeBynavn ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join NavngivenVejSupplerendeBynavn other on other.id_lokalId = violation_log.id_lokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'NavngivenVejSupplerendeBynavn' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join Opgang ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Opgang other on other.id_lokalId = violation_log.id_lokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'Opgang' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join Postnummer ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Postnummer other on other.id_lokalId = violation_log.id_lokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'Postnummer' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join Sagsniveau ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Sagsniveau other on other.id_lokalId = violation_log.id_lokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'Sagsniveau' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join SupplerendeBynavn ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join SupplerendeBynavn other on other.id_lokalId = violation_log.id_lokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'SupplerendeBynavn' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join TekniskAnlæg ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join TekniskAnlæg other on other.id_lokalId = violation_log.id_lokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'TekniskAnlæg' = violation_log.table_name
     ) extended_violation_log
         join file_extract on extended_violation_log.file_extract_id = file_extract.id
         left outer join metadata deltavindueSlut on file_extract.id = deltavindueSlut.file_extract_id and
                                                     deltavindueSlut.key = 'DatafordelerUdtraekstidspunkt[0].deltavindueSlut'
where true
--and table_name = 'Etage'
--and registreringTil is null
--and virkningTil is null
group by register, table_name, dato, violation_type
order by register desc, bitemporale_fejl desc
;
