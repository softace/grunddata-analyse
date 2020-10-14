-- Useful for statistics (pivot-table)
-- Bitemporal errors
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

-- Useful for statistics (pivot-table)
-- Bitemporal errors detail
select substr(file_extract.metadata_file_name, 1, 3) as register,
       table_name                                    as tabel_navn,
       deltavindueSlut.value                         as dato,
       violation_type                                as fejl_type,
       count(extended_violation_log.id)              as antal_bitemporale_fejl,
       count(distinct objekt_id)                     as antal_forretningsobjekter,
       sum(correctable)                              as antal_retbare
from (
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId                         as objekt_id,
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
                ent.id_lokalId                         as objekt_id,
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
                ent.id_lokalId                         as objekt_id,
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
                ent.id_lokalId                         as objekt_id,
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
                ent.id_lokalId                         as objekt_id,
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
                ent.id_lokalId                         as objekt_id,
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
                ent.id_lokalId                         as objekt_id,
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
                ent.id_lokalId                         as objekt_id,
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
                ent.id_lokalId                         as objekt_id,
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
                ent.id_lokalId                         as objekt_id,
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
                ent.id_lokalId                         as objekt_id,
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
                ent.id_lokalId                         as objekt_id,
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
                ent.id_lokalId                         as objekt_id,
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
                ent.id_lokalId                         as objekt_id,
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
                ent.id_lokalId                         as objekt_id,
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
                ent.id_lokalId                         as objekt_id,
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
                ent.id_lokalId                         as objekt_id,
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
                ent.id_lokalId                         as objekt_id,
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
                ent.id_lokalId                         as objekt_id,
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
                ent.id_lokalId                         as objekt_id,
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
                ent.id_lokalId                         as objekt_id,
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
                ent.id_lokalId                         as objekt_id,
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
-- EBR:
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId || ent.status           as objekt_id,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join Ejendomsbeliggenhed ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.status = violation_log.status
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Ejendomsbeliggenhed other on other.id_lokalId = violation_log.id_lokalId
             and other.status = violation_log.status
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'Ejendomsbeliggenhed' = violation_log.table_name
-- MAT:
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId || ent.status || ent.senesteSagLokalId as objekt_id,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null)                as correctable
         from violation_log
                  join BygningPaaFremmedGrundFlade ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.status = violation_log.status
             and ent.senesteSagLokalId = violation_log.senesteSagLokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join BygningPaaFremmedGrundFlade other on other.id_lokalId = violation_log.id_lokalId
             and other.status = violation_log.status
             and other.senesteSagLokalId = violation_log.senesteSagLokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'BygningPaaFremmedGrundFlade' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId || ent.status || ent.senesteSagLokalId as objekt_id,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null)                as correctable
         from violation_log
                  join BygningPaaFremmedGrundPunkt ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.status = violation_log.status
             and ent.senesteSagLokalId = violation_log.senesteSagLokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join BygningPaaFremmedGrundPunkt other on other.id_lokalId = violation_log.id_lokalId
             and other.status = violation_log.status
             and other.senesteSagLokalId = violation_log.senesteSagLokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'BygningPaaFremmedGrundPunkt' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId || ent.status || ent.senesteSagLokalId as objekt_id,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null)                as correctable
         from violation_log
                  join Centroide ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.status = violation_log.status
             and ent.senesteSagLokalId = violation_log.senesteSagLokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Centroide other on other.id_lokalId = violation_log.id_lokalId
             and other.status = violation_log.status
             and other.senesteSagLokalId = violation_log.senesteSagLokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'Centroide' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId || ent.status --|| ent.senesteSagLokalId
                                                       as objekt_id,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join Ejerlav ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.status = violation_log.status
--                                                  and ent.senesteSagLokalId = violation_log.senesteSagLokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Ejerlav other on other.id_lokalId = violation_log.id_lokalId
             and other.status = violation_log.status
--                                                  and other.senesteSagLokalId = violation_log.senesteSagLokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'Ejerlav' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId || ent.status || ent.senesteSagLokalId as objekt_id,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null)                as correctable
         from violation_log
                  join Ejerlejlighed ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.status = violation_log.status
             and ent.senesteSagLokalId = violation_log.senesteSagLokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Ejerlejlighed other on other.id_lokalId = violation_log.id_lokalId
             and other.status = violation_log.status
             and other.senesteSagLokalId = violation_log.senesteSagLokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'Ejerlejlighed' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId || ent.status || ent.senesteSagLokalId as objekt_id,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null)                as correctable
         from violation_log
                  join Ejerlejlighedslod ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.status = violation_log.status
             and ent.senesteSagLokalId = violation_log.senesteSagLokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Ejerlejlighedslod other on other.id_lokalId = violation_log.id_lokalId
             and other.status = violation_log.status
             and other.senesteSagLokalId = violation_log.senesteSagLokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'Ejerlejlighedslod' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId || ent.status || ent.senesteSagLokalId as objekt_id,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null)                as correctable
         from violation_log
                  join Jordstykke ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.status = violation_log.status
             and ent.senesteSagLokalId = violation_log.senesteSagLokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Jordstykke other on other.id_lokalId = violation_log.id_lokalId
             and other.status = violation_log.status
             and other.senesteSagLokalId = violation_log.senesteSagLokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'Jordstykke' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId || ent.status || ent.senesteSagLokalId as objekt_id,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null)                as correctable
         from violation_log
                  join JordstykkeTemaflade ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.status = violation_log.status
             and ent.senesteSagLokalId = violation_log.senesteSagLokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join JordstykkeTemaflade other on other.id_lokalId = violation_log.id_lokalId
             and other.status = violation_log.status
             and other.senesteSagLokalId = violation_log.senesteSagLokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'JordstykkeTemaflade' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId || ent.status || ent.senesteSagLokalId as objekt_id,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null)                as correctable
         from violation_log
                  join Lodflade ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.status = violation_log.status
             and ent.senesteSagLokalId = violation_log.senesteSagLokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Lodflade other on other.id_lokalId = violation_log.id_lokalId
             and other.status = violation_log.status
             and other.senesteSagLokalId = violation_log.senesteSagLokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'Lodflade' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId || ent.status -- || ent.senesteSagLokalId
                                                       as objekt_id,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join MatrikelKommune ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.status = violation_log.status
