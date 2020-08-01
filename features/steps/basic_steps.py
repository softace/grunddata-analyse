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

@given('I initialize the DAF database')
def step_impl(context):
    context.behave_db=f'behave_DAF'
    if os.path.isfile(f'behave_DAF.db'):
        os.remove(f'behave_DAF.db')
    load_daf.main(initialise=True,
                  wipe=False,
                  db_backend='sqlite',
                  db_host=None,
                  db_port=None,
                  db_name=context.behave_db,
                  db_user=None,
                  db_password=None,
                  data_package=None)

@given(u'a (?P<registry>.*?) file extract zip file with metadata for day (?P<start_day>\d+)')
def step_impl(context, registry, start_day):
    context.registry = registry
    context.data_file = {}
    start_datetime = '202001010400'
    deltavindue_start = f'1900-01-{int(start_day)+1:0>2}T00:00:00.000+00:00'
    context.file_extract_file_name = f'{context.registry}_Totaludtræk_1_abonnement_{start_datetime}'
    context.metadata_content = temp_env.get_template('Metadata_template.json').render({'file_extract_file_name':context.file_extract_file_name,
                                                                                       'registry':context.registry,
                                                                                       'deltavindue_start':deltavindue_start

                                                                               })

@given(u'the file extract contains data for (?P<table_name>.*?) with dummy data and')
def step_impl(context, table_name):
    listName = table_name + 'List'
    for row in context.table:
        if listName not in context.data_file.keys():
            context.data_file[listName] = []
        context.data_file[listName].append({**dummy_data[table_name], **dict(zip(row.headings, row.cells))})
        pass
    pass


@when(u'file extract is loaded in the DAF database')
@given(u'file extract is loaded in the DAF database')
def step_impl(context):
    context.file_extract_name = f"{context.file_extract_file_name}.zip"
    ##    file_like_object = io.BytesIO(my_zip_data)
    context.file_extract = ZipFile(context.file_extract_name, 'w')
    with context.file_extract as f:
        f.writestr(f'{context.file_extract_file_name}_Metadata.json', context.metadata_content)
        f.writestr(f'{context.file_extract_file_name}.json', json.dumps(context.data_file))
    load_daf.main(initialise=False,
                  wipe=False,
                  db_backend='sqlite',
                  db_host=None,
                  db_port=None,
                  db_name=context.behave_db,
                  db_user=None,
                  db_password=None,
                  data_package=context.file_extract_name)

@then(u'the database table (?P<table_name>.*?) should contain rows with the following entries(?P<no_more> and no more)?')
def step_impl(context, table_name, no_more):
#    context.behave_db
    conn = sqlite3paramstyle.connect(context.behave_db + '.db')
    conn.execute("PRAGMA encoding = 'UTF-8';")
    result = conn.execute(f'select * from {table_name}')
    for expected_row in context.table:
        sql = f'select * from {table_name} where ' + "and ".join([f"{h} = %({h})s " for h in context.table.headings])
        cursor = conn.execute(f'select * from {table_name} where ' + "and ".join([f"{h} = %({h})s " for h in context.table.headings]),
                              expected_row)
        rows = cursor.fetchall()
        expect(len(rows)).to(equal(1))
        actual = dict(zip([x[0] for x in cursor.description], rows[0]))
        for i, col_name in enumerate(context.table.headings):
            expect(actual[col_name]).to(equal(expected_row.cells[i]))
    if no_more:
        rows = conn.execute(f'select * from {table_name}').fetchall()
        expect(len(rows)).to(equal(len(context.table.rows)))
#    if os.path.isfile(f'behave_{context.registry}.db'):
#        os.remove(f'behave_{context.registry}.db')

