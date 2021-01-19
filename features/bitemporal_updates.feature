Feature: Bitemporal entity integrity

  Background: A DAF database with an un-final and a final instance
    Given I initialize the DAF database
    Given a DAR file extract zip file with metadata for day 0
    Given the file extract contains data for Postnummer with dummy data and
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | 2020-01-01T01:01:01.111111+01:00 |                                  | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
      | guid-1     | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
    And file extract is loaded in the DAF database
    Then the database table status_report should contain rows with the following entries
      | file_extract_id | table_name | instance_count | object_count | non_positive_interval_registrering | non_positive_interval_virkning | bitemporal_entity_integrity_count | bitemporal_entity_integrity_instances | bitemporal_entity_integrity_objects | total_instance_count | total_object_count | total_non_positive_interval_registrering | total_non_positive_interval_virkning | total_bitemporal_entity_integrity_count | total_bitemporal_entity_integrity_instances | total_bitemporal_entity_integrity_objects |
      | 1               | Postnummer | 2              | 2            | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 2                    | 2                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |

  Scenario: Finalising an un-final instance shall not log violation
    Given a DAR file extract zip file with metadata for day 1
    And the file extract contains data for Postnummer with dummy data and
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
    When file extract is loaded in the DAF database
    Then the database table Postnummer should contain rows with the following entries
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | registreringFra_UTC | virkningFra_UTC | violation_type | conflicting_registreringFra_UTC | conflicting_virkningFra_UTC |
    And the database table status_report should contain rows with the following entries
      | file_extract_id | table_name | instance_count | object_count | invalid_update_count | non_positive_interval_registrering | non_positive_interval_virkning | bitemporal_entity_integrity_count | bitemporal_entity_integrity_instances | bitemporal_entity_integrity_objects | total_instance_count | total_object_count | total_non_positive_interval_registrering | total_non_positive_interval_virkning | total_bitemporal_entity_integrity_count | total_bitemporal_entity_integrity_instances | total_bitemporal_entity_integrity_objects |
      | 1               | Postnummer | 2              | 2            | 0                    | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 2                    | 2                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 2               | Postnummer | 1              | 1            | 0                    | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 2                    | 2                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |

  Scenario: Update an instance should update and log violation
    Given a DAR file extract zip file with metadata for day 1
    And the file extract contains data for Postnummer with dummy data and
      | id_lokalId | registreringFra                  | registreringTil | virkningFra                      | virkningTil                      |
      | guid-0     | 2020-01-01T01:01:01.111111+01:00 |                 | 2020-01-01T01:01:01.111111+01:00 | 2030-01-02T01:01:01.111111+01:00 |
    When file extract is loaded in the DAF database
    Then the database table Postnummer should contain rows with the following entries
      | id_lokalId | registreringFra                  | registreringTil | virkningFra                      | virkningTil                      |
      | guid-0     | 2020-01-01T01:01:01.111111+01:00 |                 | 2020-01-01T01:01:01.111111+01:00 | 2030-01-02T01:01:01.111111+01:00 |
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | registreringFra_UTC              | virkningFra_UTC                  | violation_type                | violation_text                                                                     |
      | 1  | Postnummer | guid-0     | 2020-01-01T00:01:01.111111+00:00 | 2020-01-01T00:01:01.111111+00:00 | Ugyldig opdatering af værdier | (virkningTil) opdateret. Tidligere værdi(er): ('2020-01-02T01:01:01.111111+01:00') |
    And the database table status_report should contain rows with the following entries
      | file_extract_id | table_name | instance_count | object_count | invalid_update_count | non_positive_interval_registrering | non_positive_interval_virkning | bitemporal_entity_integrity_count | bitemporal_entity_integrity_instances | bitemporal_entity_integrity_objects | total_instance_count | total_object_count | total_non_positive_interval_registrering | total_non_positive_interval_virkning | total_bitemporal_entity_integrity_count | total_bitemporal_entity_integrity_instances | total_bitemporal_entity_integrity_objects |
      | 1               | Postnummer | 2              | 2            | 0                    | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 2                    | 2                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 2               | Postnummer | 1              | 1            | 1                    | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 2                    | 2                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |

  Scenario: Finalising an un-final instance with extra updates should update and log violation
    Given a DAR file extract zip file with metadata for day 1
    And the file extract contains data for Postnummer with dummy data and
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 | 2020-01-01T01:01:01.111111+01:00 | 2030-01-02T01:01:01.111111+01:00 |
    When file extract is loaded in the DAF database
    Then the database table Postnummer should contain rows with the following entries
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 | 2020-01-01T01:01:01.111111+01:00 | 2030-01-02T01:01:01.111111+01:00 |
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | registreringFra_UTC              | virkningFra_UTC                  | violation_type                | violation_text                                                                     |
      | 1  | Postnummer | guid-0     | 2020-01-01T00:01:01.111111+00:00 | 2020-01-01T00:01:01.111111+00:00 | Ugyldig opdatering af værdier | (virkningTil) opdateret. Tidligere værdi(er): ('2020-01-02T01:01:01.111111+01:00') |
    And the database table status_report should contain rows with the following entries
      | file_extract_id | table_name | instance_count | object_count | invalid_update_count | non_positive_interval_registrering | non_positive_interval_virkning | bitemporal_entity_integrity_count | bitemporal_entity_integrity_instances | bitemporal_entity_integrity_objects | total_instance_count | total_object_count | total_non_positive_interval_registrering | total_non_positive_interval_virkning | total_bitemporal_entity_integrity_count | total_bitemporal_entity_integrity_instances | total_bitemporal_entity_integrity_objects |
      | 1               | Postnummer | 2              | 2            | 0                    | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 2                    | 2                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 2               | Postnummer | 1              | 1            | 1                    | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 2                    | 2                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |

  Scenario: Finalising an already final instance should update and log violation
    Given a DAR file extract zip file with metadata for day 1
    And the file extract contains data for Postnummer with dummy data and
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T01:01:01.111111+01:00 | 2030-01-02T01:01:01.111111+01:00 | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
    When file extract is loaded in the DAF database
    Then the database table Postnummer should contain rows with the following entries
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T01:01:01.111111+01:00 | 2030-01-02T01:01:01.111111+01:00 | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | registreringFra_UTC              | virkningFra_UTC                  | violation_type                | violation_text                                                                         |
      | 1  | Postnummer | guid-1     | 2020-01-01T00:01:01.111111+00:00 | 2020-01-01T00:01:01.111111+00:00 | Ugyldig opdatering af værdier | (registreringTil) opdateret. Tidligere værdi(er): ('2020-01-02T01:01:01.111111+01:00') |
    And the database table status_report should contain rows with the following entries
      | file_extract_id | table_name | instance_count | object_count | invalid_update_count | non_positive_interval_registrering | non_positive_interval_virkning | bitemporal_entity_integrity_count | bitemporal_entity_integrity_instances | bitemporal_entity_integrity_objects | total_instance_count | total_object_count | total_non_positive_interval_registrering | total_non_positive_interval_virkning | total_bitemporal_entity_integrity_count | total_bitemporal_entity_integrity_instances | total_bitemporal_entity_integrity_objects |
      | 1               | Postnummer | 2              | 2            | 0                    | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 2                    | 2                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |
      | 2               | Postnummer | 1              | 1            | 1                    | 0                                  | 0                              | 0                                 | 0                                     | 0                                   | 2                    | 2                  | 0                                        | 0                                    | 0                                       | 0                                           | 0                                         |