--                                                  and ent.senesteSagLokalId = violation_log.senesteSagLokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join MatrikelKommune other on other.id_lokalId = violation_log.id_lokalId
             and other.status = violation_log.status
--                                                  and other.senesteSagLokalId = violation_log.senesteSagLokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'MatrikelKommune' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId || ent.status -- || ent.senesteSagLokalId
                                                       as objekt_id,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join MatrikelRegion ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.status = violation_log.status
--                                                  and ent.senesteSagLokalId = violation_log.senesteSagLokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join MatrikelRegion other on other.id_lokalId = violation_log.id_lokalId
             and other.status = violation_log.status
--                                                  and other.senesteSagLokalId = violation_log.senesteSagLokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'MatrikelRegion' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId || ent.status -- || ent.senesteSagLokalId
                                                       as objekt_id,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join MatrikelSogn ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.status = violation_log.status
--                                                  and ent.senesteSagLokalId = violation_log.senesteSagLokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join MatrikelSogn other on other.id_lokalId = violation_log.id_lokalId
             and other.status = violation_log.status
--                                                  and other.senesteSagLokalId = violation_log.senesteSagLokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'MatrikelSogn' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId || ent.status || ent.senesteSagLokalId
                                                       as objekt_id,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join Matrikelskel ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.status = violation_log.status
             and ent.senesteSagLokalId = violation_log.senesteSagLokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Matrikelskel other on other.id_lokalId = violation_log.id_lokalId
             and other.status = violation_log.status
             and other.senesteSagLokalId = violation_log.senesteSagLokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'Matrikelskel' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId || ent.status -- || ent.senesteSagLokalId
                                                       as objekt_id,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join MatrikulaerSag ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.status = violation_log.status
--                                                  and ent.senesteSagLokalId = violation_log.senesteSagLokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join MatrikulaerSag other on other.id_lokalId = violation_log.id_lokalId
             and other.status = violation_log.status
--                                                  and other.senesteSagLokalId = violation_log.senesteSagLokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'MatrikulaerSag' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId || ent.status || ent.senesteSagLokalId
                                                       as objekt_id,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join Nullinje ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.status = violation_log.status
             and ent.senesteSagLokalId = violation_log.senesteSagLokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Nullinje other on other.id_lokalId = violation_log.id_lokalId
             and other.status = violation_log.status
             and other.senesteSagLokalId = violation_log.senesteSagLokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'Nullinje' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId || ent.status || ent.senesteSagLokalId
                                                       as objekt_id,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join OptagetVej ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.status = violation_log.status
             and ent.senesteSagLokalId = violation_log.senesteSagLokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join OptagetVej other on other.id_lokalId = violation_log.id_lokalId
             and other.status = violation_log.status
             and other.senesteSagLokalId = violation_log.senesteSagLokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'OptagetVej' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId || ent.status || ent.senesteSagLokalId
                                                       as objekt_id,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join SamletFastEjendom ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.status = violation_log.status
             and ent.senesteSagLokalId = violation_log.senesteSagLokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join SamletFastEjendom other on other.id_lokalId = violation_log.id_lokalId
             and other.status = violation_log.status
             and other.senesteSagLokalId = violation_log.senesteSagLokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'SamletFastEjendom' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId || ent.status || ent.senesteSagLokalId
                                                       as objekt_id,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join Skelpunkt ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.status = violation_log.status
             and ent.senesteSagLokalId = violation_log.senesteSagLokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Skelpunkt other on other.id_lokalId = violation_log.id_lokalId
             and other.status = violation_log.status
             and other.senesteSagLokalId = violation_log.senesteSagLokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'Skelpunkt' = violation_log.table_name
         union
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId || ent.status || ent.senesteSagLokalId
                                                       as objekt_id,
                ent.registreringFra,
                ent.registreringTil,
                ent.virkningFra,
                ent.virkningTil,
                (ent.registreringFra_UTC < other.registreringFra_UTC and ent.registreringTil is null)
                    or (other.registreringFra_UTC < ent.registreringFra_UTC and
                        other.registreringTil is null) as correctable
         from violation_log
                  join Temalinje ent on ent.id_lokalId = violation_log.id_lokalId
             and ent.status = violation_log.status
             and ent.senesteSagLokalId = violation_log.senesteSagLokalId
             and ent.registreringFra_UTC = violation_log.registreringFra_UTC
             and ent.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Temalinje other on other.id_lokalId = violation_log.id_lokalId
             and other.status = violation_log.status
             and other.senesteSagLokalId = violation_log.senesteSagLokalId
             and other.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and other.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         where 'Temalinje' = violation_log.table_name
     ) extended_violation_log
         join file_extract on extended_violation_log.file_extract_id = file_extract.id
         left outer join metadata deltavindueSlut on file_extract.id = deltavindueSlut.file_extract_id and
                                                     deltavindueSlut.key = 'DatafordelerUdtraekstidspunkt[0].deltavindueSlut'
where true
--and table_name = 'Etage'
--and registreringTil is null
--and virkningTil is null
group by register, table_name, dato, violation_type
order by register desc, dato
;
