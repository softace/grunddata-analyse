select substr(file_extract.metadata_file_name, 1, 3) as register,
       table_name,
       deltavindueSlut.value                         as dato,
       violation_type,
       count(extended_violation_log.id)              as bitemporale_fejl
from (
         select violation_log.id,
                violation_log.file_extract_id,
                deltavindueSlut.value        as dato,
                violation_log.table_name,
                violation_log.violation_type,
--        violation_log.conflicting_registreringFra_UTC,
--        violation_log.conflicting_virkningFra_UTC,
                ny_entitet.id_lokalId,
                ny_entitet.status,
                ny_entitet.registreringFra   as ny_registreringFra,
                ny_entitet.registreringTil   as ny_registreringTil,
                ny_entitet.virkningFra       as ny_virkningFra,
                ny_entitet.virkningTil       as ny_virkningTil,
                eksisterende.registreringFra as eksisterende_registreringFra,
                eksisterende.registreringTil as eksisterende_registreringFra,
                eksisterende.virkningFra     as eksisterende_virkningFra,
                eksisterende.virkningTil     as eksisterende_virkningTil
         from violation_log
                  join Ejendomsbeliggenhed ny_entitet on ny_entitet.id_lokalId = violation_log.id_lokalId
                                                             and ny_entitet.status = violation_log.status
             and ny_entitet.status = violation_log.status
             and ny_entitet.registreringFra_UTC = violation_log.registreringFra_UTC
             and ny_entitet.virkningFra_UTC = violation_log.virkningFra_UTC
                  left outer join Ejendomsbeliggenhed eksisterende on eksisterende.id_lokalId = violation_log.id_lokalId
                                                             and eksisterende.status = violation_log.status
             and eksisterende.status = violation_log.status
             and eksisterende.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
             and eksisterende.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
                  join file_extract on violation_log.file_extract_id = file_extract.id
                  left outer join metadata deltavindueSlut on file_extract.id = deltavindueSlut.file_extract_id and
                                                              deltavindueSlut.key = 'DatafordelerUdtraekstidspunkt[0].deltavindueSlut'
         where 'Ejendomsbeliggenhed' = violation_log.table_name
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

select
--        violation_log.id,
--       violation_log.file_extract_id,
       deltavindueSlut.value                         as dato,
       violation_log.table_name,
       violation_log.violation_type,
--        violation_log.conflicting_registreringFra_UTC,
--        violation_log.conflicting_virkningFra_UTC,
       ny_entitet.id_lokalId,
       ny_entitet.status,
       ny_entitet.registreringFra,
       ny_entitet.registreringTil,
       ny_entitet.virkningFra,
       ny_entitet.virkningTil,
       eksisterende.registreringFra,
       eksisterende.registreringTil,
       eksisterende.virkningFra,
       eksisterende.virkningTil
from violation_log
         join Ejendomsbeliggenhed ny_entitet on ny_entitet.id_lokalId = violation_log.id_lokalId
                                                    and ny_entitet.status = violation_log.status
    and ny_entitet.registreringFra_UTC = violation_log.registreringFra_UTC
    and ny_entitet.virkningFra_UTC = violation_log.virkningFra_UTC
         left outer join Ejendomsbeliggenhed eksisterende on eksisterende.id_lokalId = violation_log.id_lokalId
                                                                 and eksisterende.status = violation_log.status
    and eksisterende.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
    and eksisterende.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         join file_extract on violation_log.file_extract_id = file_extract.id
         left outer join metadata deltavindueSlut on file_extract.id = deltavindueSlut.file_extract_id and
                                                     deltavindueSlut.key = 'DatafordelerUdtraekstidspunkt[0].deltavindueSlut'
where 'Ejendomsbeliggenhed' = violation_log.table_name
limit 20
;



select substr(file_extract.metadata_file_name, 1, 3) as register,
       table_name,
       deltavindueSlut.value                         as dato,
       violation_type,
       count(extended_violation_log.id)              as bitemporale_fejl,
       count(distinct objekt_id)                    as unikke_id_lokalId,
       sum(correctable)                              as antal_retbare
from (
         select violation_log.id,
                violation_log.file_extract_id,
                violation_log.table_name,
                violation_log.violation_type,
                violation_log.conflicting_registreringFra_UTC,
                violation_log.conflicting_virkningFra_UTC,
                ent.id_lokalId as objekt_id,
                ent.status,
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


select
--        violation_log.id,
--       violation_log.file_extract_id,
       deltavindueSlut.value                         as dato,
       violation_log.table_name,
       violation_log.violation_type,
--        violation_log.conflicting_registreringFra_UTC,
--        violation_log.conflicting_virkningFra_UTC,
       ny_entitet.id_lokalId,
       ny_entitet.status,
       ny_entitet.senesteSagLokalId,
       ny_entitet.registreringFra as ny_registreringFra,
       ny_entitet.registreringTil as ny_registreringTil,
       ny_entitet.virkningFra as ny_virkningFra,
       ny_entitet.virkningTil as ny_virkningTil,
       eksisterende.registreringFra as eksisterende_registreringFra,
       eksisterende.registreringTil as eksisterende_registreringFra,
       eksisterende.virkningFra as eksisterende_virkningFra,
       eksisterende.virkningTil as eksisterende_virkningTil
from violation_log
         join SamletFastEjendom ny_entitet on ny_entitet.id_lokalId = violation_log.id_lokalId
                                                    and ny_entitet.status = violation_log.status
                                                  and ny_entitet.senesteSagLokalId = violation_log.senesteSagLokalId
    and ny_entitet.registreringFra_UTC = violation_log.registreringFra_UTC
    and ny_entitet.virkningFra_UTC = violation_log.virkningFra_UTC
         left outer join SamletFastEjendom eksisterende on eksisterende.id_lokalId = violation_log.id_lokalId
                                                                 and eksisterende.status = violation_log.status
                                                               and eksisterende.senesteSagLokalId = violation_log.senesteSagLokalId
    and eksisterende.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC
    and eksisterende.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC
         join file_extract on violation_log.file_extract_id = file_extract.id
         left outer join metadata deltavindueSlut on file_extract.id = deltavindueSlut.file_extract_id and
                                                     deltavindueSlut.key = 'DatafordelerUdtraekstidspunkt[0].deltavindueSlut'
where 'SamletFastEjendom' = violation_log.table_name
limit 20
;


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
                ent.status,
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

