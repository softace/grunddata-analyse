select distinct violation_type from violation_log;

select * from file_extract;

select *
from violation_log
where violation_type = 'Ugyldig opdatering af værdier'

select * from Husnummer
where true
and id_lokalId = '0a3f508f-047f-32b8-e044-0003ba298018'
and registreringFra_UTC = '2018-09-05T11:47:30.795832+00:00'
and virkningFra_UTC = '2018-09-05T11:47:30.795832+00:00'
