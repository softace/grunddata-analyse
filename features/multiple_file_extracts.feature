Feature: Loading multiple file extracts in one go.
  The loader can take multiple file extract file name arguments and load them in order of date and then by subscription name

  Background: A set of file_extracts
    Given I initialize the DAF database
    Given this list of file extracts:
      | registry | file_name                                      | day |
      | DAR      | DAR_Totaludtraek_abonnement_20200101010000.zip | 0   |
      | DAR      | DAR_Totaludtraek_abonnement_20200102010000.zip | 1   |
      | BBR      | BBR_Totaludtraek_abonnement_20200101010000.zip | 0   |
      | BBR      | BBR_Totaludtraek_abonnement_20200102010000.zip | 1   |

  Scenario: Providing four file names based on Datafordeler naming convention
    When file extracts is loaded in the DAF database
    Then the database table file_extract should contain rows with the following entries and no more:
      | id | zip_file_name                                  |
      | 1  | BBR_Totaludtraek_abonnement_20200101010000.zip |
      | 2  | DAR_Totaludtraek_abonnement_20200101010000.zip |
      | 3  | BBR_Totaludtraek_abonnement_20200102010000.zip |
      | 4  | DAR_Totaludtraek_abonnement_20200102010000.zip |

  Scenario: Repeated loading is ignored.
    When file extracts is loaded in the DAF database
    Given this list of file extracts:
      | registry | file_name                                      | day |
      | DAR      | DAR_Totaludtraek_abonnement_20200102010000.zip | 1   |
      | BBR      | BBR_Totaludtraek_abonnement_20200102010000.zip | 1   |
    When file extracts is loaded in the DAF database
    Then the database table file_extract should contain rows with the following entries and no more:
      | id | zip_file_name                                  |
      | 1  | BBR_Totaludtraek_abonnement_20200101010000.zip |
      | 2  | DAR_Totaludtraek_abonnement_20200101010000.zip |
      | 3  | BBR_Totaludtraek_abonnement_20200102010000.zip |
      | 4  | DAR_Totaludtraek_abonnement_20200102010000.zip |
    # Repeating some files are ignored
