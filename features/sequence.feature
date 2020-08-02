Feature: On a non-empty database the sequence shall be in date order
  Loading a file it must ensure that data is loaded in correct order.

  Background: An initial file extract is loaded into the DB
    Given I initialize the DAF database
    Given a DAR file extract zip file with metadata for day 0
    Given the file extract contains data for Postnummer with dummy data and:
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | 2020-01-01T01:01:01.111111+01:00 |                                  | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
    And file extract is loaded in the DAF database

  Scenario: in-sequnce file-extract on incomplete earlier load should fail

  Scenario: in-sequnce file-extract on initial will load
    Given a DAR file extract zip file with metadata for day 1
    Given the file extract contains data for Postnummer with dummy data and:
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T01:01:01.111111+01:00 |                                  | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
    Then file extract is loaded in the DAF database

  Scenario: in-sequnce file-extract on initial will load
    Given a DAR file extract zip file with metadata for day 1
    Given the file extract contains data for Postnummer with dummy data and:
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T01:01:01.111111+01:00 |                                  | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
    Then file extract is loaded in the DAF database
    Given a DAR file extract zip file with metadata for day 2
    Given the file extract contains data for Postnummer with dummy data and:
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-2     | 2020-01-01T01:01:01.111111+01:00 |                                  | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
    Then file extract is loaded in the DAF database
    Then the database table metadata should contain rows with the following entries:
      | key                                               | value                         |
      | DatafordelerUdtraekstidspunkt[0].deltavindueStart | 2020-01-03T00:00:00.000+00:00 |

  Scenario: Initial file-extract on non-empty DB should fail
    Given a DAR file extract zip file with metadata for day 0
    Given the file extract contains data for Postnummer with dummy data and:
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T01:01:01.111111+01:00 |                                  | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
    Then file extract is loaded in the DAF database fails

