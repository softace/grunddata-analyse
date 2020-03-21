#!/usr/bin/env/python
import decimal
import ijson
import json
from zipfile import ZipFile
from pprint import pprint
import sqlite3
import psycopg2
import time
from datetime import timezone
import dateutil.parser

SQLITE = 'sqlite'
POSTGRESQL = 'psql'
STEP_ROWS = 1000000
table_names = {}


def decimal2text(d):
    return str(d)


def text2decimal(s):
    return decimal.Decimal(s.decode('ascii'))


def insert_row(cursor, list_name, row):
    row['registreringFra_UTC'] = dateutil.parser.isoparse(row['registreringFra']).astimezone(
        timezone.utc).isoformat()
    row['registreringTil_UTC'] = dateutil.parser.isoparse(row['registreringTil']).astimezone(
        timezone.utc).isoformat() if row['registreringTil'] else None
    row['virkningFra_UTC'] = dateutil.parser.isoparse(row['virkningFra']).astimezone(
        timezone.utc).isoformat()
    row['virkningTil_UTC'] = dateutil.parser.isoparse(row['virkningTil']).astimezone(
        timezone.utc).isoformat() if row[
        'virkningTil'] else None
    if row['id_lokalId'] is None or row['registreringFra_UTC'] is None or row['virkningFra_UTC'] is None:
        raise ValueError(
            "Forventet primær nøgle (id_lokalId, registreringFra_UTC, virkningFra_UTC)"
            f" har egentlig værdier, men fandt "
            f"({row['id_lokalId']}, {row['registreringFra_UTC']}, {row['virkningFra_UTC']})")
    if row['registreringTil_UTC'] and row['registreringTil_UTC'] < row['registreringFra_UTC']:
        err_msg = f"For ({row['id_lokalId']}, {row['registreringFra_UTC']}, {row['virkningFra_UTC']}):"\
                  " Registreringsinterval er forkert ({row['registreringFra']}, {row['registreringTil']})"
        print(err_msg)
        return -1
        # raise ValueError(err_msg)
    if row['virkningTil_UTC'] and row['virkningTil_UTC'] < row['virkningFra_UTC']:
        err_msg = f"For ({row['id_lokalId']}, {row['virkningFra_UTC']}, {row['virkningFra_UTC']}):"\
                  f" Virkningsinterval er forkert ({row['virkningFra']}, {row['virkningTil']})"
        print(err_msg)
        return -1
        # raise ValueError(err_msg)
    if row['registreringTil_UTC']:  # This is an update
        cursor.execute(table_names[list_name]['F'], {k: row[k] for k in ['id_lokalId', 'registreringFra_UTC', 'virkningFra_UTC']})
        rows = cursor.fetchall()
        if len(rows) > 1:
            raise ValueError(
                "Forventet at opdatere een forekomst for "
                f"({row['id_lokalId']}, {row['registreringFra_UTC']}, {row['virkningFra_UTC']}),"
                f" fandt {len(rows)} forekomster")
        elif len(rows) == 1:
            cursor.execute(table_names[list_name]['U'], row)
            return 1
        # else this is just a normal insert
    cursor.execute(table_names[list_name]['V'],
                   {k: row[k] for k in
                    ['id_lokalId', 'registreringFra_UTC', 'registreringTil_UTC', 'virkningFra_UTC', 'virkningTil_UTC']})
    violations = cursor.fetchall()
    if len(violations) > 0:
        columns = ['id_lokalId', 'registreringFra_UTC', 'registreringTil_UTC', 'virkningFra_UTC', 'virkningTil_UTC']
        for v in violations:
            vio = dict(zip(columns, v))
            cursor.execute("insert into violation_log (table_name, id_lokalId,"
                           " conflicting_registreringFra_UTC, conflicting_virkningFra_UTC,"
                           " violating_registreringFra_UTC, violating_virkningFra_UTC) "
                           " VALUES(?, ?,  ?, ?,  ?, ?)",
                           (list_name, row['id_lokalId'], row['registreringFra_UTC'], row['virkningFra_UTC'],
                            vio['registreringFra_UTC'], vio['virkningFra_UTC']))
    try:
        cursor.execute(table_names[list_name]['I'], row)
        return 0
    except sqlite3.Error as e:
        print(
            f"FAIL ({row['id_lokalId']}, {row['registreringFra']}, {row['virkningFra']}) -> "
            f"({row['id_lokalId']}, {row['registreringFra_UTC']}, {row['virkningFra_UTC']})")
        pprint(row)
        raise e


