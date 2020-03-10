#!/usr/bin/env/python
import os
import ijson
import json
from zipfile import ZipFile
from pprint import pprint
import sqlite3
import contextlib
#from zipstream import ZipFile


def populate(connection, listName, list):
    print(f'populating {listName}')
    rows = 0
    for elem in list:
        columns = elem.keys()
        values = ['NULL' if (x is None) else f"'{x}'" for x in elem.values()]
        SQL = f" INSERT into {listName}({', '.join(columns)}) VALUES({', '.join(['?' for x in range(len(values))])});"
        try:
            connection.execute(SQL, values)
            rows += 1
            if rows % 100000 == 0:
                connection.commit()
        except Exception as e:
            print(SQL)
            raise e
    connection.commit()
    print(f'populating {listName} done with {rows} rows.')


def initialise_dar(db_name):
    with open("DAR_v2.3.6_2019.08.18_DLS/DAR_v2.3.6_2019.08.19_DARTotal.schema.json", 'rb') as file:
        jsonschema = json.load(file)
    conn = sqlite3.connect(db_name)
    conn.execute("PRAGMA encoding = 'UTF-8';")
    conn.commit()
    for (table_name, table_content) in jsonschema['properties'].items():
        assert (table_content['type'] == 'array')
        SQL = f"CREATE TABLE {table_name} (\n"
        for (att_name, att_content) in table_content['items']['properties'].items():
            SQL += f"  {att_name: <20} {'TEXT': <10},\n"
        SQL += "\n"
        SQL += "  PRIMARY KEY(id_lokalId, registreringFra, virkningFra)\n"
        SQL += ");\n"
        conn.execute(SQL)
    conn.commit()
    conn.close()


def main(data_package: 'file path to the zip datapackage',
         create: ("Create the database", 'flag', 'c'),
         force: ("Force the DB creation", 'flag', 'f'),
         db_name: 'Database file' = 'dar.db'):
    """Loads a DAR data file into database"""
    if not data_package[-4:] == '.zip':
        raise ValueError("data_package must be a zip file and end with '.zip'")
    package_name = data_package[:-4]
    print(f'Loading data from {package_name}')
    if create:
        if force:
            with contextlib.suppress(FileNotFoundError):
                print("Deleting DB")
                os.remove(db_name)
        print("Creating DB")
        initialise_dar(db_name)

    conn = sqlite3.connect(db_name)
    with ZipFile(data_package, 'r') as myzip:
        #for info in myzip.infolist():
        #    print(info.filename)
        json_data_name = next(x for x in myzip.namelist() if not 'Metadata' in x)
        with myzip.open(json_data_name) as file:
            for (listName, list) in ijson.kvitems(file, ''):
                populate(conn, listName, list)
    conn.close()


if __name__ == '__main__':
    import plac; plac.call(main)
