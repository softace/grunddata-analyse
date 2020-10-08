Feature: Bitemporal data integrity with composite bitemporalprimary key

  Background: A DAF database with one entry for a closed rectangle
    Given I initialize the DAF database
    Given a MAT file extract zip file with metadata for day 0
    Given the file extract contains data for Ejerlav with dummy data and
      | id_lokalId | status   | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | Gældende | 2020-01-01T00:12:01.111111-01:00 | 2020-01-01T00:15:01.111111-01:00 | 2000-01-01T00:12:01.111111-01:00 | 2000-01-01T00:15:01.111111-01:00 |
      | guid-1     | Gældende | 2020-01-01T00:12:01.111111-01:00 |                                  | 2000-01-01T00:12:01.111111-01:00 |                                  |
    And file extract is loaded in the DAF database
    Then the database table Ejerlav should contain rows with the following entries and no more
      | id_lokalId | status   | registreringFra_UTC              | registreringTil_UTC              | virkningFra_UTC                  | virkningTil_UTC                  |
      | guid-0     | Gældende | 2020-01-01T01:12:01.111111+00:00 | 2020-01-01T01:15:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2000-01-01T01:15:01.111111+00:00 |
      | guid-1     | Gældende | 2020-01-01T01:12:01.111111+00:00 |                                  | 2000-01-01T01:12:01.111111+00:00 |                                  |

  Scenario: 8 different bitemporal integrity issues on a closed rectangle
    Given a MAT file extract zip file with metadata for day 1
    Given the file extract contains data for Ejerlav with dummy data and
    # positive circular direction, starting at left-bottom.
      | id_lokalId | status   | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-0     | Gældende | 2020-01-01T03:11:01.111111+02:00 | 2020-01-01T03:13:01.111111+02:00 | 2000-01-01T03:11:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 |
      | guid-0     | Gældende | 2020-01-01T03:13:01.111111+02:00 | 2020-01-01T03:14:01.111111+02:00 | 2000-01-01T03:11:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 |
      | guid-0     | Gældende | 2020-01-01T03:14:01.111111+02:00 | 2020-01-01T03:16:01.111111+02:00 | 2000-01-01T03:11:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 |
      | guid-0     | Gældende | 2020-01-01T03:14:01.111111+02:00 | 2020-01-01T03:16:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 | 2000-01-01T03:14:01.111111+02:00 |
      | guid-0     | Gældende | 2020-01-01T03:14:01.111111+02:00 | 2020-01-01T03:16:01.111111+02:00 | 2000-01-01T03:14:01.111111+02:00 | 2000-01-01T03:16:01.111111+02:00 |
      | guid-0     | Gældende | 2020-01-01T03:13:01.111111+02:00 | 2020-01-01T03:14:01.111111+02:00 | 2000-01-01T03:14:01.111111+02:00 | 2000-01-01T03:16:01.111111+02:00 |
      | guid-0     | Gældende | 2020-01-01T03:11:01.111111+02:00 | 2020-01-01T03:13:01.111111+02:00 | 2000-01-01T03:14:01.111111+02:00 | 2000-01-01T03:16:01.111111+02:00 |
      | guid-0     | Gældende | 2020-01-01T03:11:01.111111+02:00 | 2020-01-01T03:13:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 | 2000-01-01T03:14:01.111111+02:00 |
    When file extract is loaded in the DAF database
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | status   | registreringFra_UTC              | virkningFra_UTC                  | violation_type                 | conflicting_registreringFra_UTC  | conflicting_virkningFra_UTC      |
      | 1  | Ejerlav    | guid-0     | Gældende | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | Bitemporal entitets-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | 2  | Ejerlav    | guid-0     | Gældende | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | Bitemporal entitets-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | 3  | Ejerlav    | guid-0     | Gældende | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | Bitemporal entitets-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | 4  | Ejerlav    | guid-0     | Gældende | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 | Bitemporal entitets-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | 5  | Ejerlav    | guid-0     | Gældende | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 | Bitemporal entitets-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | 6  | Ejerlav    | guid-0     | Gældende | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 | Bitemporal entitets-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | 7  | Ejerlav    | guid-0     | Gældende | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 | Bitemporal entitets-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | 8  | Ejerlav    | guid-0     | Gældende | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 | Bitemporal entitets-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |

  Scenario: 4 different bitemporal integrity issues on an double open rectangle
  Bitemporal integrity is resolved in 3/4 on invalid update

    Given a MAT file extract zip file with metadata for day 1
    Given the file extract contains data for Ejerlav with dummy data and
    # positive circular direction, starting at left-bottom.
      | id_lokalId | status   | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-1     | Gældende | 2020-01-01T03:11:01.111111+02:00 | 2020-01-01T03:13:01.111111+02:00 | 2000-01-01T03:11:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 |
      | guid-1     | Gældende | 2020-01-01T03:13:01.111111+02:00 | 2020-01-01T03:14:01.111111+02:00 | 2000-01-01T03:11:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 |
      | guid-1     | Gældende | 2020-01-01T03:14:01.111111+02:00 | 2020-01-01T03:16:01.111111+02:00 | 2000-01-01T03:14:01.111111+02:00 | 2000-01-01T03:16:01.111111+02:00 |
      | guid-1     | Gældende | 2020-01-01T03:11:01.111111+02:00 | 2020-01-01T03:13:01.111111+02:00 | 2000-01-01T03:13:01.111111+02:00 | 2000-01-01T03:14:01.111111+02:00 |
    When file extract is loaded in the DAF database
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | status   | registreringFra_UTC              | virkningFra_UTC                  | violation_type                 | conflicting_registreringFra_UTC  | conflicting_virkningFra_UTC      |
      | 1  | Ejerlav    | guid-1     | Gældende | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | Bitemporal entitets-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | 2  | Ejerlav    | guid-1     | Gældende | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | Bitemporal entitets-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | 3  | Ejerlav    | guid-1     | Gældende | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 | Bitemporal entitets-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | 4  | Ejerlav    | guid-1     | Gældende | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 | Bitemporal entitets-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
    Given a MAT file extract zip file with metadata for day 2
    Given the file extract contains data for Ejerlav with dummy data and
      # The original open is closed with a minimal positive registrering interval
      | id_lokalId | status   | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      | guid-1     | Gældende | 2020-01-01T00:12:01.111111-01:00 | 2020-01-01T00:12:01.111112-01:00 | 2000-01-01T00:12:01.111111-01:00 | 2000-01-01T00:12:01.111112-01:00 |
    Then file extract is loaded in the DAF database
    Then the database table Ejerlav should contain rows with the following entries and no more
      | id_lokalId | status   | registreringFra_UTC              | registreringTil_UTC              | virkningFra_UTC                  | virkningTil_UTC                  |
      | guid-0     | Gældende | 2020-01-01T01:12:01.111111+00:00 | 2020-01-01T01:15:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2000-01-01T01:15:01.111111+00:00 |
      | guid-1     | Gældende | 2020-01-01T01:12:01.111111+00:00 | 2020-01-01T01:12:01.111112+00:00 | 2000-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111112+00:00 |
      | guid-1     | Gældende | 2020-01-01T01:11:01.111111+00:00 | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 |
      | guid-1     | Gældende | 2020-01-01T01:13:01.111111+00:00 | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 |
      | guid-1     | Gældende | 2020-01-01T01:14:01.111111+00:00 | 2020-01-01T01:16:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 | 2000-01-01T01:16:01.111111+00:00 |
      | guid-1     | Gældende | 2020-01-01T01:11:01.111111+00:00 | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 |
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | status   | registreringFra_UTC              | virkningFra_UTC                  | violation_type                 | conflicting_registreringFra_UTC  | conflicting_virkningFra_UTC      |
      | 1  | Ejerlav    | guid-1     | Gældende | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | Bitemporal entitets-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | 2  | Ejerlav    | guid-1     | Gældende | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | Bitemporal entitets-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | 3  | Ejerlav    | guid-1     | Gældende | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 | Bitemporal entitets-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | 4  | Ejerlav    | guid-1     | Gældende | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 | Bitemporal entitets-integritet | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 |
      | 5  | Ejerlav    | guid-1     | Gældende | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | Ugyldig opdatering af værdier  |                                  |                                  |
      | 6  | Ejerlav    | guid-1     | Gældende | 2020-01-01T01:12:01.111111+00:00 | 2000-01-01T01:12:01.111111+00:00 | Bitemporal entitets-integritet | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 |

  Scenario: Zero and negative intervals should never a bitemporal conflict
    Given a MAT file extract zip file with metadata for day 1
    Given the file extract contains data for Ejerlav with dummy data and
      | id_lokalId | status   | registreringFra                  | registreringTil                  | virkningFra                      | virkningTil                      |
      # A zero registreringstid
      | guid-0     | Gældende | 2020-01-01T01:13:01.111111+00:00 | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 |                                  |
      # A zero virkningstid
      | guid-0     | Gældende | 2020-01-01T01:11:01.111111+00:00 |                                  | 2000-01-01T01:13:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 |
      # A negative registreringstid
      | guid-0     | Gældende | 2020-01-01T01:14:01.111111+00:00 | 2020-01-01T01:14:00.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 |                                  |
      # A negative virkningstid
      | guid-0     | Gældende | 2020-01-01T01:11:01.111111+00:00 |                                  | 2000-01-01T01:14:01.111111+00:00 | 2000-01-01T01:14:00.111111+00:00 |
    When file extract is loaded in the DAF database
    Then the database table violation_log should contain rows with the following entries and no more
      | id | table_name | id_lokalId | status   | registreringFra_UTC              | virkningFra_UTC                  | violation_type                      |
      | 1  | Ejerlav    | guid-0     | Gældende | 2020-01-01T01:13:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | Ikke-positivt registreringsinterval |
      | 2  | Ejerlav    | guid-0     | Gældende | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:13:01.111111+00:00 | Ikke-positivt virkningsinterval     |
      | 3  | Ejerlav    | guid-0     | Gældende | 2020-01-01T01:14:01.111111+00:00 | 2000-01-01T01:11:01.111111+00:00 | Ikke-positivt registreringsinterval |
      | 4  | Ejerlav    | guid-0     | Gældende | 2020-01-01T01:11:01.111111+00:00 | 2000-01-01T01:14:01.111111+00:00 | Ikke-positivt virkningsinterval     |