def prepare_table(table):
    table_name = table['name']
    column_names = [c['name'] for c in table['columns']]
    table_names[table_name] = {}
    table_names[table_name]['row'] = dict(zip(column_names, [None for i in range(len(column_names))]))
    table_names[table_name]['F'] = "select id_lokalId, registreringFra_UTC, virkningFra_UTC " \
                                   f"from {table_name} where true " \
                                   "AND id_lokalId = :id_lokalId " \
                                   "AND registreringFra_UTC = :registreringFra_UTC " \
                                   "AND virkningFra_UTC = :virkningFra_UTC"
    table_names[table_name]['U'] = f"update {table_name} set " + \
                                   ", ".join([f"{c} = :{c} " for c in column_names]) + \
                                   " where true " \
                                   "AND id_lokalId = :id_lokalId " \
                                   "AND registreringFra_UTC = :registreringFra_UTC " \
                                   "AND virkningFra_UTC = :virkningFra_UTC"
    table_names[table_name]['V'] = \
        "select id_lokalId, registreringFra_UTC, registreringTil_UTC, virkningFra_UTC, virkningTil_UTC "\
        f"from {table_name} where true " \
        "AND id_lokalId = :id_lokalId " \
        "AND (     registreringFra_UTC <= :registreringFra_UTC"\
        "    AND (:registreringFra_UTC <   registreringTil_UTC OR registreringTil_UTC is NULL) " \
        "    OR   :registreringFra_UTC <=  registreringFra_UTC "\
        "    AND ( registreringFra_UTC <  :registreringTil_UTC OR :registreringTil_UTC is NULL) " \
        "    )"\
        "AND (     virkningFra_UTC <= :virkningFra_UTC "\
        "    AND (:virkningFra_UTC <   virkningTil_UTC OR virkningTil_UTC is NULL) " \
        "    OR   :virkningFra_UTC <=  virkningFra_UTC "\
        "    AND ( virkningFra_UTC <  :virkningTil_UTC OR :virkningTil_UTC is NULL)"\
        "    ) "
    table_names[table_name]['I'] = f" INSERT into {table_name} ({', '.join(column_names)})" \
                                   " VALUES(" + ', '.join([':' + c for c in column_names]) + ");"



def sqlite3_create_table(table):
    SQL = f"CREATE TABLE {table['name']} (\n"
    for (column) in table['columns']:
        # table_content['items']['properties'].items()
        type_spec = ''
        TYPE_MAPPING = {
            'string': 'TEXT',
            'datetime': 'TEXT',  # TODO: This could be improved
            'integer': 'INT',
            'number': 'NUMERIC'  # This will ensure affinity and trigger the converter
        }
        if column['type'] not in TYPE_MAPPING:
            raise NotImplementedError(f"Unknown columns type '{column['type']}' on column {repr(column)}.")
        type_spec += TYPE_MAPPING[column['type']]
        if 'nullspec' in column:
            if column['nullspec'] == 'null':
                type_spec += ' NULL'
            else:
                raise NotImplementedError(
                    f"Unknown column nullification '{column['nullspec']}' on column {repr(column)}.")
        comment = f"  --  {column['description']}" if 'description' in column else ''
        SQL += f"  {column['name']: <20} {type_spec: <10},{comment}\n"
    SQL += "\n"
    SQL += "  PRIMARY KEY(" + ','.join(table['primary_keys']) + ")\n"
    SQL += ");\n"
    return SQL


def psql_create_table(table):
    SQL = f"CREATE TABLE {table['name']} (\n"
    for (column) in table['columns']:
        # table_content['items']['properties'].items()
        type_spec = ''
        TYPE_MAPPING = {
            'string': 'text',
            'datetime': 'timestamp(6) with time zone',
            'integer': 'integer',
            'number': 'double precision'  # This will ensure affinity and trigger the converter
        }
        if column['type'] not in TYPE_MAPPING:
            raise NotImplementedError(f"Unknown columns type '{column['type']}' on column {repr(column)}.")
        type_spec += TYPE_MAPPING[column['type']]
        if 'nullspec' in column:
            if column['nullspec'] == 'null':
                type_spec += ' null'
            else:
                raise NotImplementedError(
                    f"Unknown column nullification '{column['nullspec']}' on column {repr(column)}.")
        comment = f"  --  {column['description']}" if 'description' in column else ''
        SQL += f"  {column['name']: <20} {type_spec: <10},{comment}\n"
    SQL += "\n"
    SQL += "  PRIMARY KEY(" + ','.join(table['primary_keys']) + ")\n"
    SQL += ");\n"
    return SQL


def jsonschema2table(table_name, table_content):
    table = {'name': table_name,
             'columns': [],
             'primary_keys': []
             }
    for (att_name, att_content) in table_content['items']['properties'].items():
        if att_content['type'][0] == 'string':
            if 'format' in att_content:
                if att_content['format'] == 'date-time':
                    type = 'datetime'
                else:
                    raise NotImplementedError(
                        f"Unknown attribute format '{att_content['format']}' on attribute {att_name}.")
            else:
                type = 'string'
        elif att_content['type'][0] == 'integer':
            type = 'integer'
        elif att_content['type'][0] == 'number':
            type = 'number'  # This will trigger the converter
        else:
            raise NotImplementedError(f"Unknown attribute type '{att_content['type'][0]}' on attribute {att_name}.")
        if att_content['type'][1] == 'null':
            nullspec = 'null'
        else:
            raise NotImplementedError(
                f"Unknown attribute nullification '{att_content['type'][1]}' on attribute {att_name}.")
        column = {'name': att_name,
                  'type': type,
                  'nullspec': nullspec,
                  'description': att_content['description'] if 'description' in att_content else None
                  }
        table['columns'].append(column)
        if att_name in ['registreringFra', 'registreringTil', 'virkningFra', 'virkningTil']:
            table['columns'].append({'name': att_name + '_UTC',
                                     'type': 'datetime',
                                     'nullspec': 'null',
                                     'description': 'TZ neutral'
                                     })
    table['primary_keys'] = ['id_lokalId', 'registreringFra_UTC', 'virkningFra_UTC']
    return table


