# Created by jarl at 04/08/2020
Feature: Loading on empty DB
  # Enter feature description here

  Background: An initial file extract is loaded into the DB
    Given I initialize the DAF database
    Then the database table registry_tables should contain rows with the following entries and no more
      | registry | table_name                        |
      | BBR      | BBRSag                        |
      | BBR      | BygningEjendomsrelation       |
      | BBR      | Bygning                       |
      | BBR      | Ejendomsrelation              |
      | BBR      | EnhedEjendomsrelation         |
      | BBR      | Enhed                         |
      | BBR      | Etage                         |
      | BBR      | FordelingAfFordelingsareal    |
      | BBR      | Fordelingsareal               |
      | BBR      | GrundJordstykke               |
      | BBR      | Grund                         |
      | BBR      | Opgang                        |
      | BBR      | Sagsniveau                    |
      | BBR      | TekniskAnlæg                  |
      | DAR      | Adresse                       |
      | DAR      | Adressepunkt                  |
      | DAR      | Husnummer                     |
      | DAR      | NavngivenVejKommunedel        |
      | DAR      | NavngivenVej                  |
      | DAR      | NavngivenVejPostnummer        |
      | DAR      | NavngivenVejSupplerendeBynavn |
      | DAR      | Postnummer                    |
      | DAR      | SupplerendeBynavn             |
    Given a DAR file extract zip file with metadata for day 0
    Given the file extract contains data for Postnummer with dummy data and:
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | 2020-01-01T01:01:01.111111+01:00 |                                  | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
    And file extract is loaded in the DAF database

  Scenario: The initial file-extract is loaded correctly
    Then the database table Postnummer should contain rows with the following entries:
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | 2020-01-01T01:01:01.111111+01:00 |                                  | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
    Then the database table file_extract should contain rows with the following entries and no more:
      | zip_file_name                                 |
      | DAR_Totaludtræk_1_abonnement_202001010400.zip |
    Then the database table metadata should contain rows with the following entries:
      | key                                               | value                         |
      | DatafordelerUdtraekstidspunkt[0].deltavindueStart | 1900-01-01T00:00:00.000+00:00 |

      Scenario: in-sequnce file-extract on empty DB should fail

  Scenario: Another initial file extract from another registry is loaded into the DB
    Given a BBR file extract zip file with metadata for day 0
    Given the file extract contains data for Grund with dummy data and:
      | id_lokalId | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | 2020-01-01T01:01:01.111111+01:00 |                                  | 2020-01-01T01:01:01.111111+01:00 | 2020-01-02T01:01:01.111111+01:00 |
    And file extract is loaded in the DAF database
