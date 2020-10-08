import os
from zipfile import ZipFile
import json
from jinja2 import Environment, PackageLoader, select_autoescape
from expects import *

import sqlite3
import sqlite3paramstyle
import load_daf

from behave import *

use_step_matcher('re') # Use regularexpression

temp_env = Environment(
    loader=PackageLoader('load_daf', 'features/steps'),
    autoescape=select_autoescape(['json'])
)

dummy_data = {
    'Postnummer': {
        "forretningshændelse": "4",
        "forretningsområde": "54.15.10.25",
        "forretningsproces": "0",
        "id_namespace": "http://data.gov.dk/dar/postnummer",
        "id_lokalId": "GUID-DAR-ZERO",
        "registreringFra": "2001-01-01T01:01:01.123456+01:00",  # "YYYY-MM-DDTHH:mm:ss:SSSSSS+01:00",
        "registreringsaktør": "DAR",
        "registreringTil": None,
        "status": "3",
        "virkningFra": "2001-01-01T01:01:01.123456+01:00",
        "virkningsaktør": "Konvertering2017",
        "virkningTil": None,
        "navn": "København K",
        "postnr": "1407",
        "postnummerinddeling": "191407"
    },
    'Grund': {
        "forretningshændelse": "Grund",
        "forretningsområde": "54.15.05.05",
        "forretningsproces": "11",
        "id_namespace": "http://data.gov.dk/bbr/grund",
        "id_lokalId": "Guid_BBR-ZERO",
        "kommunekode": "0101",
        "registreringFra": "2001-01-01T01:01:01.123456+01:00",
        "registreringsaktør": "BBR",
        "registreringTil": None,
        "virkningFra": "2001-01-01T01:01:01.123456+01:00",
        "virkningsaktør": "Registerfører",
        "virkningTil": None,
        "status": "4",
        "gru009Vandforsyning": None,
        "gru010Afløbsforhold": None,
        "gru021Udledningstilladelse": None,
        "gru022MedlemskabAfSpildevandsforsyning": None,
        "gru023PåbudVedrSpildevandsafledning": None,
        "gru024FristVedrSpildevandsafledning": None,
        "gru025TilladelseTilUdtræden": None,
        "gru026DatoForTilladelseTilUdtræden": None,
        "gru027TilladelseTilAlternativBortskaffelseEllerAfledning": None,
        "gru028DatoForTilladelseTilAlternativBortskaffelseEllerAfledning": None,
        "gru029DispensationFritagelseIftKollektivVarmeforsyning": None,
        "gru030DatoForDispensationFritagelseIftKollektivVarmeforsyning": None,
        "gru500Notatlinjer": None,
        "husnummer": "0a3f507b-380d-32b8-e044-0003ba298018",
        "bestemtFastEjendom": "2d40bbc8-90ea-4be1-b1c1-f8893133d61a"
    },
    "Lodflade": {
        "datafordelerOpdateringstid": "2001-01-01T01:01:01.123456+01:00",
        "objectid": 8411477,
        "forretningshaendelse": "Afledt ændring",
        "forretningsomraade": "52.20.05",
        "forretningsproces": "Matrikulær sag",
        "id_namespace": "http://data.gov.dk/Matriklen/Lodflade",
        "id_lokalId": "Guid_MAT-ZERO",
        "paataenktHandling": "Ændring",
        "registreringFra": "2001-01-01T01:01:01.123456+01:00",
        "registreringsaktoer": "Matriklen",
        "registreringTil": None,
        "status": "Foreløbig",
        "virkningFra": "2001-01-01T01:01:01.123456+01:00",
        "virkningsaktoer": "dummy",
        "virkningTil": None,
        "jordstykkeLokalId": "1289174",
        "senesteSagLokalId": "100149329"
    },
    "Stormfald": {
        "datafordelerOpdateringstid": "2001-01-01T01:01:01.123456+01:00",
        "jordstykkeobjectid": None,
        "stormfaldobjectid": "",
    }

}

@given('I initialize the DAF database')
def step_impl(context):
    context.behave_db=f'behave_DAF'
    if os.path.isfile(f'{context.behave_db}.db'):
        os.remove(f'{context.behave_db}.db')
    load_daf.main(initialise=True,
                  db_backend='sqlite',
                  db_host=None,
                  db_port=None,
                  db_name=context.behave_db,
                  db_user=None,
                  db_password=None)

def deltavindue_from_day(day):
    deltavindue_start = '1900-01-01T00:00:00.000+00:00' if day == '0' else f'2020-01-{int(day)+1:0>2}T00:00:00.000+00:00'
    deltavindue_slut = f'2020-01-{int(day)+2:0>2}T00:00:00.000+00:00'
    return (deltavindue_start, deltavindue_slut)

