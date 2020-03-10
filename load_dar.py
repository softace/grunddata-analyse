#!/usr/bin/env/python
import os
import ijson
import json
from zipfile import ZipFile
from pprint import pprint
import sqlite3
import contextlib
import time
#from zipstream import ZipFile
step_rows = 1000000


def insert_row(connection, listName, row):
    columns = row.keys()
    values = ['NULL' if (x is None) else x for x in row.values()]
    SQL = f" INSERT into {listName} ({', '.join(columns)}) VALUES({', '.join(['?' for x in range(len(values))])});"
    try:
        connection.execute(SQL, values)
    except Exception as e:
        print(SQL)
        raise e
    return


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
            parser = ijson.parse(file)
            db_table_name = None
            db_row = None
            db_column = None
            rows = 0
            start_time = time.time()
            step_time = time.time()
            for prefix, event, value in parser:
                if event == 'map_key':
                    if '.' in prefix:
                        db_column = value
                    else:
                        db_table_name = value
                        print(f"Inserting into {db_table_name}")
                if event == 'end_array':
                    print(f"{rows} rows inserted into {db_table_name}")
                    rows = 0
                    db_table_name = None
                if '.' in prefix and event == 'start_map':
                    db_row = {}
                if '.' in prefix and event == 'end_map':
                    insert_row(conn, db_table_name, db_row)
                    db_row = None
                    rows += 1
                    if rows % step_rows == 0:
                        prev_step_time = step_time
                        step_time = time.time()
                        print(f"{rows} rows inserted into {db_table_name}. {step_rows//(step_time - prev_step_time)} rows/sec")
                if event == 'string':
                    db_row[db_column] = value
                    db_column = None
    conn.commit()
    conn.close()


if __name__ == '__main__':
    import plac; plac.call(main)
