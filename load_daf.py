#!/usr/bin/env/python
import decimal
import ijson
import json
from zipfile import ZipFile
from pprint import pprint
import sqlite3
import sqlite3paramstyle
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


def insert_row(cursor, db_functions, row):
    row['registreringFra_UTC'] = dateutil.parser.isoparse(row['registreringFra']).astimezone(
        timezone.utc).isoformat()
    row['registreringTil_UTC'] = dateutil.parser.isoparse(row['registreringTil']).astimezone(
        timezone.utc).isoformat() if row['registreringTil'] else None
    row['virkningFra_UTC'] = dateutil.parser.isoparse(row['virkningFra']).astimezone(
        timezone.utc).isoformat()
    row['virkningTil_UTC'] = dateutil.parser.isoparse(row['virkningTil']).astimezone(
        timezone.utc).isoformat() if row['virkningTil'] else None
    if row['id_lokalId'] is None or row['registreringFra'] is None or row['virkningFra'] is None:
        raise ValueError(
            "Forventet primær nøgle (id_lokalId, registreringFra, virkningFra)"
            f" har egentlig værdier, men fandt "
            f"({row['id_lokalId']}, {row['registreringFra']}, {row['virkningFra']})")
    if row['registreringTil_UTC'] and row['registreringTil_UTC'] < row['registreringFra_UTC']:
        err_msg = f"For ({row['id_lokalId']}, {row['registreringFra']}, {row['virkningFra']}):"\
                  f" Registreringsinterval er negativ ({row['registreringFra']}, {row['registreringTil']})"
        print(err_msg)
        return -1
        # raise ValueError(err_msg)
    if row['virkningTil_UTC'] and row['virkningTil_UTC'] < row['virkningFra_UTC']:
        err_msg = f"For ({row['id_lokalId']}, {row['virkningFra']}, {row['virkningFra']}):"\
                  f" Virkningsinterval er negativ ({row['virkningFra']}, {row['virkningTil']})"
        print(err_msg)
        return -1
        # raise ValueError(err_msg)
    if row['registreringTil']:  # This might be an update
        db_functions['Find row'](cursor, row)
        rows = cursor.fetchall()
        if len(rows) > 1:  # Integrity error
            raise ValueError(
                "Forventet at opdatere een forekomst for "
                f"({row['id_lokalId']}, {row['registreringFra']}, {row['virkningFra']}),"
                f" fandt {len(rows)} forekomster")
        elif len(rows) == 1:
            db_functions['Update row'](cursor, row)
            return 1
        # else this is just a normal insert
    db_functions['Find overlaps'](cursor, row)
    violations = cursor.fetchall()
    if len(violations) > 0:
        violation_columns = [des[0] for des in cursor.description]
        for v in violations:
            db_functions['Log overlap'](cursor, row, dict(zip(violation_columns, v)))
    try:
        db_functions['Insert row'](cursor, row)
        return 0
    except sqlite3.Error as e:
        print(
            f"FAIL ({row['id_lokalId']}, {row['registreringFra']}, {row['virkningFra']}) -> "
            f"({row['id_lokalId']}, {row['registreringFra']}, {row['virkningFra']})")
        pprint(row)
        raise e


