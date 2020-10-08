Feature: Ignoring obsolete entities
  Some registries has obsolete entities in the DLS files

  Scenario: Initialising DB with obsolete entities specified in MAT
    Given I initialize the DAF database

  Scenario: Loading file with data for obsolete entities, should give a warning
    Given I initialize the DAF database
    Given a MAT file extract zip file with metadata for day 0
    Given the file extract contains data for Lodflade with dummy data and
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T01:01:01.111111+01:00 |                                  | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
    Given the file extract contains data for Stormfald with dummy data and
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T01:01:01.111111+01:00 |                                  | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
    When file extract is loaded in the DAF database
    Then the database table Lodflade should contain rows with the following entries
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-1     | 2020-01-01T01:01:01.111111+01:00 |                                  | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
