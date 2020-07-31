Feature: Basic stuff
  Scenario: A simple DAR entry
    Given a DAR file extract zip file with metadata
    Given the file extract contains data for Postnummer with dummy data and:
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
    When file extract is loaded
    Then the database table Postnummer should contain rows with the following entries:
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
