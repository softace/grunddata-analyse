import os
from zipfile import ZipFile
import json
from jinja2 import Environment, PackageLoader, select_autoescape
from expects import *

import sqlite3
import load_daf

from behave import *

temp_env = Environment(
    loader=PackageLoader('load_daf', 'features/steps'),
    autoescape=select_autoescape(['json'])
)

dummy_data = {'Postnummer': {
                                "forretningshændelse": "4",
                                "forretningsområde": "54.15.10.25",
                                "forretningsproces": "0",
                                "id_namespace": "http://data.gov.dk/dar/postnummer",
                                "id_lokalId": "INSERT",
                                "registreringFra": "",  # "YYYY-MM-DDTHH:mm:ss:SSSSSS+01:00",
                                "registreringsaktør": "DAR",
                                "registreringTil": "INSERT",
                                "status": "3",
                                "virkningFra": "INSERT",
                                "virkningsaktør": "Konvertering2017",
                                "virkningTil": "INSERT",
                                "navn": "København K",
                                "postnr": "1407",
                                "postnummerinddeling": "191407"
                            }
}

@given(u'a {registry} file extract zip file with metadata')
def step_impl(context, registry):
    context.registry = registry
    context.data_file = {}
    start_datetime = '202001010400'
    context.file_extract_file_name = f'{context.registry}_Totaludtræk_1_abonnement_{start_datetime}'
    context.metadata_content = temp_env.get_template('Metadata_template.json').render({'file_extract_file_name':context.file_extract_file_name,
                                                                                   'registry':context.registry,
                                                                               })

@given(u'the file extract contains data for {table_name} with dummy data and')
def step_impl(context, table_name):
    for row in context.table:
        if table_name not in context.data_file.keys():
            context.data_file[table_name+'List'] = []
        context.data_file[table_name+'List'].append({**dummy_data[table_name], **dict(zip(row.headings, row.cells))})

@when(u'file extract is loaded')
def step_impl(context):
    context.file_extract_name = f"{context.file_extract_file_name}.zip"
    ##    file_like_object = io.BytesIO(my_zip_data)
    context.file_extract = ZipFile(context.file_extract_name, 'w')
    with context.file_extract as f:
        f.writestr(f'{context.file_extract_file_name}_Metadata.json', context.metadata_content)
        print(json.dumps(context.data_file))
        f.writestr(f'{context.file_extract_file_name}.json', json.dumps(context.data_file))
    context.behave_db=f'behave_{context.registry}'
    load_daf.main(initialise=True,
                  wipe=True,
                  db_backend='sqlite',
                  db_host=None,
                  db_port=None,
                  db_name=context.behave_db,
                  db_user=None,
                  db_password=None,
                  data_package=context.file_extract_name);

@then(u'the database table {table_name} should contain rows with the following entries')
def step_impl(context, table_name):
#    context.behave_db
    conn = sqlite3.connect(context.behave_db + '.db')
    conn.execute("PRAGMA encoding = 'UTF-8';")
    result = conn.execute(f'select * from {table_name}')
    for expected_row in context.table:
        cursor = conn.execute(f'select * from {table_name} where id_lokalId = ? and registreringFra = ? and virkningFra = ?',
                              [expected_row['id_lokalId'], expected_row['registreringFra'], expected_row['virkningFra']])
        rows = cursor.fetchall()
        expect(len(rows)).to(equal(1))
        actual = dict(zip([x[0] for x in cursor.description], rows[0]))
        for i, col_name in enumerate(context.table.headings):
            expect(actual[col_name]).to(equal(expected_row.cells[i]))
    if os.path.isfile(f'behave_{context.registry}.db'):
        os.remove(f'behave_{context.registry}.db')

