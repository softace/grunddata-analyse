# Introduction
This is a small handy utility to analyze data from Datafordeleren

Currently it only support DAR, BBR, MAT, EBR

The postgres backend is currently not working. Only sqlite backed is maintained for now.

# Analysis
From a subscription with daily delta deliveries, the utility loads the delivery files into an accumulating database.
It validates the bitemporal validity of the data content of the delivery packages and registers occurances of violations.
The violations is ergistered in the table `violation_log`.

The following violations are registered:
* Violation of positive time interval (on registreringstid and virkningstid).
* Violation of bitemporal entity integrity (aka bitemporal conflict). That is violation of entity integrity fore some bitemporal time coordinates.
* Violation of Update requirements. Only one type of update is allowed for a data-instance: Changing `registreringTil` from NULL to an actual value.

Violations not implemented yet:
* Violation of bitemporal referential integrity. That is violation of referential integrity fore some bitemporal time coordinates.


# Getting started

Initialise python venv and open a shell:
```shell script
pipenv --three
pipenv install
pipenv shell
```

# Sample runs

Get help
```shell script
python load_daf.py -h
```

Create database for analysis
```shell script
python load_daf.py -i -b sqlite -d minDAF
```

Analyse one (DAR) file on database 'minDAF'.
This assumes that you have fetched a data package for your subscription from the datafordeler FTP server
```shell script
python load_daf.py -b sqlite -d minDAF DAR_Totaludtraek_1_0_1_abonnement_20200626040000.zip
```

# Development
There is a minimialistic test-suite that should be run with
```shell script
behave
```

# Handy shell tips

## Fetch an instance from JSON:
```shell script
cat DAR_Totaludtraek_1_0_1_abonnement_20200505040000.json | grep -B 5 -A 26 '"id_lokalId":"0a3f508f-047f-32b8-e044-0003ba298018",' | grep -B 6 -A 25 '"registreringFra":"2018-09-05T13:47:30.795832+02:00",' | grep -B 10 -A 21 '"virkningFra":"2018-09-05T13:47:30.795832+02:00"' | grep -B 4 -A 27 '"id_namespace":"http://data.gov.dk/dar/husnummer"'
```

# License
See the [LICENSE](LICENSE) file. If you are interested in other licenses, please contact support.

# Support
For further support and assistance, please contact [jarl@softace.dk](mailto:jarl@softace.dk)
