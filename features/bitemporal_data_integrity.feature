Feature: Bitemporal data integrity
  Background: A DAF database with one entry for a closed rectangle
    Given I initialize the DAF database
    Given a DAR file extract zip file with metadata for day 0
    Given the file extract contains data for Postnummer with dummy data and
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | 2020-01-01T00:12:01.111111-01:00 | 2020-01-01T00:15:01.111111-01:00 | 2000-01-01T00:12:01.111111-01:00 | 2000-01-01T00:15:01.111111-01:00 |
      | guid-1     | 2020-01-01T00:12:01.111111-01:00 |                                  | 2000-01-01T00:12:01.111111-01:00 |                                  |
    And file extract is loaded in the DAF database

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
      | table_name | id_lokalId | registreringFra_UTC              | virkningFra_UTC                  | violation_type             | conflicting_registreringFra_UTC  | conflicting_virkningFra_UTC      |
      | Postnummer | guid-0     | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | Bitemporal data-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | Postnummer | guid-0     | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | Bitemporal data-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | Postnummer | guid-0     | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | Bitemporal data-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | Postnummer | guid-0     | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 | Bitemporal data-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | Postnummer | guid-0     | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 | Bitemporal data-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | Postnummer | guid-0     | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 | Bitemporal data-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | Postnummer | guid-0     | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 | Bitemporal data-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | Postnummer | guid-0     | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 | Bitemporal data-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |

  Scenario: 4 different bitemporal integrity issues on an double open rectangle
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
      | table_name | id_lokalId | registreringFra_UTC              | virkningFra_UTC                  | violation_type             | conflicting_registreringFra_UTC  | conflicting_virkningFra_UTC      |
      | Postnummer | guid-1     | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | Bitemporal data-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | Postnummer | guid-1     | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | Bitemporal data-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | Postnummer | guid-1     | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 | Bitemporal data-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | Postnummer | guid-1     | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 | Bitemporal data-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
