#!/usr/bin/env/python
import os
import ijson
import json
from zipfile import ZipFile
from pprint import pprint
import sqlite3
import contextlib
import time
from datetime import timezone
import dateutil.parser
STEP_ROWS = 1000000

table_names = {}


def insert_row(cursor, listName, row):
    row['registreringFra_UTC'] = dateutil.parser.isoparse(row['registreringFra']).astimezone(timezone.utc).isoformat()
    row['registreringTil_UTC'] = dateutil.parser.isoparse(row['registreringTil']).astimezone(timezone.utc).isoformat() if row['registreringTil'] else None
    row['virkningFra_UTC'] = dateutil.parser.isoparse(row['virkningFra']).astimezone(timezone.utc).isoformat()
    row['virkningTil_UTC'] = dateutil.parser.isoparse(row['virkningTil']).astimezone(timezone.utc).isoformat() if row['virkningTil'] else None
    if row['id_lokalId'] is None or row['registreringFra_UTC'] is None or row['virkningFra_UTC'] is None:
        raise ValueError(f"Forventet primær nøgle (id_lokalId, registreringFra_UTC, virkningFra_UTC) har egentlig værdier, men fandt ({row['id_lokalId']}, {row['registreringFra_UTC']}, {row['virkningFra_UTC']})")
    if row['registreringTil_UTC'] and row['registreringTil_UTC'] < row['registreringFra_UTC']:
        err_msg = f"For ({row['id_lokalId']}, {row['registreringFra_UTC']}, {row['virkningFra_UTC']}): Registreringsinterval er forkert ({row['registreringFra']}, {row['registreringTil']})"
        print(err_msg)
        return -1
        # raise ValueError(err_msg)
    if row['virkningTil_UTC'] and row['virkningTil_UTC'] < row['virkningFra_UTC']:
        err_msg = f"For ({row['id_lokalId']}, {row['virkningFra_UTC']}, {row['virkningFra_UTC']}): Virkningsinterval er forkert ({row['virkningFra']}, {row['virkningTil']})"
        print(err_msg)
        return -1
        # raise ValueError(err_msg)
    if row['registreringTil_UTC']: #This is an update
        cursor.execute(table_names[listName]['F'], [row['id_lokalId'], row['registreringFra_UTC'], row['virkningFra_UTC']])
        rows = cursor.fetchall()
        if len(rows) > 1:
            raise ValueError(f"Forventet at opdatere een forekomst for ({row['id_lokalId']}, {row['registreringFra_UTC']}, {row['virkningFra_UTC']}), fandt {len(rows)} forekomster")
        elif len(rows) == 1:
            cursor.execute(table_names[listName]['U'], list(row.values()) + [row['id_lokalId'], row['registreringFra_UTC'], row['virkningFra_UTC']])
            return 1
        # else this is just a normal insert
    cursor.execute(table_names[listName]['V'], [row['id_lokalId'], row['registreringFra_UTC'], row['registreringTil_UTC'], row['virkningFra_UTC'], row['virkningTil_UTC']])
    violations = cursor.fetchall()
    if len(violations) > 0:
        columns = ['id_lokalId', 'registreringFra_UTC', 'registreringTil_UTC', 'virkningFra_UTC', 'virkningTil_UTC']
        for v in violations:
            vio = dict(zip(columns, v))
            cursor.execute("insert into violation_log (table_name, id_lokalId, conflicting_registreringFra_UTC, conflicting_virkningFra_UTC, violating_registreringFra_UTC, violating_virkningFra_UTC) "\
                           " VALUES(?, ?,  ?, ?,  ?, ?)", (listName, row['id_lokalId'], row['registreringFra_UTC'], row['virkningFra_UTC'], vio['registreringFra_UTC'], vio['virkningFra_UTC']))
    try:
        cursor.execute(table_names[listName]['I'], list(row.values()))
#        print(f"NEW ({row['id_lokalId']}, {row['registreringFra_ORG']}, {row['virkningFra_ORG']}) -> ({row['id_lokalId']}, {row['registreringFra_UTC']}, {row['virkningFra_UTC']})")
        return 0
    except sqlite3.Error as e:
        print(f"F   ({row['id_lokalId']}, {row['registreringFra']}, {row['virkningFra']}) -> ({row['id_lokalId']}, {row['registreringFra_UTC']}, {row['virkningFra_UTC']})")
        pprint(row)
        raise e