def prepare_table(table):
    table_name = table['name']
    column_names = [c['name'] for c in table['columns']]
    extra_column_names = [c['name'] for c in table['extra_columns']]
    table_names[table_name] = {POSTGRESQL: {},
                               SQLITE: {}}
    table_names[table_name]['row'] = dict(zip(column_names, [None] * len(column_names)))

    #  TODO: ensure timestamps are comparable
    def find_row_psql(cursor, row):
        cursor.execute("select id_lokalId, registreringFra, virkningFra "
                       f"from {table_name} where true "
                       "AND id_lokalId = %(id_lokalId)s "
                       "AND registreringFra = %(registreringFra)s "
                       "AND virkningFra = %(virkningFra)s",  # TODO: ensure timestamps are comparable
                       {k: row[k] for k in ['id_lokalId', 'registreringFra', 'virkningFra']})
    table_names[table_name][POSTGRESQL]['Find row'] = find_row_psql
    table_names[table_name][SQLITE]['Find row'] = find_row_psql

    # FIXME: update ranges
    def update_row_psql(cursor, row):
        cursor.execute(f"update {table_name} set " +
                       ", ".join([f"{c} = %({c})s " for c in column_names]) +
                       " where true "
                       "AND id_lokalId = %(id_lokalId)s "
                       "AND registreringFra = %(registreringFra)s "
                       "AND virkningFra = %(virkningFra)s", row)
    table_names[table_name][POSTGRESQL]['Update row'] = update_row_psql
    table_names[table_name][SQLITE]['Update row'] = update_row_psql

    violation_columns = ['id_lokalId',
                         'registreringFra_UTC', 'registreringTil_UTC', 'virkningFra_UTC', 'virkningTil_UTC']

    # FIXME: use ranges
    def find_overlaps_sqlite(cursor, row):
        cursor.execute("select id_lokalId, registreringFra, virkningFra "
                       f"from {table_name} where true "
                       "AND id_lokalId = %(id_lokalId)s "
                       "AND (      registreringFra_UTC   <= %(registreringFra_UTC)s"
                       "  AND (%(registreringFra_UTC)s <    registreringTil_UTC   OR   registreringTil_UTC is NULL) "
                       "  OR   %(registreringFra_UTC)s <=   registreringFra_UTC "
                       "  AND (  registreringFra_UTC   <  %(registreringTil_UTC)s OR %(registreringTil_UTC)s is NULL) " 
                       "  )"
                       "AND (      virkningFra_UTC   <= %(virkningFra_UTC)s "
                       "  AND (%(virkningFra_UTC)s <    virkningTil_UTC   OR   virkningTil_UTC is NULL) " 
                       "  OR   %(virkningFra_UTC)s <=   virkningFra_UTC "
                       "  AND (  virkningFra_UTC   <  %(virkningTil_UTC)s OR %(virkningTil_UTC)s is NULL)"
                       "  ) ", {k: row[k] for k in violation_columns})
    table_names[table_name][SQLITE]['Find overlaps'] = find_overlaps_sqlite

    # FIXME: use ranges
    def find_overlaps_psql(cursor, row):
        cursor.execute("select id_lokalId, registreringFra, virkningFra "
                       f"from {table_name} where true "
                       "AND id_lokalId = %(id_lokalId)s "
                       "AND registreringTid_UTC && tsrange(%(registreringFra_UTC)s, %(registreringTil_UTC)s, '[)')"
                       "AND virkningTid_UTC     && tsrange(    %(virkningFra_UTC)s,     %(virkningTil_UTC)s, '[)')",
                       {k: row[k] for k in violation_columns})
    table_names[table_name][POSTGRESQL]['Find overlaps'] = find_overlaps_psql

    def log_overlap(cursor, row, vio):
        cursor.execute("insert into violation_log (table_name, id_lokalId,"
                       " conflicting_registreringFra_UTC, conflicting_virkningFra_UTC,"
                       " violating_registreringFra_UTC, violating_virkningFra_UTC) "
                       " VALUES(?, ?,  ?, ?,  ?, ?)",
                       (table_name, row['id_lokalId'], row['registreringFra'], row['virkningFra'],
                        vio['registreringFra'], vio['virkningFra']))
    table_names[table_name][POSTGRESQL]['Log overlap'] = log_overlap
    table_names[table_name][SQLITE]['Log overlap'] = log_overlap

    def insert_row_sqlite(cursor, row):
        cursor.execute(f" INSERT into {table_name} ({', '.join(column_names + extra_column_names)})"
                       " VALUES(" + ', '.join([f"%({c})s" for c in column_names + extra_column_names]) + ");", row)
    table_names[table_name][SQLITE]['Insert row'] = insert_row_sqlite

    def insert_row_psql(cursor, row):
        cursor.execute(f" INSERT into {table_name} ({', '.join(column_names + extra_column_names)})"
                       " VALUES(" + ', '.join([f"%({c})s" for c in column_names]) + ', '
                       "        tsrange(%(registreringFra_UTC)s, %(registreringTil_UTC)s, '[)'), " +
                       "        tsrange(    %(virkningFra_UTC)s,     %(virkningTil_UTC)s, '[)')" +
                       ");", row)
    table_names[table_name][POSTGRESQL]['Insert row'] = insert_row_psql


