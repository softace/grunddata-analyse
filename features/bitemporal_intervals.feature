Feature: Bitemporal intervals

  Background:
    Given I initialize the DAF database

  Scenario: virkningTid negative and zero
    Given a DAR file extract zip file with metadata for day 0
    And the file extract contains data for Postnummer with dummy data and
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T01:01:01.111111+00:00 |                                  | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 |
      | guid-2     | 2020-01-01T01:01:01.111111+00:00 |                                  | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111110+00:00 |
      | guid-3     | 2020-01-01T01:01:01.111111+00:00 |                                  | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111112+00:00 |
    When file extract is loaded in the DAF database
    Then the database table Postnummer should contain rows with the following entries
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T01:01:01.111111+00:00 |                                  | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 |
      | guid-2     | 2020-01-01T01:01:01.111111+00:00 |                                  | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111110+00:00 |
      | guid-3     | 2020-01-01T01:01:01.111111+00:00 |                                  | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111112+00:00 |
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | registreringFra_UTC              | virkningFra_UTC                  | violation_type                |
      |  1 | Postnummer | guid-1     | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 | Negativt virkningsinterval    |
      |  2 | Postnummer | guid-2     | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 | Negativt virkningsinterval    |

  Scenario: virkningTid negative and zero
    Given a DAR file extract zip file with metadata for day 0
    And the file extract contains data for Postnummer with dummy data and
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 |                                  |
      | guid-2     | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111110+00:00 | 2020-01-01T01:01:01.111111+00:00 |                                  |
      | guid-3     | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111112+00:00 | 2020-01-01T01:01:01.111111+00:00 |                                  |
    When file extract is loaded in the DAF database
    Then the database table Postnummer should contain rows with the following entries
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 |                                  |
      | guid-2     | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111110+00:00 | 2020-01-01T01:01:01.111111+00:00 |                                  |
      | guid-3     | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111112+00:00 | 2020-01-01T01:01:01.111111+00:00 |                                  |
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | registreringFra_UTC              | virkningFra_UTC                  | violation_type                 |
      |  1 | Postnummer | guid-1     | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 | Negativt registreringsinterval |
      |  2 | Postnummer | guid-2     | 2020-01-01T01:01:01.111111+00:00 | 2020-01-01T01:01:01.111111+00:00 | Negativt registreringsinterval |
