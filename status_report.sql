-- Status report
select substr(deltavindueSlut.value, 0, 11)        as 'Leverancedato',
       registry                                    as 'Register',
       table_name                                  as 'Begreb',
       instance_count                              as 'Forekomster i levarance',
       object_count                                as 'Forretningsobjekter i levarance',
       invalid_update_count                        as 'Ugyldig opateringer i levarance',
       non_positive_interval_registrering          as 'Ikke-positiv registreringsinterval i levarance',
       non_positive_interval_virkning              as 'Ikke-positiv virkningsinterval i levarance',
       bitemporal_entity_integrity_count           as 'Bitemporal entitets-integritet fejl i levarance',
       bitemporal_entity_integrity_instances       as 'Forekomster med bitemporal entitets-integritet fejl i levarance',
       bitemporal_entity_integrity_objects         as 'Forretningsobjekter med bitemporal entitets-integritet fejl i levarance',
       total_instance_count                        as 'Forekomster i alt',
       total_object_count                          as 'Forretningsobjekter i alt',
       total_non_positive_interval_registrering    as 'Ikke-positiv registreringsinterval i alt',
       total_non_positive_interval_virkning        as 'Ikke-positiv virkningsinterval i alt',
       total_bitemporal_entity_integrity_count     as 'Bitemporal entitets-integritet fejl i alt',
       total_bitemporal_entity_integrity_instances as 'Forekomster med bitemporal entitets-integritet fejl i alt',
       total_bitemporal_entity_integrity_objects   as 'Forretningsobjekter med bitemporal entitets-integritet fejl i alt'
from status_report
         join file_extract on status_report.file_extract_id = file_extract.id
         join metadata deltavindueSlut on file_extract.id = deltavindueSlut.file_extract_id and
                                          deltavindueSlut.key = 'DatafordelerUdtraekstidspunkt[0].deltavindueSlut'
