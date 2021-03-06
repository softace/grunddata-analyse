Feature: Bitemporal entity integrity

  Background: A DAF database with one entry for a closed rectangle
    Given I initialize the DAF database
    Given a DAR file extract zip file with metadata for day 0
    Given the file extract contains data for Postnummer with dummy data and
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | 2020-01-01T00:12:01.111111-01:00 | 2020-01-01T00:15:01.111111-01:00 | 2000-01-01T00:12:01.111111-01:00 | 2000-01-01T00:15:01.111111-01:00 |
      | guid-1     | 2020-01-01T00:12:01.111111-01:00 |                                  | 2000-01-01T00:12:01.111111-01:00 |                                  |
    And file extract is loaded in the DAF database
    Then the database table Postnummer should contain rows with the following entries and no more
      | id_lokalId | registreringFra_UTC              | registreringTil_UTC              | virkningFra_UTC                  | virkningTil_UTC                  |
      | guid-0     | 2020-01-01T01:12:01.111111+00:00 | 2020-01-01T01:15:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2000-01-01T01:15:01.111111+00:00 |
      | guid-1     | 2020-01-01T01:12:01.111111+00:00 |                                  | 2000-01-01T01:12:01.111111+00:00 |                                  |
    And the database table status_report should contain rows with the following entries and no more
      | file_extract_id | table_name                    | instance_count | object_count | non_positive_interval_registrering | non_positive_interval_virkning | bitemporal_entity_integrity_count | bitemporal_entity_integrity_instances | bitemporal_entity_integrity_objects | total_instance_count | total_object_count | total_non_positive_interval_registrering | total_non_positive_interval_virkning | total_bitemporal_entity_integrity_count | total_bitemporal_entity_integrity_instances | total_bitemporal_entity_integrity_objects |
      | 1               | Adresse                       | 0              | 0            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 0                    | 0                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 1               | Adressepunkt                  | 0              | 0            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 0                    | 0                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 1               | Husnummer                     | 0              | 0            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 0                    | 0                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 1               | NavngivenVejKommunedel        | 0              | 0            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 0                    | 0                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 1               | NavngivenVej                  | 0              | 0            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 0                    | 0                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 1               | NavngivenVejPostnummer        | 0              | 0            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 0                    | 0                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 1               | NavngivenVejSupplerendeBynavn | 0              | 0            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 0                    | 0                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 1               | Postnummer                    | 2              | 2            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 2                    | 2                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 1               | SupplerendeBynavn             | 0              | 0            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 0                    | 0                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |

  Scenario: 8 different bitemporal integrity issues on a closed rectangle
    Given a DAR file extract zip file with metadata for day 1
    Given the file extract contains data for Postnummer with dummy data and
    # positive circular direction, starting at left-bottom.
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | 2020-01-01T03:11:01.111111+02:00 | 2020-01-01T03:13:01.111111+02:00 | 2000-01-01T03:11:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 |
      | guid-0     | 2020-01-01T03:13:01.111111+02:00 | 2020-01-01T03:14:01.111111+02:00 | 2000-01-01T03:11:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 |
      | guid-0     | 2020-01-01T03:14:01.111111+02:00 | 2020-01-01T03:16:01.111111+02:00 | 2000-01-01T03:11:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 |
      | guid-0     | 2020-01-01T03:14:01.111111+02:00 | 2020-01-01T03:16:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 | 2000-01-01T03:14:01.111111+02:00 |
      | guid-0     | 2020-01-01T03:14:01.111111+02:00 | 2020-01-01T03:16:01.111111+02:00 | 2000-01-01T03:14:01.111111+02:00 | 2000-01-01T03:16:01.111111+02:00 |
      | guid-0     | 2020-01-01T03:13:01.111111+02:00 | 2020-01-01T03:14:01.111111+02:00 | 2000-01-01T03:14:01.111111+02:00 | 2000-01-01T03:16:01.111111+02:00 |
      | guid-0     | 2020-01-01T03:11:01.111111+02:00 | 2020-01-01T03:13:01.111111+02:00 | 2000-01-01T03:14:01.111111+02:00 | 2000-01-01T03:16:01.111111+02:00 |
      | guid-0     | 2020-01-01T03:11:01.111111+02:00 | 2020-01-01T03:13:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 | 2000-01-01T03:14:01.111111+02:00 |
    When file extract is loaded in the DAF database
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | registreringFra_UTC | virkningFra_UTC | violation_type |
    Then the database table entity_integrity_violation should contain rows with the following entries and no more
      | table_name | bitemporal_primary_key | ent1_registreringFra_UTC         | ent1_virkningFra_UTC             | ent2_registreringFra_UTC         | ent2_virkningFra_UTC             |
      | Postnummer | guid-0                 | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | Postnummer | guid-0                 | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 |
      | Postnummer | guid-0                 | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 |
      | Postnummer | guid-0                 | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 |
      | Postnummer | guid-0                 | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 |
      | Postnummer | guid-0                 | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 |
      | Postnummer | guid-0                 | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | Postnummer | guid-0                 | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
    And the database table status_report should contain rows with the following entries
      | file_extract_id | table_name | instance_count | object_count | non_positive_interval_registrering | non_positive_interval_virkning | bitemporal_entity_integrity_count | bitemporal_entity_integrity_instances | bitemporal_entity_integrity_objects | total_instance_count | total_object_count | total_non_positive_interval_registrering | total_non_positive_interval_virkning | total_bitemporal_entity_integrity_count | total_bitemporal_entity_integrity_instances | total_bitemporal_entity_integrity_objects |
      | 1               | Postnummer | 2              | 2            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 2                    | 2                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 2               | Postnummer | 8              | 1            | 0                                  | 0                              | 8                                 | 9                                     | 1                                   | 10                   | 2                  | 0                                        | 0                                    | 8                                       | 9                                           | 1                                         |

  Scenario: 4 different bitemporal integrity issues on an double open rectangle
  Bitemporal integrity is resolved in 3 out of 4 on invalid update on day 2

    Given a DAR file extract zip file with metadata for day 1
    Given the file extract contains data for Postnummer with dummy data and
    # positive circular direction, starting at left-bottom.
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T03:11:01.111111+02:00 | 2020-01-01T03:13:01.111111+02:00 | 2000-01-01T03:11:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 |
      | guid-1     | 2020-01-01T03:13:01.111111+02:00 | 2020-01-01T03:14:01.111111+02:00 | 2000-01-01T03:11:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 |
      | guid-1     | 2020-01-01T03:14:01.111111+02:00 | 2020-01-01T03:16:01.111111+02:00 | 2000-01-01T03:14:01.111111+02:00 | 2000-01-01T03:16:01.111111+02:00 |
      | guid-1     | 2020-01-01T03:11:01.111111+02:00 | 2020-01-01T03:13:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 | 2000-01-01T03:14:01.111111+02:00 |
    When file extract is loaded in the DAF database
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | registreringFra_UTC | virkningFra_UTC | violation_type |
    Then the database table entity_integrity_violation should contain rows with the following entries and no more
      | table_name | bitemporal_primary_key | ent1_registreringFra_UTC         | ent1_virkningFra_UTC             | ent2_registreringFra_UTC         | ent2_virkningFra_UTC             |
      | Postnummer | guid-1                 | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | Postnummer | guid-1                 | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 |
      | Postnummer | guid-1                 | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 |
      | Postnummer | guid-1                 | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
    And the database table status_report should contain rows with the following entries
      | file_extract_id | table_name | instance_count | object_count | non_positive_interval_registrering | non_positive_interval_virkning | bitemporal_entity_integrity_count | bitemporal_entity_integrity_instances | bitemporal_entity_integrity_objects | total_instance_count | total_object_count | total_non_positive_interval_registrering | total_non_positive_interval_virkning | total_bitemporal_entity_integrity_count | total_bitemporal_entity_integrity_instances | total_bitemporal_entity_integrity_objects |
      | 1               | Postnummer | 2              | 2            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 2                    | 2                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 2               | Postnummer | 4              | 1            | 0                                  | 0                              | 4                                 | 5                                     | 1                                   | 6                    | 2                  | 0                                        | 0                                    | 4                                       | 5                                           | 1                                         |
    Given a DAR file extract zip file with metadata for day 2
    Given the file extract contains data for Postnummer with dummy data and
      # The original double-open rectangle is closed with a minimal positive registrering interval
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T00:12:01.111111-01:00 | 2020-01-01T00:12:01.111112-01:00 | 2000-01-01T00:12:01.111111-01:00 | 2000-01-01T00:12:01.111112-01:00 |
    Then file extract is loaded in the DAF database
    Then the database table Postnummer should contain rows with the following entries and no more
      | id_lokalId | registreringFra_UTC              | registreringTil_UTC              | virkningFra_UTC                  | virkningTil_UTC                  |
      | guid-0     | 2020-01-01T01:12:01.111111+00:00 | 2020-01-01T01:15:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2000-01-01T01:15:01.111111+00:00 |
      | guid-1     | 2020-01-01T01:12:01.111111+00:00 | 2020-01-01T01:12:01.111112+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111112+00:00 |
      | guid-1     | 2020-01-01T01:11:01.111111+00:00 | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 |
      | guid-1     | 2020-01-01T01:13:01.111111+00:00 | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 |
      | guid-1     | 2020-01-01T01:14:01.111111+00:00 | 2020-01-01T01:16:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 | 2000-01-01T01:16:01.111111+00:00 |
      | guid-1     | 2020-01-01T01:11:01.111111+00:00 | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 |
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | registreringFra_UTC              | virkningFra_UTC                  | violation_type                |
      | 1  | Postnummer | guid-1     | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | Ugyldig opdatering af værdier |
    And the database table entity_integrity_violation should contain rows with the following entries and no more
      | table_name | bitemporal_primary_key | ent1_registreringFra_UTC         | ent1_virkningFra_UTC             | ent2_registreringFra_UTC         | ent2_virkningFra_UTC             |
      | Postnummer | guid-1                 | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
    And the database table status_report should contain rows with the following entries
      | file_extract_id | table_name | instance_count | object_count | non_positive_interval_registrering | non_positive_interval_virkning | bitemporal_entity_integrity_count | bitemporal_entity_integrity_instances | bitemporal_entity_integrity_objects | total_instance_count | total_object_count | total_non_positive_interval_registrering | total_non_positive_interval_virkning | total_bitemporal_entity_integrity_count | total_bitemporal_entity_integrity_instances | total_bitemporal_entity_integrity_objects |
      | 1               | Postnummer | 2              | 2            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 2                    | 2                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 2               | Postnummer | 4              | 1            | 0                                  | 0                              | 4                                 | 5                                     | 1                                   | 6                    | 2                  | 0                                        | 0                                    | 4                                       | 5                                           | 1                                         |
      | 3               | Postnummer | 1              | 1            | 0                                  | 0                              | 1                                 | 2                                     | 1                                   | 6                    | 2                  | 0                                        | 0                                    | 1                                       | 2                                           | 1                                         |

  Scenario: file extract counts is not affected by total counts
    Given a DAR file extract zip file with metadata for day 1
    Given the file extract contains data for Postnummer with dummy data and
    # positive circular direction, starting at left-bottom.
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T03:14:01.111111+02:00 | 2020-01-01T03:16:01.111111+02:00 | 2000-01-01T03:14:01.111111+02:00 | 2000-01-01T03:16:01.111111+02:00 |
    When file extract is loaded in the DAF database
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | registreringFra_UTC | virkningFra_UTC | violation_type |
    Then the database table entity_integrity_violation should contain rows with the following entries and no more
      | table_name | bitemporal_primary_key | ent1_registreringFra_UTC         | ent1_virkningFra_UTC             | ent2_registreringFra_UTC         | ent2_virkningFra_UTC             |
      | Postnummer | guid-1                 | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 |
    And the database table status_report should contain rows with the following entries
      | file_extract_id | table_name | instance_count | object_count | non_positive_interval_registrering | non_positive_interval_virkning | bitemporal_entity_integrity_count | bitemporal_entity_integrity_instances | bitemporal_entity_integrity_objects | total_instance_count | total_object_count | total_non_positive_interval_registrering | total_non_positive_interval_virkning | total_bitemporal_entity_integrity_count | total_bitemporal_entity_integrity_instances | total_bitemporal_entity_integrity_objects |
      | 1               | Postnummer | 2              | 2            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 2                    | 2                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 2               | Postnummer | 1              | 1            | 0                                  | 0                              | 1                                 | 2                                     | 1                                   | 3                    | 2                  | 0                                        | 0                                    | 1                                       | 2                                           | 1                                         |
    Given a DAR file extract zip file with metadata for day 2
    Given the file extract contains data for Postnummer with dummy data and
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-3     | 2020-01-01T00:12:01.111111-01:00 | 2020-01-01T00:12:01.111112-01:00 | 2000-01-01T00:12:01.111111-01:00 | 2000-01-01T00:12:01.111112-01:00 |
    Then file extract is loaded in the DAF database
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | registreringFra_UTC | virkningFra_UTC | violation_type |
    And the database table entity_integrity_violation should contain rows with the following entries and no more
      | table_name | bitemporal_primary_key | ent1_registreringFra_UTC         | ent1_virkningFra_UTC             | ent2_registreringFra_UTC         | ent2_virkningFra_UTC             |
      | Postnummer | guid-1                 | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 |
    And the database table status_report should contain rows with the following entries
      | file_extract_id | table_name | instance_count | object_count | non_positive_interval_registrering | non_positive_interval_virkning | bitemporal_entity_integrity_count | bitemporal_entity_integrity_instances | bitemporal_entity_integrity_objects | total_instance_count | total_object_count | total_non_positive_interval_registrering | total_non_positive_interval_virkning | total_bitemporal_entity_integrity_count | total_bitemporal_entity_integrity_instances | total_bitemporal_entity_integrity_objects |
      | 1               | Postnummer | 2              | 2            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 2                    | 2                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 2               | Postnummer | 1              | 1            | 0                                  | 0                              | 1                                 | 2                                     | 1                                   | 3                    | 2                  | 0                                        | 0                                    | 1                                       | 2                                           | 1                                         |
      | 3               | Postnummer | 1              | 1            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 4                    | 3                  | 0                                        | 0                                    | 1                                       | 2                                           | 1                                         |

  Scenario: Zero and negative intervals should never a bitemporal conflict
    Given a DAR file extract zip file with metadata for day 1
    Given the file extract contains data for Postnummer with dummy data and
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      # A zero registreringstid
      | guid-0     | 2020-01-01T01:13:01.111111+00:00 | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 |                                  |
      # A zero virkningstid
      | guid-0     | 2020-01-01T01:11:01.111111+00:00 |                                  | 2000-01-01T01:13:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 |
      # A negative registreringstid
      | guid-0     | 2020-01-01T01:14:01.111111+00:00 | 2020-01-01T01:14:00.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 |                                  |
      # A negative virkningstid
      | guid-0     | 2020-01-01T01:11:01.111111+00:00 |                                  | 2000-01-01T01:14:01.111111+00:00 | 2000-01-01T01:14:00.111111+00:00 |
    When file extract is loaded in the DAF database
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | registreringFra_UTC              | virkningFra_UTC                  | violation_type                      |
      | 1  | Postnummer | guid-0     | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | Ikke-positivt registreringsinterval |
      | 2  | Postnummer | guid-0     | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 | Ikke-positivt virkningsinterval     |
      | 3  | Postnummer | guid-0     | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | Ikke-positivt registreringsinterval |
      | 4  | Postnummer | guid-0     | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 | Ikke-positivt virkningsinterval     |
    And the database table status_report should contain rows with the following entries
      | file_extract_id | table_name | instance_count | object_count | invalid_update_count | non_positive_interval_registrering | non_positive_interval_virkning | bitemporal_entity_integrity_count | bitemporal_entity_integrity_instances | bitemporal_entity_integrity_objects | total_instance_count | total_object_count | total_non_positive_interval_registrering | total_non_positive_interval_virkning | total_bitemporal_entity_integrity_count | total_bitemporal_entity_integrity_instances | total_bitemporal_entity_integrity_objects |
      | 1               | Postnummer | 2              | 2            | 0                    | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 2                    | 2                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 2               | Postnummer | 4              | 1            | 4                    | 2                                  | 2                              | 0                                 | 0                                     | 0                                   | 6                    | 2                  | 2                                        | 2                                    | 0                                       | 0                                           | 0                                         |

  Scenario: Adjacent but non-overlapping rectangles is not a conflict
    Given a DAR file extract zip file with metadata for day 1
    Given the file extract contains data for Postnummer with dummy data and
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-11    | 2020-01-01T01:12:01.111111+00:00 | 2020-01-01T01:15:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2000-01-01T01:15:01.111111+00:00 |
      | guid-12    | 2020-01-01T01:12:01.111111+00:00 | 2020-01-01T01:15:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2000-01-01T01:15:01.111111+00:00 |
      | guid-13    | 2020-01-01T01:12:01.111111+00:00 | 2020-01-01T01:15:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2000-01-01T01:15:01.111111+00:00 |
      | guid-14    | 2020-01-01T01:12:01.111111+00:00 | 2020-01-01T01:15:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2000-01-01T01:15:01.111111+00:00 |
    And file extract is loaded in the DAF database
    Then the database table Postnummer should contain rows with the following entries
      | id_lokalId | registreringFra_UTC              | registreringTil_UTC              | virkningFra_UTC                  | virkningTil_UTC                  |
      | guid-11    | 2020-01-01T01:12:01.111111+00:00 | 2020-01-01T01:15:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2000-01-01T01:15:01.111111+00:00 |
      | guid-12    | 2020-01-01T01:12:01.111111+00:00 | 2020-01-01T01:15:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2000-01-01T01:15:01.111111+00:00 |
      | guid-13    | 2020-01-01T01:12:01.111111+00:00 | 2020-01-01T01:15:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2000-01-01T01:15:01.111111+00:00 |
      | guid-14    | 2020-01-01T01:12:01.111111+00:00 | 2020-01-01T01:15:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2000-01-01T01:15:01.111111+00:00 |
    Given a DAR file extract zip file with metadata for day 2
    Given the file extract contains data for Postnummer with dummy data and
    # positive circular direction, starting at bottom.
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-11    | 2020-01-01T01:01:01.111111+00:00 |                                  | 2000-01-01T01:01:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | guid-12    | 2020-01-01T01:15:01.111111+00:00 |                                  | 2000-01-01T01:15:01.111111+00:00 |                                  |
      | guid-13    | 2020-01-01T01:03:01.111111+00:00 |                                  | 2000-01-01T01:15:01.111111+00:00 |                                  |
      | guid-14    | 2020-01-01T01:04:01.111111+00:00 | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:04:01.111111+00:00 |                                  |
    When file extract is loaded in the DAF database
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | registreringFra_UTC | virkningFra_UTC | violation_type |
    And the database table entity_integrity_violation should contain rows with the following entries and no more
      | table_name | bitemporal_primary_key | ent1_registreringFra_UTC | ent1_virkningFra_UTC | ent2_registreringFra_UTC | ent2_virkningFra_UTC |
    And the database table status_report should contain rows with the following entries
      | file_extract_id | table_name | instance_count | object_count | non_positive_interval_registrering | non_positive_interval_virkning | bitemporal_entity_integrity_count | bitemporal_entity_integrity_instances | bitemporal_entity_integrity_objects | total_instance_count | total_object_count | total_non_positive_interval_registrering | total_non_positive_interval_virkning | total_bitemporal_entity_integrity_count | total_bitemporal_entity_integrity_instances | total_bitemporal_entity_integrity_objects |
      | 1               | Postnummer | 2              | 2            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 2                    | 2                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 2               | Postnummer | 4              | 4            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 6                    | 6                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 3               | Postnummer | 4              | 4            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 10                   | 6                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |

  Scenario: Realistic new registrering with adjacent but non-overlapping registrering is not a conflict
  This scenario has intentionally put the order of the new instance BEFORE the update of the old instance in the file
  because that is what is observed in real life updates. So a delta file should be considered as ONE transation.
    Given a DAR file extract zip file with metadata for day 1
    Given the file extract contains data for Postnummer with dummy data and
      | id_lokalId | registreringFra                  | registreringTil | virkningFra                      | virkningTil |
      | guid-11    | 2020-01-01T01:04:01.111111+00:00 |                 | 2000-01-01T01:12:01.111111+00:00 |             |
    And file extract is loaded in the DAF database
    Then the database table Postnummer should contain rows with the following entries
      | id_lokalId | registreringFra_UTC              | registreringTil_UTC | virkningFra_UTC                  | virkningTil_UTC |
      | guid-11    | 2020-01-01T01:04:01.111111+00:00 |                     | 2000-01-01T01:12:01.111111+00:00 |                 |
    Given a DAR file extract zip file with metadata for day 2
    Given the file extract contains data for Postnummer with dummy data and
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-11    | 2020-01-01T01:12:01.111111+00:00 |                                  | 2000-01-01T01:12:01.111111+00:00 | 2000-01-01T01:15:01.111111+00:00 |
      | guid-11    | 2020-01-01T01:04:01.111111+00:00 | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |                                  |
    When file extract is loaded in the DAF database
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | registreringFra_UTC | virkningFra_UTC | violation_type |
    And the database table entity_integrity_violation should contain rows with the following entries and no more
      | table_name | bitemporal_primary_key | ent1_registreringFra_UTC | ent1_virkningFra_UTC | ent2_registreringFra_UTC | ent2_virkningFra_UTC |
    And the database table status_report should contain rows with the following entries
      | file_extract_id | table_name | instance_count | object_count | non_positive_interval_registrering | non_positive_interval_virkning | bitemporal_entity_integrity_count | bitemporal_entity_integrity_instances | bitemporal_entity_integrity_objects | total_instance_count | total_object_count | total_non_positive_interval_registrering | total_non_positive_interval_virkning | total_bitemporal_entity_integrity_count | total_bitemporal_entity_integrity_instances | total_bitemporal_entity_integrity_objects |
      | 1               | Postnummer | 2              | 2            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 2                    | 2                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 2               | Postnummer | 1              | 1            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 3                    | 3                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 3               | Postnummer | 2              | 1            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 4                    | 3                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
