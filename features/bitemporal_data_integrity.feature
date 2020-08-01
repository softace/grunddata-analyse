Feature: Bitemporal data integrity
  Background: A DAF database with one entry for a closed rectangle
    Given I initialize the DAF database
    Given a DAR file extract zip file with metadata
    Given the file extract contains data for Postnummer with dummy data and:
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | 2020-01-12T01:01:01.111111+00:00 | 2020-01-15T01:01:01.111111+00:00 | 2000-01-12T01:01:01.111111+00:00 | 2000-01-15T01:01:01.111111+00:00 |
    And file extract is loaded in the DAF database

  Scenario: 8 different bitemporal integrity issues
    Given a DAR file extract zip file with metadata
    Given the file extract contains data for Postnummer with dummy data and:
    # positive circular direction, starting at left-bottom.
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | 2020-01-11T01:01:01.111111+00:00 | 2020-01-13T01:01:01.111111+00:00 | 2000-01-11T01:01:01.111111+00:00 | 2000-01-13T01:01:01.111111+00:00 |
      | guid-0     | 2020-01-13T01:01:01.111111+00:00 | 2020-01-14T01:01:01.111111+00:00 | 2000-01-11T01:01:01.111111+00:00 | 2000-01-13T01:01:01.111111+00:00 |
      | guid-0     | 2020-01-14T01:01:01.111111+00:00 | 2020-01-16T01:01:01.111111+00:00 | 2000-01-11T01:01:01.111111+00:00 | 2000-01-13T01:01:01.111111+00:00 |
      | guid-0     | 2020-01-14T01:01:01.111111+00:00 | 2020-01-16T01:01:01.111111+00:00 | 2000-01-13T01:01:01.111111+00:00 | 2000-01-14T01:01:01.111111+00:00 |
      | guid-0     | 2020-01-14T01:01:01.111111+00:00 | 2020-01-16T01:01:01.111111+00:00 | 2000-01-14T01:01:01.111111+00:00 | 2000-01-16T01:01:01.111111+00:00 |
      | guid-0     | 2020-01-13T01:01:01.111111+00:00 | 2020-01-14T01:01:01.111111+00:00 | 2000-01-14T01:01:01.111111+00:00 | 2000-01-16T01:01:01.111111+00:00 |
      | guid-0     | 2020-01-11T01:01:01.111111+00:00 | 2020-01-13T01:01:01.111111+00:00 | 2000-01-14T01:01:01.111111+00:00 | 2000-01-16T01:01:01.111111+00:00 |
      | guid-0     | 2020-01-11T01:01:01.111111+00:00 | 2020-01-13T01:01:01.111111+00:00 | 2000-01-13T01:01:01.111111+00:00 | 2000-01-14T01:01:01.111111+00:00 |
    When file extract is loaded in the DAF database
    Then the database table violation_log should contain rows with the following entries and no more:
      | table_name | id_lokalId | registreringFra_UTC              | virkningFra_UTC                  | violation_type             | conflicting_registreringFra_UTC  | conflicting_virkningFra_UTC      |
      | Postnummer | guid-0     | 2020-01-11T01:01:01.111111+00:00 | 2000-01-11T01:01:01.111111+00:00 | Bitemporal data-integritet | 2020-01-12T01:01:01.111111+00:00 | 2000-01-12T01:01:01.111111+00:00 |
      | Postnummer | guid-0     | 2020-01-13T01:01:01.111111+00:00 | 2000-01-11T01:01:01.111111+00:00 | Bitemporal data-integritet | 2020-01-12T01:01:01.111111+00:00 | 2000-01-12T01:01:01.111111+00:00 |
      | Postnummer | guid-0     | 2020-01-14T01:01:01.111111+00:00 | 2000-01-11T01:01:01.111111+00:00 | Bitemporal data-integritet | 2020-01-12T01:01:01.111111+00:00 | 2000-01-12T01:01:01.111111+00:00 |
      | Postnummer | guid-0     | 2020-01-14T01:01:01.111111+00:00 | 2000-01-13T01:01:01.111111+00:00 | Bitemporal data-integritet | 2020-01-12T01:01:01.111111+00:00 | 2000-01-12T01:01:01.111111+00:00 |
      | Postnummer | guid-0     | 2020-01-14T01:01:01.111111+00:00 | 2000-01-14T01:01:01.111111+00:00 | Bitemporal data-integritet | 2020-01-12T01:01:01.111111+00:00 | 2000-01-12T01:01:01.111111+00:00 |
      | Postnummer | guid-0     | 2020-01-13T01:01:01.111111+00:00 | 2000-01-14T01:01:01.111111+00:00 | Bitemporal data-integritet | 2020-01-12T01:01:01.111111+00:00 | 2000-01-12T01:01:01.111111+00:00 |
      | Postnummer | guid-0     | 2020-01-11T01:01:01.111111+00:00 | 2000-01-14T01:01:01.111111+00:00 | Bitemporal data-integritet | 2020-01-12T01:01:01.111111+00:00 | 2000-01-12T01:01:01.111111+00:00 |
      | Postnummer | guid-0     | 2020-01-11T01:01:01.111111+00:00 | 2000-01-13T01:01:01.111111+00:00 | Bitemporal data-integritet | 2020-01-12T01:01:01.111111+00:00 | 2000-01-12T01:01:01.111111+00:00 |
