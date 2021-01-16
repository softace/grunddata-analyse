Feature: Bitemporal intervals

  Background:
    Given I initialize the DAF database

  Scenario: virkningTid negative and zero
    Given a DAR file extract zip file with metadata for day 0
    And the file extract contains data for Postnummer with dummy data and
      | id_lokalId | registreringFra                  | registreringTil | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T01:01:01.111111+00:00 |                 | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 |
      | guid-2     | 2020-01-01T01:01:01.111111+00:00 |                 | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111110+00:00 |
      | guid-1     | 2120-01-01T01:01:01.111111+00:00 |                 | 2120-01-01T01:01:01.111111+00:00 | 2120-01-01T01:01:01.111112+00:00 |
    When file extract is loaded in the DAF database
    Then the database table Postnummer should contain rows with the following entries
      | id_lokalId | registreringFra                  | registreringTil | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T01:01:01.111111+00:00 |                 | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 |
      | guid-2     | 2020-01-01T01:01:01.111111+00:00 |                 | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111110+00:00 |
      | guid-1     | 2120-01-01T01:01:01.111111+00:00 |                 | 2120-01-01T01:01:01.111111+00:00 | 2120-01-01T01:01:01.111112+00:00 |
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | registreringFra_UTC              | virkningFra_UTC                  | violation_type                  |
      | 1  | Postnummer | guid-1     | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 | Ikke-positivt virkningsinterval |
      | 2  | Postnummer | guid-2     | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 | Ikke-positivt virkningsinterval |
    And the database table status_report should contain rows with the following entries
      | file_extract_id | table_name | instance_count | object_count | non_positive_interval_registrering | non_positive_interval_virkning | bitemporal_entity_integrity_count | bitemporal_entity_integrity_instances | bitemporal_entity_integrity_objects | total_instance_count | total_object_count | total_non_positive_interval_registrering | total_non_positive_interval_virkning | total_bitemporal_entity_integrity_count | total_bitemporal_entity_integrity_instances | total_bitemporal_entity_integrity_objects |
      | 1               | Postnummer | 3              | 2            | 0                                  | 2                              | 0                                 | 0                                     | 0                                   | 3                    | 2                  | 0                                        | 2                                    | 0                                       | 0                                           | 0                                         |

  Scenario: registreringTid negative and zero
    Given a DAR file extract zip file with metadata for day 0
    And the file extract contains data for Postnummer with dummy data and
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 |                                  |
      | guid-2     | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111110+00:00 | 2020-01-01T01:01:01.111111+00:00 |                                  |
      | guid-1     | 2120-01-01T01:01:01.111111+00:00 |                                  | 2120-01-01T01:01:01.111111+00:00 | 2120-01-01T01:01:01.111112+00:00 |
    When file extract is loaded in the DAF database
    Then the database table Postnummer should contain rows with the following entries
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 |                                  |
      | guid-2     | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111110+00:00 | 2020-01-01T01:01:01.111111+00:00 |                                  |
      | guid-1     | 2120-01-01T01:01:01.111111+00:00 |                                  | 2120-01-01T01:01:01.111111+00:00 | 2120-01-01T01:01:01.111112+00:00 |
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | registreringFra_UTC              | virkningFra_UTC                  | violation_type                      |
      | 1  | Postnummer | guid-1     | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 | Ikke-positivt registreringsinterval |
      | 2  | Postnummer | guid-2     | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 | Ikke-positivt registreringsinterval |
    And the database table status_report should contain rows with the following entries
      | file_extract_id | table_name | instance_count | object_count | non_positive_interval_registrering | non_positive_interval_virkning | bitemporal_entity_integrity_count | bitemporal_entity_integrity_instances | bitemporal_entity_integrity_objects | total_instance_count | total_object_count | total_non_positive_interval_registrering | total_non_positive_interval_virkning | total_bitemporal_entity_integrity_count | total_bitemporal_entity_integrity_instances | total_bitemporal_entity_integrity_objects |
      | 1               | Postnummer | 3              | 2            | 2                                  | 0                              | 0                                 | 0                                     | 0                                   | 3                    | 2                  | 2                                        | 0                                    | 0                                       | 0                                           | 0                                         |

  Scenario: Updates affects counting
    Given a DAR file extract zip file with metadata for day 0
    And the file extract contains data for Postnummer with dummy data and
      | id_lokalId | registreringFra                  | registreringTil | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T01:01:01.111111+00:00 |                 | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 |
      | guid-2     | 2020-01-01T01:01:01.111111+00:00 |                 | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111110+00:00 |
      | guid-1     | 2120-01-01T01:01:01.111111+00:00 |                 | 2120-01-01T01:01:01.111111+00:00 | 2120-01-01T01:01:01.111112+00:00 |
    When file extract is loaded in the DAF database
    Then the database table Postnummer should contain rows with the following entries
      | id_lokalId | registreringFra                  | registreringTil | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T01:01:01.111111+00:00 |                 | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 |
      | guid-2     | 2020-01-01T01:01:01.111111+00:00 |                 | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111110+00:00 |
      | guid-1     | 2120-01-01T01:01:01.111111+00:00 |                 | 2120-01-01T01:01:01.111111+00:00 | 2120-01-01T01:01:01.111112+00:00 |
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | registreringFra_UTC              | virkningFra_UTC                  | violation_type                  |
      | 1  | Postnummer | guid-1     | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 | Ikke-positivt virkningsinterval |
      | 2  | Postnummer | guid-2     | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 | Ikke-positivt virkningsinterval |
    And the database table status_report should contain rows with the following entries
      | file_extract_id | table_name | instance_count | object_count | non_positive_interval_registrering | non_positive_interval_virkning | bitemporal_entity_integrity_count | bitemporal_entity_integrity_instances | bitemporal_entity_integrity_objects | total_instance_count | total_object_count | total_non_positive_interval_registrering | total_non_positive_interval_virkning | total_bitemporal_entity_integrity_count | total_bitemporal_entity_integrity_instances | total_bitemporal_entity_integrity_objects |
      | 1               | Postnummer | 3              | 2            | 0                                  | 2                              | 0                                 | 0                                     | 0                                   | 3                    | 2                  | 0                                        | 2                                    | 0                                       | 0                                           | 0                                         |
    Given a DAR file extract zip file with metadata for day 1
    And the file extract contains data for Postnummer with dummy data and
      | id_lokalId | registreringFra                  | registreringTil | virkningFra                      | virkningTil                      |
      | guid-2     | 2020-01-01T01:01:01.111111+00:00 |                 | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111113+00:00 |
    When file extract is loaded in the DAF database
    Then the database table Postnummer should contain rows with the following entries
      | id_lokalId | registreringFra                  | registreringTil | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T01:01:01.111111+00:00 |                 | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 |
      | guid-2     | 2020-01-01T01:01:01.111111+00:00 |                 | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111113+00:00 |
      | guid-1     | 2120-01-01T01:01:01.111111+00:00 |                 | 2120-01-01T01:01:01.111111+00:00 | 2120-01-01T01:01:01.111112+00:00 |
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | registreringFra_UTC              | virkningFra_UTC                  | violation_type                  |
      | 1  | Postnummer | guid-1     | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 | Ikke-positivt virkningsinterval |
      | 2  | Postnummer | guid-2     | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 | Ikke-positivt virkningsinterval |
      | 3  | Postnummer | guid-2     | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 | Ugyldig opdatering af værdier   |
    And the database table status_report should contain rows with the following entries
      | file_extract_id | table_name | instance_count | object_count | non_positive_interval_registrering | non_positive_interval_virkning | bitemporal_entity_integrity_count | bitemporal_entity_integrity_instances | bitemporal_entity_integrity_objects | total_instance_count | total_object_count | total_non_positive_interval_registrering | total_non_positive_interval_virkning | total_bitemporal_entity_integrity_count | total_bitemporal_entity_integrity_instances | total_bitemporal_entity_integrity_objects |
      | 1               | Postnummer | 3              | 2            | 0                                  | 2                              | 0                                 | 0                                     | 0                                   | 3                    | 2                  | 0                                        | 2                                    | 0                                       | 0                                           | 0                                         |
      | 2               | Postnummer | 1              | 1            | 0                                  | 1                              | 0                                 | 0                                     | 0                                   | 4                    | 2                  | 0                                        | 1                                    | 0                                       | 0                                           | 0                                         |
