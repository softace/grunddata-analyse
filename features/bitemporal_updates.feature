Feature: Bitemporal data integrity
  Background: A DAF database with an un-final and a final instance
    Given I initialize the DAF database
    Given a DAR file extract zip file with metadata
    Given the file extract contains data for Postnummer with dummy data and:
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | 2020-01-01T01:01:01.111111+01:00 |                                  | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
      | guid-1     | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
    And file extract is loaded in the DAF database

  Scenario: Finalising an un-final instance
    Given a DAR file extract zip file with metadata
    And the file extract contains data for Postnummer with dummy data and:
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
    When file extract is loaded in the DAF database
    Then the database table Postnummer should contain rows with the following entries:
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
    Then the database table violation_log should contain rows with the following entries and no more:
      | table_name | id_lokalId | registreringFra_UTC              | virkningFra_UTC                  | violation_type             | conflicting_registreringFra_UTC  | conflicting_virkningFra_UTC      |

  Scenario: Finalising an un-final instance with extra updates
    Given a DAR file extract zip file with metadata
    And the file extract contains data for Postnummer with dummy data and:
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 | 2020-01-01T01:01:01.111111+01:00 | 2030-01-02T01:01:01.111111+01:00 |
    When file extract is loaded in the DAF database
    Then the database table Postnummer should contain rows with the following entries:
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 | 2020-01-01T01:01:01.111111+01:00 | 2030-01-02T01:01:01.111111+01:00 |
    Then the database table violation_log should contain rows with the following entries and no more:
      | table_name | id_lokalId | registreringFra_UTC              | virkningFra_UTC                  | violation_type              | violation_text                                                                                                                      |
      | Postnummer | guid-0     | 2020-01-01T00:01:01.111111+00:00 | 2020-01-01T00:01:01.111111+00:00 |Ugyldig opdatering af værdier|(virkningTil) opdateret. Tidligere værdi(er): ('2020-01-02T01:01:01.111111+01:00')|