@given(u'a (?P<registry>.*?) file extract zip file with metadata for day (?P<start_day>\d+)')
def step_impl(context, registry, start_day):
    (deltavindueStart, deltavindueSlut) = deltavindue_from_day(start_day)
    registry2tjenestenavn = {'DAR': 'DAR-Totaludtraek',
                             'BBR': 'BBR-Totaludtraek',
                             'MAT' : 'MUTotalUdtraekFlad',
                             'EBR' : 'EBREjendomsbeliggenhedSimpel',
                             }
    context.meta_data = {'registry': registry,
                         'tjenestenavn': registry2tjenestenavn[registry],
                         'abonnementnavn': f'{registry}_Totaludtræk_1_abonnement',
                         'deltavindueStart': deltavindueStart,
                         'deltavindueSlut': deltavindueSlut
                         }
    context.meta_data['leveranceNavn'] = f"{context.meta_data['abonnementnavn']}_202001010400"
    context.data_file = {}

@given(u'the file extract contains data for (?P<table_name>.*?) with dummy data and')
def step_impl(context, table_name):
    listName = table_name + 'List'
    for row in context.table:
        if listName not in context.data_file.keys():
            context.data_file[listName] = []
        context.data_file[listName].append({**dummy_data[table_name], **dict(zip(row.headings, row.cells))})
        pass
    pass


def generate_file_extract(meta_data, data_json):
    zip_file_extract_name = f"{meta_data['leveranceNavn']}.zip"
    ##    file_like_object = io.BytesIO(my_zip_data)
    file_extract = ZipFile(zip_file_extract_name, 'w')
    with file_extract as f:
        f.writestr(f"{meta_data['leveranceNavn']}.json", json.dumps(data_json))
        f.writestr(f"{meta_data['leveranceNavn']}_Metadata.json", temp_env.get_template('Metadata_template.json').render(meta_data))



@when(u'file extract is loaded in the DAF database(?P<fails> fails)?')
@given(u'file extract is loaded in the DAF database(?P<fails> fails)?')
@then(u'file extract is loaded in the DAF database(?P<fails> fails)?')
def step_impl(context, fails):
    generate_file_extract(context.meta_data, context.data_file)
    load = lambda : load_daf.main(False,
                                  'sqlite',
                                  None,
                                  None,
                                  context.behave_db,
                                  None,
                                  None,
                                  f"{context.meta_data['leveranceNavn']}.zip")
    if not fails:
        load()
#        expect(load).not_to(raise_error)
    else:
        expect(load).to(raise_error)

@then(u'the database table (?P<table_name>.*?) should contain rows with the following entries(?P<no_more> and no more)?')
def step_impl(context, table_name, no_more):
#    context.behave_db
    conn = sqlite3paramstyle.connect(context.behave_db + '.db')
    conn.execute("PRAGMA encoding = 'UTF-8';")
    result = conn.execute(f'select * from {table_name}')
    for e_row in context.table:
        expected_row = dict([(k,v) for k, v in e_row.items() if v != ''])
        sql = f'select * from {table_name} where ' + "and ".join([f"{h} = %({h})s " for h in context.table.headings])
        cursor = conn.execute(f'select * from {table_name} where ' + "and ".join([f"{k} = %({k})s " for k in expected_row.keys()]),
                              expected_row)
        rows = cursor.fetchall()
        expect(len(rows)).to(equal(1))
        actual = dict(zip([x[0] for x in cursor.description], rows[0]))
        for col_name in expected_row.keys():
            expect(str(actual[col_name])).to(equal(expected_row[col_name]))
    if no_more:
        rows = conn.execute(f'select * from {table_name}').fetchall()
        expect(len(rows)).to(equal(len(context.table.rows)))
#    if os.path.isfile(f'behave_{context.registry}.db'):
#        os.remove(f'behave_{context.registry}.db')

@given(u'this list of file extracts')
def step_impl(context):
    context.file_extract_list = []
    for row in context.table:
        (deltavindueStart, deltavindueSlut) = deltavindue_from_day(row['day'])
#        file_datetime = row['file_name'][-18:-4]
        assert row['registry'] == row['file_name'][:3]
        leveranceNavn = f"{row['file_name'][:-4]}"
        abonnementNavn = leveranceNavn[:-14]
        meta_data = {'leveranceNavn': leveranceNavn,
                     'abonnementnavn': abonnementNavn,
                     'registry': row['registry'],
                     'tjenestenavn': row['registry'] + '-Totaludtraek',
                     'deltavindueStart': deltavindueStart,
                     'deltavindueSlut': deltavindueSlut
                     }
        data_file = {}
        table_name = None
        if row['registry'] == 'DAR':
            table_name = 'Postnummer'
        elif row['registry'] == 'BBR':
            table_name = 'Grund'
        else:
            raise NotImplementedError
        list_name = table_name + 'List'
        data_file[list_name] = []
        data_file[list_name].append({**dummy_data[table_name]})
        generate_file_extract(meta_data, data_file)
        context.file_extract_list.append(row['file_name'])


@when(u'file extracts is loaded in the DAF database')
def step_impl(context):
    load_daf.main(False,
                  'sqlite',
                  None,
                  None,
                  context.behave_db,
                  None,
                  None,
                  *context.file_extract_list
                  )