SQLITE_TYPE_MAPPING = {
    'string': 'TEXT',
    'datetimetz': 'TEXT',  # TODO: This could be improved
    'datetime': 'TEXT',  # TODO: This could be improved
    'integer': 'INT',
    'tsrange': None,
    'number': 'NUMERIC'  # This will ensure affinity and trigger the converter
}


def sqlite3_create_table(table):
    sql = f"CREATE TABLE {table['name']} (\n"
    extra_columns = []
    indexes = []
    for column in table['extra_columns']:
        if column['type'] == 'tsrange':
            print(column['name'])
            assert column['name'][-7:] == 'Tid_UTC'
            for ex in ['Fra', 'Til']:
                col_name = column['name'].replace('Tid', ex)
                extra_columns += [{'name': col_name,
                                   'type': 'datetime',
                                   'nullspec': 'null',  # column['nullspec'],
                                   'description': f"Expansion of '{column['name']}. {column['description']}"
                                   }]
                indexes += [f"CREATE INDEX {table['name']}_{col_name}_idx ON {table['name']} ({col_name});"]
        else:
            extra_columns.append(column)
    table['extra_columns'] = extra_columns
    for column in table['columns'] + table['extra_columns']:
        # table_content['items']['properties'].items()
        type_spec = ''
        if column['type'] not in SQLITE_TYPE_MAPPING:
            raise NotImplementedError(f"Unknown columns type '{column['type']}' on column {repr(column)}.")
        type_spec += SQLITE_TYPE_MAPPING[column['type']]
        if 'nullspec' in column:
            if column['nullspec'] == 'null':
                type_spec += ' NULL'
            elif column['nullspec'] == 'notnull':
                type_spec += ' NOT NULL'
            else:
                raise NotImplementedError(
                    f"Unknown column nullification '{column['nullspec']}' on column {repr(column)}.")
        comment = f"  --  {column['description']}" if 'description' in column else ''
        sql += f"  {column['name']: <20} {type_spec: <10},{comment}\n"
    sql += "\n"
    table['primary_keys'] = [ (x + '_UTC') if x[-3:] == 'Fra' else x for x in table['primary_keys']]
    sql += "  PRIMARY KEY(" + ','.join(table['primary_keys']) + ")\n"
    sql += ");\n"
    return [sql] + indexes


PSQL_TYPE_MAPPING = {
    'string': 'text',
    'datetimetz': 'timestamp(6) with time zone',
    'integer': 'integer',
    'tsrange': 'tsrange',
    'number': 'double precision'  # This will ensure affinity and trigger the converter
}


def psql_create_table(table):
    sql = f"CREATE TABLE {table['name']} (\n"
    indexes = []
    for (column) in table['columns'] + table['extra_columns']:
        # table_content['items']['properties'].items()
        type_spec = ''
        if column['type'] not in PSQL_TYPE_MAPPING:
            raise NotImplementedError(f"Unknown columns type '{column['type']}' on column {repr(column)}.")
        type_spec += PSQL_TYPE_MAPPING[column['type']]
        if type_spec == 'tsrange':
            indexes += [f"CREATE INDEX {table['name']}_{column['name']}_idx "
                        f"ON {table['name']} USING GIST ({column['name']});"]
        if 'nullspec' in column:
            if column['nullspec'] == 'null':
                type_spec += ' null'
            elif column['nullspec'] == 'notnull':
                type_spec += ' not null'
            else:
                raise NotImplementedError(
                    f"Unknown column nullification '{column['nullspec']}' on column {repr(column)}.")
        comment = f"  --  {column['description']}" if 'description' in column else ''
        sql += f"  {column['name']: <20} {type_spec: <10},{comment}\n"
    sql += "\n"
    sql += "  PRIMARY KEY(" + ','.join(table['primary_keys']) + ")\n"
    sql += ");\n"
    return [sql] + indexes