def initialise_db(dbo, create, force, jsonschema):
    if dbo['backend'] == SQLITE:
        sqlite3.register_adapter(decimal.Decimal, decimal2text)
        sqlite3.register_converter('NUMERIC', text2decimal)  # It is most efficient to use storage class NUMERIC
        conn = sqlite3.connect(dbo['database'] + '.db', detect_types=sqlite3.PARSE_DECLTYPES)
        conn.execute("PRAGMA encoding = 'UTF-8';")
        conn.commit()
    elif dbo['backend'] == POSTGRESQL:
        conn = psycopg2.connect(host=dbo['host'],
                                port=dbo['port'],
                                user=dbo['user'],
                                password=dbo['password'],
                                dbname=dbo['database'])
    else:
        raise NotImplementedError(
            f"Unknown database backend '{dbo['backend']}'.")

    cur = conn.cursor()
    for (table_name, table_content) in jsonschema['properties'].items():
        assert (table_content['type'] == 'array')
        table = jsonschema2table(table_name, table_content)
        prepare_table(table)
        if create:
            if force:
                cur.execute(f"DROP TABLE IF EXISTS {table['name']}")
            cur.execute(sqlite3_create_table(table))
    table = {
        'name': 'violation_log',
        'columns': [{'name': 'number', 'type': 'integer'},
                    {'name': 'table_name', 'type': 'string'},
                    {'name': 'id_lokalId', 'type': 'string'},
                    {'name': 'conflicting_registreringFra_UTC', 'type': 'string'},
                    {'name': 'conflicting_virkningFra_UTC', 'type': 'string'},
                    {'name': 'violating_registreringFra_UTC', 'type': 'string'},
                    {'name': 'violating_virkningFra_UTC', 'type': 'string'},
                    ],
        'primary_keys': ['number'],
    }
    #  Consider prepare_table(table)
    if create:
        if force:
            cur.execute(f"DROP TABLE IF EXISTS {table['name']}")
        cur.execute(sqlite3_create_table(table))
    conn.commit()
    return conn


def main(create: ("Create the tables before inserting", 'flag', 'C'),
         force: ("Force creation of tables (DROP) if they already exists", 'flag', 'F'),
         db_backend: ("DB backend. Supported is 'sqlite', 'psql'", 'option', 'b'),
         db_host: ("Database host", 'option', 'H'),
         db_port: ("Database port", 'option', 'p'),
         db_name: ('Database name, defaults to DAF', 'option', 'd'),
         db_user: ("Database user", 'option', 'u'),
         db_password: ("Database password", 'option', 'X'),
         registry: ("DAF register: dar, bbr", 'option', 'r'),
         data_package: 'file path to the zip datapackage'):
    """Loads a DAF data file into database"""

    database_options = {
        'backend': db_backend,
        'host': db_host,
        'port': db_port,
        'database': db_name if db_name else 'DAF',
        'user': db_user,
        'password': db_password
    }

    if not data_package[-4:] == '.zip':
        raise ValueError("data_package must be a zip file and end with '.zip'")
    package_name = data_package[:-4]
    print(f'Loading data from {package_name}')
    if registry == 'dar':
        json_schema_file_name = "DAR_v2.3.6_2019.08.18_DLS/DAR_v2.3.6_2019.08.19_DARTotal.schema.json"
    elif registry == 'bbr':
        json_schema_file_name = 'BBR_v2.4.4_2019.08.13_DLS/BBR_v2.4.4_2019.08.13_BBRTotal.schema.json'
    else:
        raise ValueError(f"Ukendt register '{registry}'.")
    with open(json_schema_file_name, 'rb') as file:
        conn = initialise_db(database_options, create, force, json.load(file))

    cursor = conn.cursor()
    with ZipFile(data_package, 'r') as myzip:
        # for info in myzip.infolist():
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
                        print(
                            f"{(row_inserts + row_updates):>10} rows inserted/updated in {db_table_name}."
                            " {int(STEP_ROWS // (step_time - prev_step_time))} rows/sec")
                if event in ['null', 'boolean', 'integer', 'double', 'number', 'string']:
                    db_row[db_column] = value
                    db_column = None
    conn.commit()
    conn.close()


if __name__ == '__main__':
    import plac;

    plac.call(main)
