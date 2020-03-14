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
STEP_ROWS = 1000000

table_names = {}

def insert_row(cursor, listName, row):
    if row['id_lokalId'] is None or row['registreringFra'] is None or row['virkningFra'] is None:
        raise ValueError(f"Forventet primær nøgle (id_lokalId, registreringFra, virkningFra) har egentlig værdier, men fandt ({row['id_lokalId']}, {row['registreringFra']}, {row['virkningFra']})")
    if row['virkningTil']: #This is an update
        cursor.execute(table_names[listName]['F'], [row['id_lokalId'], row['registreringFra'], row['virkningFra']])
        rows = cursor.fetchall()
        if len(rows) > 1:
            raise ValueError(f"Forventet at opdatere een forekomst for ({row['id_lokalId']}, {row['registreringFra']}, {row['virkningFra']}), fandt {len(rows)} forekomster")
        else:
            cursor.execute(table_names[listName]['U'], list(row.values()) + [row['id_lokalId'], row['registreringFra'], row['virkningFra']])
            return 1
    else:
        print(table_names[listName]['V'])
        pprint([row['registreringFra'], row['registreringTil'], row['virkningFra'], row['virkningTil']])
        cursor.execute(table_names[listName]['V'], [row['registreringFra'], row['registreringTil'], row['virkningFra'], row['virkningTil']])
        violations = cursor.fetchall()
        if len(violations) > 0:
            raise ValueError(f"Der findes allerede en forekomst i registreringstid ({row['registreringFra']}; {row['registreringTil']}) og virkningstid({row['virkningFra']}, {row['virkningTil']})")
        cursor.execute(table_names[listName]['I'], list(row.values()))
        return 0


def prepare_table(table_name, columns):
    table_names[table_name] = {}
    table_names[table_name]['F'] = "select id_lokalId, registreringFra, virkningFra " \
                                   f"from {table_name} where true " \
                                   "AND id_lokalId = ? " \
                                   "AND registreringFra = ? " \
                                   "AND virkningFra = ?"
    table_names[table_name]['U'] = f"update {table_name} set " + \
                                   ", ".join([f" {c} = ? " for c in columns]) + " where true "\
                                   "AND id_lokalId = ? " \
                                   "AND registreringFra = ? " \
                                   "AND virkningFra = ?"
    table_names[table_name]['V'] = f"select *, ? _RegistreringFra, ? _RegistreringTil, ? _VirkningFra, ? _VirkningTil from {table_name} where true " \
                                   "AND ( registreringFra <= _RegistreringFra AND (_RegistreringFra <  registreringTil OR  registreringTil is NULL) "\
                                   "  OR _RegistreringFra <=  registreringFra AND ( registreringFra < _RegistreringTil OR _RegistreringTil is NULL)) "\
                                   "AND ( virkningFra <= _VirkningFra AND (_VirkningFra <  virkningTil OR  virkningTil is NULL) "\
                                   "  OR _VirkningFra <=  virkningFra AND ( virkningFra < _VirkningFra OR _VirkningFra is NULL)) "
    table_names[table_name]['I'] = f" INSERT into {table_name} ({', '.join(columns)})"\
                                   f" VALUES({', '.join(['?' for x in range(len(columns))])});"


def initialise_dar(db_name, create=False):
    with open("DAR_v2.3.6_2019.08.18_DLS/DAR_v2.3.6_2019.08.19_DARTotal.schema.json", 'rb') as file:
        jsonschema = json.load(file)
    conn = None
    if create:
        conn = sqlite3.connect(db_name)
        conn.execute("PRAGMA encoding = 'UTF-8';")
        conn.commit()
    for (table_name, table_content) in jsonschema['properties'].items():
        assert (table_content['type'] == 'array')
        columns = []
        SQL = f"CREATE TABLE {table_name} (\n"
        for (att_name, att_content) in table_content['items']['properties'].items():
            columns.append(att_name)
            SQL += f"  {att_name: <20} {'TEXT': <10},\n"
        SQL += "\n"
        SQL += "  PRIMARY KEY(id_lokalId, registreringFra, virkningFra)\n"
        SQL += ");\n"
        prepare_table(table_name, columns)
        if create:
            conn.execute(SQL)
    if create:
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
    initialise_dar(db_name, create)

    conn = sqlite3.connect(db_name)
    cursor = conn.cursor()
    with ZipFile(data_package, 'r') as myzip:
        #for info in myzip.infolist():
        #    print(info.filename)
        json_data_name = next(x for x in myzip.namelist() if not 'Metadata' in x)
        with myzip.open(json_data_name) as file:
            parser = ijson.parse(file)
            db_table_name = None
            db_row = None
            db_column = None
            row_inserts = 0
            row_updates = 0
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
                    print(f"{row_inserts} rows inserted into {db_table_name}")
                    print(f"{row_updates} rows updated  in   {db_table_name}")
                    row_inserts = 0
                    row_updates = 0
                    db_table_name = None
                if '.' in prefix and event == 'start_map':
                    db_row = {}
                if '.' in prefix and event == 'end_map':
                    ret = insert_row(cursor, db_table_name, db_row)
                    db_row = None
                    if ret == 0:
                        row_inserts += 1
                    else:
                        row_updates += 1
                    if (row_inserts + row_updates) % STEP_ROWS == 0:
                        prev_step_time = step_time
                        step_time = time.time()
                        print(f"{(row_inserts + row_updates):>10} rows inserted/updated in {db_table_name}. {int(STEP_ROWS // (step_time - prev_step_time))} rows/sec")
                if event in ['null', 'boolean', 'integer', 'double', 'number',  'string']:
                    db_row[db_column] = value
                    db_column = None
    conn.commit()
    conn.close()


if __name__ == '__main__':
    import plac; plac.call(main)
