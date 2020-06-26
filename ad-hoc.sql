select substr(file_extract.metadata_file_name, 1, 3) as register, violation_log.table_name, violation_log.violation_type, ent.id_lokalId, ent.registreringFra, registreringTil, ent.virkningFra, ent.virkningTil
from violation_log
join file_extract on violation_log.file_extract_id = file_extract.id
join Grund ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
and 'Grund' = violation_log.table_name
union
select substr(file_extract.metadata_file_name, 1, 3) as register, violation_log.table_name, violation_log.violation_type, ent.id_lokalId, ent.registreringFra, ent.registreringTil, ent.virkningFra, ent.virkningTil
from violation_log
join file_extract on violation_log.file_extract_id = file_extract.id
join Adresse ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
and 'Adresse' = violation_log.table_name
select substr(file_extract.metadata_file_name, 1, 3) as register, violation_log.table_name, violation_log.violation_type, violation_log.violation_text, ent.id_lokalId, ent.registreringFra, registreringTil, ent.virkningFra, ent.virkningTil
from violation_log
join file_extract on violation_log.file_extract_id = file_extract.id
join Enhed ent on ent.id_lokalId = violation_log.id_lokalId
                      and ent.registreringFra_UTC = violation_log.registreringFra_UTC
                      and ent.virkningFra_UTC = violation_log.virkningFra_UTC
and 'Enhed' = violation_log.table_name
;


select substr(file_extract.metadata_file_name, 1, 3) as register, violation_log.table_name, violation_log.violation_type, ent.id_lokalId, ent.registreringFra, registreringTil, ent.virkningFra, ent.virkningTil
from violation_log
join file_extract on violation_log.file_extract_id = file_extract.id
join Enhed ent on ent.id_lokalId = violation_log.id_lokalId
                      and (
                          (ent.registreringFra_UTC = violation_log.registreringFra_UTC and
                           ent.virkningFra_UTC = violation_log.virkningFra_UTC)
                              OR
                          (ent.registreringFra_UTC = violation_log.conflicting_registreringFra_UTC and
                           ent.virkningFra_UTC = violation_log.conflicting_virkningFra_UTC)
                          )
and 'Enhed' = violation_log.table_name
and 'Samtidig virkende forekomst' = violation_log.violation_type
limit 5*2
;


select *
from Enhed
where id_lokalId = '00040b2c-2530-41ad-9b2c-085aa86fc3de'
and registreringTil is null
and virkningTil is null
;

select count(*) from (
                         select Enhed.id_lokalId, count(EnhedEjendomsrelation.ejerlejlighed)
                         from Enhed
                                  left join EnhedEjendomsrelation on Enhed.id_lokalId = EnhedEjendomsrelation.enhed
--       left join Ejendomsrelation on EnhedEjendomsrelation.ejerlejlighed = Ejendomsrelation.id_lokalId
                         where Enhed.registreringTil is null
                           and Enhed.virkningTil is null
                           and EnhedEjendomsrelation.registreringTil is null
                           and EnhedEjendomsrelation.virkningTil is null
-- and Ejendomsrelation.registreringTil is null
-- and Ejendomsrelation.virkningTil is null
                         group by Enhed.id_lokalId
                         having count(EnhedEjendomsrelation.ejerlejlighed) > 1
                     );
-- 624 (uden Ejendomsrelation)
-- 998 (med Ejendomsrelation)?? bitemporale fejl?

select Adresse.adressebetegnelse, Enhed.id_lokalId, Ejendomsrelation.ejendomsnummer, EnhedEjendomsrelation.*, Ejendomsrelation.*
from Enhed
   left join EnhedEjendomsrelation on Enhed.id_lokalId = EnhedEjendomsrelation.enhed
       left join Ejendomsrelation on EnhedEjendomsrelation.ejerlejlighed = Ejendomsrelation.id_lokalId
left join Adresse on Enhed.adresseIdentificerer = Adresse.id_lokalId
where EnhedEjendomsrelation.enhed = '0072b9a8-60e0-4503-9564-fd5d127f03fe'
and Enhed.registreringTil is null
and Enhed.virkningTil is null
and EnhedEjendomsrelation.registreringTil is null
and EnhedEjendomsrelation.virkningTil is null
and Ejendomsrelation.registreringTil is null
and Ejendomsrelation.virkningTil is null
and Adresse.registreringTil is null
and Adresse.virkningTil is null
;


select file_extract_id, zip_file_name, *
from Husnummer
join file_extract fe on Husnummer.file_extract_id = fe.id
where id_lokalId = '0a3f5097-e885-32b8-e044-0003ba298018'
and registreringFra = '2020-05-10T14:33:25.685071+02:00'
and virkningFra = '2020-05-10T14:33:25.685071+02:00'
;

select * from file_extract;

select * from Adresse
where id_lokalid = '52d33071-adc7-48ab-af7e-48f30d9c3762'
;