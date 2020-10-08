Feature: Basic stuff

  Background:
    Given I initialize the DAF database

  Scenario: Loading the initial load
    Given a DAR file extract zip file with metadata for day 0
    Given the file extract contains data for Postnummer with dummy data and
      | id_lokalId | registreringFra                  | registreringTil | virkningFra                      | virkningTil                      |
      | guid-A-1   | 2020-01-01T01:01:01.111111+01:00 |                 | 2020-01-01T01:01:01.000000+01:00 | 2020-01-02T01:01:01.111111+01:00 |
    When file extract is loaded in the DAF database
    Then the database table Postnummer should contain rows with the following entries
      | id_lokalId | registreringFra                  | registreringTil | virkningFra                      | virkningTil                      |
      | guid-A-1   | 2020-01-01T01:01:01.111111+01:00 |                 | 2020-01-01T01:01:01.000000+01:00 | 2020-01-02T01:01:01.111111+01:00 |

    Given a BBR file extract zip file with metadata for day 0
    Given the file extract contains data for Grund with dummy data and
      | id_lokalId | registreringFra                  | registreringTil | virkningFra                      | virkningTil                      |
      | guid-B-1   | 2020-01-01T01:01:01.111111+01:00 |                 | 2020-01-01T01:01:01.000000+01:00 | 2020-01-02T01:01:01.111111+01:00 |
    When file extract is loaded in the DAF database
    Then the database table Grund should contain rows with the following entries
      | id_lokalId | registreringFra                  | registreringTil | virkningFra                      | virkningTil                      |
      | guid-B-1   | 2020-01-01T01:01:01.111111+01:00 |                 | 2020-01-01T01:01:01.000000+01:00 | 2020-01-02T01:01:01.111111+01:00 |

    Given a MAT file extract zip file with metadata for day 0
    Given the file extract contains data for Lodflade with dummy data and
      | id_lokalId | registreringFra                  | registreringTil | virkningFra                      | virkningTil                      | status   |
      | guid-C-1   | 2020-01-01T01:01:01.111111+01:00 |                 | 2020-01-01T01:01:01.000000+01:00 | 2020-01-02T01:01:01.111111+01:00 | Gældende |
    When file extract is loaded in the DAF database
    Then the database table Lodflade should contain rows with the following entries
      | id_lokalId | registreringFra                  | registreringTil | virkningFra                      | virkningTil                      | status   |
      | guid-C-1   | 2020-01-01T01:01:01.111111+01:00 |                 | 2020-01-01T01:01:01.000000+01:00 | 2020-01-02T01:01:01.111111+01:00 | Gældende |