def jsonschema2table(table_name, table_content):
    table = {'name': table_name,
             'columns': [],
             'primary_keys': []
             }
    for (att_name, att_content) in table_content['items']['properties'].items():
        if att_content['type'][0] == 'string':
            if 'format' in att_content:
                if att_content['format'] == 'date-time':
                    column_type = 'datetimetz'
                else:
                    raise NotImplementedError(
                        f"Unknown attribute format '{att_content['format']}' on attribute {att_name}.")
            else:
                column_type = 'string'
        elif att_content['type'][0] == 'integer':
            column_type = 'integer'
        elif att_content['type'][0] == 'number':
            column_type = 'number'  # This will trigger the converter
        else:
            raise NotImplementedError(f"Unknown attribute type '{att_content['type'][0]}' on attribute {att_name}.")
        if att_content['type'][1] == 'null':
            nullspec = 'null'
        else:
            raise NotImplementedError(
                f"Unknown attribute nullification '{att_content['type'][1]}' on attribute {att_name}.")
        column = {'name': att_name,
                  'type': column_type,
                  'nullspec': nullspec,
                  'description': att_content['description'] if 'description' in att_content else None
                  }
        table['columns'] += [column]
    #  Create bitemporal colums
    table['extra_columns'] = []
    for tid in ['registrering', 'virkning']:
        table['extra_columns'] += [{'name': f'{tid}Tid_UTC',
                                    'type': 'tsrange',
                                    'description': f'({tid}Fra, {tid}Til) i UTC',
                                    'nullspec': 'notnull'
                                    }]
    table['primary_keys'] = ['id_lokalId', 'registreringFra', 'virkningFra']
    return table


def initialise_db(dbo, create, force, jsonschema):
    if dbo['backend'] == SQLITE:
        sqlite3.register_adapter(decimal.Decimal, decimal2text)
        sqlite3.register_converter('NUMERIC', text2decimal)  # It is most efficient to use storage class NUMERIC
        conn = sqlite3paramstyle.connect(dbo['database'] + '.db', detect_types=sqlite3.PARSE_DECLTYPES)
        conn.execute("PRAGMA encoding = 'UTF-8';")
        conn.commit()
        sql_create_table = sqlite3_create_table
    elif dbo['backend'] == POSTGRESQL:
        conn = psycopg2.connect(host=dbo['host'],
                                port=dbo['port'],
                                user=dbo['user'],
                                password=dbo['password'],
                                dbname=dbo['database'])
        sql_create_table = psql_create_table
    else:
        raise NotImplementedError(
            f"Unknown database backend '{dbo['backend']}'.")

    cur = conn.cursor()
    for (table_name, table_content) in jsonschema['properties'].items():
        assert (table_content['type'] == 'array')
        table = jsonschema2table(table_name, table_content)
        if create:
            if force:
                cur.execute(f"DROP TABLE IF EXISTS {table['name']}")
                print(f"Table {table['name']} droped.")
            for sql in sql_create_table(table):
#                print(sql)
                cur.execute(sql)
            print(f"Table {table['name']} created.")
        prepare_table(table)
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
        'extra_columns': [],
        'primary_keys': ['number'],
    }
    #  Consider prepare_table(table)
    if create:
        if force:
            cur.execute(f"DROP TABLE IF EXISTS {table['name']}")
            print(f"Table {table['name']} droped.")
        for sql in sql_create_table(table):
            cur.execute(sql)
        print(f"Table {table['name']} created.")
    conn.commit()
    print(f"Database {dbo['database']} initialised.")
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
    """Loads a DAF data file into database
    """

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
        json_data_name = next(x for x in myzip.namelist() if 'Metadata' not in x)
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
                    ret = insert_row(cursor, table_names[db_table_name][database_options['backend']], db_row)
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
                            f" {int(STEP_ROWS // (step_time - prev_step_time))} rows/sec")
                if event in ['null', 'boolean', 'integer', 'double', 'number', 'string']:
                    db_row[db_column] = value
                    db_column = None
    conn.commit()
    conn.close()


if __name__ == '__main__':
    import plac
    plac.call(main)