def prepare_table(table_name, columns):
    table_names[table_name] = {}
    table_names[table_name]['row'] = dict(zip(columns,[None for i in range(len(columns))]))
    table_names[table_name]['F'] = "select id_lokalId, registreringFra_UTC, virkningFra_UTC " \
                                   f"from {table_name} where true " \
                                   "AND id_lokalId = ? " \
                                   "AND registreringFra_UTC = ? " \
                                   "AND virkningFra_UTC = ?"
    table_names[table_name]['U'] = f"update {table_name} set " + \
                                   ", ".join([f" {c} = ? " for c in columns]) + " where true "\
                                   "AND id_lokalId = ? " \
                                   "AND registreringFra_UTC = ? " \
                                   "AND virkningFra_UTC = ?"
    table_names[table_name]['V'] = f"select id_lokalId, registreringFra_UTC, registreringTil_UTC, virkningFra_UTC, virkningTil_UTC, ? _id_lokalId, ? _RegistreringFra_UTC, ? _RegistreringTil_UTC, ? _VirkningFra_UTC, ? _VirkningTil_UTC from {table_name} where true " \
                                   "AND id_lokalId = _id_lokalId " \
                                   "AND ( registreringFra_UTC <= _RegistreringFra_UTC AND (_RegistreringFra_UTC <  registreringTil_UTC OR  registreringTil_UTC is NULL) "\
                                   "  OR _RegistreringFra_UTC <=  registreringFra_UTC AND ( registreringFra_UTC < _RegistreringTil_UTC OR _RegistreringTil_UTC is NULL)) "\
                                   "AND ( virkningFra_UTC <= _VirkningFra_UTC AND (_VirkningFra_UTC <  virkningTil_UTC OR  virkningTil_UTC is NULL) "\
                                   "  OR _VirkningFra_UTC <=  virkningFra_UTC AND ( virkningFra_UTC < _VirkningTil_UTC OR _VirkningTil_UTC is NULL)) "
    table_names[table_name]['I'] = f" INSERT into {table_name} ({', '.join(columns)})"\
                                   f" VALUES({', '.join(['?' for x in range(len(columns))])});"


def initialise_db(db_name, jsonschema, create=False):
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
            type_spec = ''
            if att_content['type'][0] == 'string':
                if 'format' in att_content:
                    if att_content['format'] == 'date-time':
                        type_spec += ' TEXT'  # TODO: improve
                    else:
                        raise NotImplementedError(f"Unknown attribute format '{att_content['format']}' on attribute {att_name}.")
                else:
                    type_spec += ' TEXT'
            elif att_content['type'][0] == 'integer':
                type_spec += 'INT'
            elif att_content['type'][0] == 'number':
                type_spec += 'REAL'
            else:
                raise NotImplementedError(f"Unknown attribute type '{att_content['type'][0]}' on attribute {att_name}.")
            if att_content['type'][1] == 'null':
                type_spec += ' NULL'
            else:
                raise NotImplementedError(f"Unknown attribute nullification '{att_content['type'][1]}' on attribute {att_name}.")
            columns.append(att_name)
            SQL += f"  {att_name: <20} {type_spec: <10}, -- {att_content['description']}\n"
            if att_name in ['registreringFra', 'registreringTil', 'virkningFra', 'virkningTil']:
                SQL += f"  {att_name + '_UTC': <20} {type_spec: <10},  -- TZ neutral\n"
                columns.append(att_name + '_UTC')
        SQL += "\n"
        SQL += "  PRIMARY KEY(id_lokalId, registreringFra_UTC, virkningFra_UTC)\n"
        SQL += ");\n"
        prepare_table(table_name, columns)
        if create:
            conn.execute(SQL)
    if create:
        SQL = "CREATE TABLE violation_log ("\
              "  number INTEGER PRIMARY KEY AUTOINCREMENT, "\
              "  table_name TEXT, "\
              "  id_lokalId TEXT, "\
              "  conflicting_registreringFra_UTC TEXT, "\
              "  conflicting_virkningFra_UTC TEXT, "\
              "  violating_registreringFra_UTC TEXT, "\
              "  violating_virkningFra_UTC TEXT"\
              ")"
        conn.execute(SQL)
        conn.commit()
        conn.close()


def main(create: ("Create the database", 'flag', 'c'),
         force: ("Force the DB creation", 'flag', 'f'),
         registry: ("DAF register: dar, bbr", 'option', 'r'),
         data_package: 'file path to the zip datapackage',
         db_name: 'Database file, defaults to <registry>.db' = None):
    """Loads a DAF data file into database"""

    if not db_name:
        db_name = registry + ".db"
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

    if registry == 'dar':
        json_schema_file_name = "DAR_v2.3.6_2019.08.18_DLS/DAR_v2.3.6_2019.08.19_DARTotal.schema.json"
    elif registry == 'bbr':
        json_schema_file_name = 'BBR_v2.4.4_2019.08.13_DLS/BBR_v2.4.4_2019.08.13_BBRTotal.schema.json'
    else:
        raise ValueError(f"Ukendt register '{registry}'.")
    with open(json_schema_file_name, 'rb') as file:
        initialise_db(db_name, json.load(file), create)

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
            data_errors = 0
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
                    print(f"{row_inserts:>10} rows inserted into  {db_table_name}")
                    print(f"{row_updates:>10} rows updated in     {db_table_name}")
                    print(f"{data_errors:>10} data errors in      {db_table_name}")
                    row_inserts = 0
                    row_updates = 0
                    data_errors = 0
                    db_table_name = None
                if '.' in prefix and event == 'start_map':
                    db_row = dict(table_names[db_table_name]['row'])
                if '.' in prefix and event == 'end_map':
                    ret = insert_row(cursor, db_table_name, db_row)
                    db_row = None
                    if ret == 0:
                        row_inserts += 1
                    elif ret == 1:
                        row_updates += 1
                    else:
                        data_errors += 1
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
