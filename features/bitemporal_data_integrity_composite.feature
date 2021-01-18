Feature: Bitemporal data integrity with composite bitemporalprimary key

  Background: A DAF database with one entry for a closed rectangle
    Given I initialize the DAF database
    Given a MAT file extract zip file with metadata for day 0
    Given the file extract contains data for Lodflade with dummy data and
      | id_lokalId | senesteSagLokalId | status    | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | senesteSagLokalId | Historisk | 2000-01-01T00:00:00.000000+00:00 | 2030-01-01T00:00:00.000000+00:00 | 2000-01-01T00:00:00.000000+00:00 | 2030-01-01T00:00:00.000000+00:00 |
      | guid-0     | senesteSagLokalId | Gældende  | 2020-01-01T00:12:01.111111-01:00 | 2020-01-01T00:15:01.111111-01:00 | 2000-01-01T00:12:01.111111-01:00 | 2000-01-01T00:15:01.111111-01:00 |
      | guid-1     | senesteSagLokalId | Historisk | 2000-01-01T00:00:00.000000+00:00 | 2030-01-01T00:00:00.000000+00:00 | 2000-01-01T00:00:00.000000+00:00 | 2030-01-01T00:00:00.000000+00:00 |
      | guid-1     | senesteSagLokalId | Gældende  | 2020-01-01T00:12:01.111111-01:00 |                                  | 2000-01-01T00:12:01.111111-01:00 |                                  |
    And file extract is loaded in the DAF database
    Then the database table Lodflade should contain rows with the following entries and no more
      | id_lokalId | senesteSagLokalId | status    | registreringFra_UTC              | registreringTil_UTC              | virkningFra_UTC                  | virkningTil_UTC                  |
      | guid-0     | senesteSagLokalId | Historisk | 2000-01-01T00:00:00.000000+00:00 | 2030-01-01T00:00:00.000000+00:00 | 2000-01-01T00:00:00.000000+00:00 | 2030-01-01T00:00:00.000000+00:00 |
      | guid-0     | senesteSagLokalId | Gældende  | 2020-01-01T01:12:01.111111+00:00 | 2020-01-01T01:15:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2000-01-01T01:15:01.111111+00:00 |
      | guid-1     | senesteSagLokalId | Historisk | 2000-01-01T00:00:00.000000+00:00 | 2030-01-01T00:00:00.000000+00:00 | 2000-01-01T00:00:00.000000+00:00 | 2030-01-01T00:00:00.000000+00:00 |
      | guid-1     | senesteSagLokalId | Gældende  | 2020-01-01T01:12:01.111111+00:00 |                                  | 2000-01-01T01:12:01.111111+00:00 |                                  |

  Scenario: 8 different bitemporal integrity issues on a closed rectangle
    Given a MAT file extract zip file with metadata for day 1
    Given the file extract contains data for Lodflade with dummy data and
    # positive circular direction, starting at left-bottom.
      | id_lokalId | senesteSagLokalId | status   | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | senesteSagLokalId | Gældende | 2020-01-01T03:11:01.111111+02:00 | 2020-01-01T03:13:01.111111+02:00 | 2000-01-01T03:11:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 |
      | guid-0     | senesteSagLokalId | Gældende | 2020-01-01T03:13:01.111111+02:00 | 2020-01-01T03:14:01.111111+02:00 | 2000-01-01T03:11:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 |
      | guid-0     | senesteSagLokalId | Gældende | 2020-01-01T03:14:01.111111+02:00 | 2020-01-01T03:16:01.111111+02:00 | 2000-01-01T03:11:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 |
      | guid-0     | senesteSagLokalId | Gældende | 2020-01-01T03:14:01.111111+02:00 | 2020-01-01T03:16:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 | 2000-01-01T03:14:01.111111+02:00 |
      | guid-0     | senesteSagLokalId | Gældende | 2020-01-01T03:14:01.111111+02:00 | 2020-01-01T03:16:01.111111+02:00 | 2000-01-01T03:14:01.111111+02:00 | 2000-01-01T03:16:01.111111+02:00 |
      | guid-0     | senesteSagLokalId | Gældende | 2020-01-01T03:13:01.111111+02:00 | 2020-01-01T03:14:01.111111+02:00 | 2000-01-01T03:14:01.111111+02:00 | 2000-01-01T03:16:01.111111+02:00 |
      | guid-0     | senesteSagLokalId | Gældende | 2020-01-01T03:11:01.111111+02:00 | 2020-01-01T03:13:01.111111+02:00 | 2000-01-01T03:14:01.111111+02:00 | 2000-01-01T03:16:01.111111+02:00 |
      | guid-0     | senesteSagLokalId | Gældende | 2020-01-01T03:11:01.111111+02:00 | 2020-01-01T03:13:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 | 2000-01-01T03:14:01.111111+02:00 |
    When file extract is loaded in the DAF database
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | senesteSagLokalId | status | registreringFra_UTC | virkningFra_UTC | violation_type | conflicting_registreringFra_UTC | conflicting_virkningFra_UTC |
    Then the database table entity_integrity_violation should contain rows with the following entries and no more
      | table_name | bitemporal_primary_key            | ent1_registreringFra_UTC         | ent1_virkningFra_UTC             | ent2_registreringFra_UTC         | ent2_virkningFra_UTC             |
      | Lodflade   | guid-0:senesteSagLokalId:Gældende | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | Lodflade   | guid-0:senesteSagLokalId:Gældende | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 |
      | Lodflade   | guid-0:senesteSagLokalId:Gældende | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 |
      | Lodflade   | guid-0:senesteSagLokalId:Gældende | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 |
      | Lodflade   | guid-0:senesteSagLokalId:Gældende | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 |
      | Lodflade   | guid-0:senesteSagLokalId:Gældende | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 |
      | Lodflade   | guid-0:senesteSagLokalId:Gældende | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | Lodflade   | guid-0:senesteSagLokalId:Gældende | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
    And the database table status_report should contain rows with the following entries
      | file_extract_id | table_name | instance_count | object_count | non_positive_interval_registrering | non_positive_interval_virkning | bitemporal_entity_integrity_count | bitemporal_entity_integrity_instances | bitemporal_entity_integrity_objects | total_instance_count | total_object_count | total_non_positive_interval_registrering | total_non_positive_interval_virkning | total_bitemporal_entity_integrity_count | total_bitemporal_entity_integrity_instances | total_bitemporal_entity_integrity_objects |
      | 1               | Lodflade   | 4              | 4            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 4                    | 4                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 2               | Lodflade   | 8              | 1            | 0                                  | 0                              | 8                                 | 9                                     | 1                                   | 12                   | 4                  | 0                                        | 0                                    | 8                                       | 9                                           | 1                                         |

  Scenario: 4 different bitemporal integrity issues on an double open rectangle
  Bitemporal integrity is resolved in 3/4 on invalid update

    Given a MAT file extract zip file with metadata for day 1
    Given the file extract contains data for Lodflade with dummy data and
    # positive circular direction, starting at left-bottom.
      | id_lokalId | senesteSagLokalId | status   | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-1     | senesteSagLokalId | Gældende | 2020-01-01T03:11:01.111111+02:00 | 2020-01-01T03:13:01.111111+02:00 | 2000-01-01T03:11:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 |
      | guid-1     | senesteSagLokalId | Gældende | 2020-01-01T03:13:01.111111+02:00 | 2020-01-01T03:14:01.111111+02:00 | 2000-01-01T03:11:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 |
      | guid-1     | senesteSagLokalId | Gældende | 2020-01-01T03:14:01.111111+02:00 | 2020-01-01T03:16:01.111111+02:00 | 2000-01-01T03:14:01.111111+02:00 | 2000-01-01T03:16:01.111111+02:00 |
      | guid-1     | senesteSagLokalId | Gældende | 2020-01-01T03:11:01.111111+02:00 | 2020-01-01T03:13:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 | 2000-01-01T03:14:01.111111+02:00 |
    When file extract is loaded in the DAF database
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | status | senesteSagLokalId | registreringFra_UTC | virkningFra_UTC | violation_type | conflicting_registreringFra_UTC | conflicting_virkningFra_UTC |
    Then the database table entity_integrity_violation should contain rows with the following entries and no more
      | table_name | bitemporal_primary_key            | ent1_registreringFra_UTC         | ent1_virkningFra_UTC             | ent2_registreringFra_UTC         | ent2_virkningFra_UTC             |
      | Lodflade   | guid-1:senesteSagLokalId:Gældende | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | Lodflade   | guid-1:senesteSagLokalId:Gældende | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | Lodflade   | guid-1:senesteSagLokalId:Gældende | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 |
      | Lodflade   | guid-1:senesteSagLokalId:Gældende | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 |
    And the database table status_report should contain rows with the following entries
      | file_extract_id | table_name | instance_count | object_count | non_positive_interval_registrering | non_positive_interval_virkning | bitemporal_entity_integrity_count | bitemporal_entity_integrity_instances | bitemporal_entity_integrity_objects | total_instance_count | total_object_count | total_non_positive_interval_registrering | total_non_positive_interval_virkning | total_bitemporal_entity_integrity_count | total_bitemporal_entity_integrity_instances | total_bitemporal_entity_integrity_objects |
      | 1               | Lodflade   | 4              | 4            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 4                    | 4                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 2               | Lodflade   | 4              | 1            | 0                                  | 0                              | 4                                 | 5                                     | 1                                   | 8                    | 4                  | 0                                        | 0                                    | 4                                       | 5                                           | 1                                         |
    Given a MAT file extract zip file with metadata for day 2
    Given the file extract contains data for Lodflade with dummy data and
      # The original open is closed with a minimal positive registrering interval
      | id_lokalId | senesteSagLokalId | status   | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-1     | senesteSagLokalId | Gældende | 2020-01-01T00:12:01.111111-01:00 | 2020-01-01T00:12:01.111112-01:00 | 2000-01-01T00:12:01.111111-01:00 | 2000-01-01T00:12:01.111112-01:00 |
    Then file extract is loaded in the DAF database
    Then the database table Lodflade should contain rows with the following entries and no more
      | id_lokalId | senesteSagLokalId | status    | registreringFra_UTC              | registreringTil_UTC              | virkningFra_UTC                  | virkningTil_UTC                  |
      | guid-0     | senesteSagLokalId | Historisk | 2000-01-01T00:00:00.000000+00:00 | 2030-01-01T00:00:00.000000+00:00 | 2000-01-01T00:00:00.000000+00:00 | 2030-01-01T00:00:00.000000+00:00 |
      | guid-0     | senesteSagLokalId | Gældende  | 2020-01-01T01:12:01.111111+00:00 | 2020-01-01T01:15:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2000-01-01T01:15:01.111111+00:00 |
      | guid-1     | senesteSagLokalId | Historisk | 2000-01-01T00:00:00.000000+00:00 | 2030-01-01T00:00:00.000000+00:00 | 2000-01-01T00:00:00.000000+00:00 | 2030-01-01T00:00:00.000000+00:00 |
      | guid-1     | senesteSagLokalId | Gældende  | 2020-01-01T01:12:01.111111+00:00 | 2020-01-01T01:12:01.111112+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111112+00:00 |
      | guid-1     | senesteSagLokalId | Gældende  | 2020-01-01T01:11:01.111111+00:00 | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 |
      | guid-1     | senesteSagLokalId | Gældende  | 2020-01-01T01:13:01.111111+00:00 | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 |
      | guid-1     | senesteSagLokalId | Gældende  | 2020-01-01T01:14:01.111111+00:00 | 2020-01-01T01:16:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 | 2000-01-01T01:16:01.111111+00:00 |
      | guid-1     | senesteSagLokalId | Gældende  | 2020-01-01T01:11:01.111111+00:00 | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 |
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | senesteSagLokalId | status   | registreringFra_UTC              | virkningFra_UTC                  | violation_type                | conflicting_registreringFra_UTC | conflicting_virkningFra_UTC |
      | 1  | Lodflade   | guid-1     | senesteSagLokalId | Gældende | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | Ugyldig opdatering af værdier |                                 |                             |
    And the database table entity_integrity_violation should contain rows with the following entries and no more
      | table_name | bitemporal_primary_key            | ent1_registreringFra_UTC         | ent1_virkningFra_UTC             | ent2_registreringFra_UTC         | ent2_virkningFra_UTC             |
      | Lodflade   | guid-1:senesteSagLokalId:Gældende | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
    And the database table status_report should contain rows with the following entries
      | file_extract_id | table_name | instance_count | object_count | non_positive_interval_registrering | non_positive_interval_virkning | bitemporal_entity_integrity_count | bitemporal_entity_integrity_instances | bitemporal_entity_integrity_objects | total_instance_count | total_object_count | total_non_positive_interval_registrering | total_non_positive_interval_virkning | total_bitemporal_entity_integrity_count | total_bitemporal_entity_integrity_instances | total_bitemporal_entity_integrity_objects |
      | 1               | Lodflade   | 4              | 4            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 4                    | 4                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 2               | Lodflade   | 4              | 1            | 0                                  | 0                              | 4                                 | 5                                     | 1                                   | 8                    | 4                  | 0                                        | 0                                    | 4                                       | 5                                           | 1                                         |
      | 3               | Lodflade   | 1              | 1            | 0                                  | 0                              | 1                                 | 2                                     | 1                                   | 8                    | 4                  | 0                                        | 0                                    | 1                                       | 2                                           | 1                                         |

  Scenario: Zero and negative intervals should never a bitemporal conflict
    Given a MAT file extract zip file with metadata for day 1
    Given the file extract contains data for Lodflade with dummy data and
      | id_lokalId | senesteSagLokalId | status   | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      # A zero registreringstid
      | guid-0     | senesteSagLokalId | Gældende | 2020-01-01T01:13:01.111111+00:00 | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 |                                  |
      # A zero virkningstid
      | guid-0     | senesteSagLokalId | Gældende | 2020-01-01T01:11:01.111111+00:00 |                                  | 2000-01-01T01:13:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 |
      # A negative registreringstid
      | guid-0     | senesteSagLokalId | Gældende | 2020-01-01T01:14:01.111111+00:00 | 2020-01-01T01:14:00.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 |                                  |
      # A negative virkningstid
      | guid-0     | senesteSagLokalId | Gældende | 2020-01-01T01:11:01.111111+00:00 |                                  | 2000-01-01T01:14:01.111111+00:00 | 2000-01-01T01:14:00.111111+00:00 |
    When file extract is loaded in the DAF database
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | senesteSagLokalId | status   | registreringFra_UTC              | virkningFra_UTC                  | violation_type                      |
      | 1  | Lodflade   | guid-0     | senesteSagLokalId | Gældende | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | Ikke-positivt registreringsinterval |
      | 2  | Lodflade   | guid-0     | senesteSagLokalId | Gældende | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 | Ikke-positivt virkningsinterval     |
      | 3  | Lodflade   | guid-0     | senesteSagLokalId | Gældende | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | Ikke-positivt registreringsinterval |
      | 4  | Lodflade   | guid-0     | senesteSagLokalId | Gældende | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 | Ikke-positivt virkningsinterval     |
