# Created by jarl at 04/08/2020
Feature: Ensure single data-load and correct order
  Loading a file it must ensure that data is loaded in correct order.

  Background: An initial file extract is loaded into the DB
    Given I initialize the DAF database
    Given a DAR file extract zip file with metadata for day 0
    Given the file extract contains data for Postnummer with dummy data and:
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | 2020-01-01T01:01:01.111111+01:00 |                                  | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
    And file extract is loaded in the DAF database

  Scenario: Initial file-extract on empty DB will load
    Then the database table Postnummer should contain rows with the following entries:
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | 2020-01-01T01:01:01.111111+01:00 |                                  | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
    Then the database table file_extract should contain rows with the following entries and no more:
      | zip_file_name                                 |
      | DAR_Totaludtræk_1_abonnement_202001010400.zip |
    Then the database table metadata should contain rows with the following entries:
      | key                                               | value                         |
      | DatafordelerUdtraekstidspunkt[0].deltavindueStart | 1900-01-01T00:00:00.000+00:00 |

  Scenario: Initial file-extract on non-empty DB should fail

  Scenario: in-sequnce file-extract on empty DB should fail

  Scenario: in-sequnce file-extract on in incomplete earlier load should fail

  Scenario: in-sequnce file-extract on in correct order will load
