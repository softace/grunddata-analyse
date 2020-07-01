# Introduction
This is a small handy utility to analyze data from Datafordeleren

Currently it only support DAR, BBR, MATRIKEL

The postgres backend is currently not working. Only sqlite backed is maintained for now.
# Getting started

Initialise python venv:
```shell script
. venv/bin/activate
pip install -r requirements.txt
```

# Sample run
```shell script
python load_daf.py -i -b sqlite DAR_Totaludtraek_1_0_1_abonnement_20200626040000.zip
```

# Handy shell tips

## Fetch an instance from JSON:
```shell script
cat DAR_Totaludtraek_1_0_1_abonnement_20200505040000.json | grep -B 5 -A 26 '"id_lokalId":"0a3f508f-047f-32b8-e044-0003ba298018",' | grep -B 6 -A 25 '"registreringFra":"2018-09-05T13:47:30.795832+02:00",' | grep -B 10 -A 21 '"virkningFra":"2018-09-05T13:47:30.795832+02:00"' | grep -B 4 -A 27 '"id_namespace":"http://data.gov.dk/dar/husnummer"'
```
