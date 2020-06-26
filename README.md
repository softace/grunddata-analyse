
# Handy shell tips

## Fetch an instance from JSON:
```shell script
cat DAR_Totaludtraek_1_0_1_abonnement_2_20200505040000.json | grep -B 5 -A 26 '"id_lokalId":"0a3f508f-047f-32b8-e044-0003ba298018",' | grep -B 6 -A 25 '"registreringFra":"2018-09-05T13:47:30.795832+02:00",' | grep -B 10 -A 21 '"virkningFra":"2018-09-05T13:47:30.795832+02:00"' | grep -B 4 -A 27 '"id_namespace":"http://data.gov.dk/dar/husnummer"'
```
