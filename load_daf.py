#!/usr/bin/env/python
import datetime
import decimal
import hashlib
import os
import ijson
import json
from zipfile import ZipFile
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
            "Forventet primærnøgle (id_lokalId, registreringFra, virkningFra)"
            f" har egentlig værdier, men fandt "
            f"({row['id_lokalId']}, {row['registreringFra']}, {row['virkningFra']})")
    if row['registreringTil_UTC'] and row['registreringTil_UTC'] <= row['registreringFra_UTC']:
        db_functions['Log violation'](cursor, row, 'Ikke-positivt registreringsinterval',
                                      f"{row['registreringTil']} <= {row['registreringFra']}", None)
    if row['virkningTil_UTC'] and row['virkningTil_UTC'] <= row['virkningFra_UTC']:
        db_functions['Log violation'](cursor, row, 'Ikke-positivt virkningsinterval',
                                      f"{row['virkningTil']} <= {row['virkningFra']}", None)
    db_functions['Find row'](cursor, row)
    rows = cursor.fetchall()
    check_bitemporal_entity_integrity = False
    if(len(rows)) > 1:
        raise ValueError(
            "Fundet mere end een række for "
            f"({row['id_lokalId']}, {row['registreringFra']}, {row['virkningFra']}).")
    elif len(rows) == 1:
        assert sorted([x[0] for x in cursor.description]) == sorted([*row.keys(), 'update_file_extract_id'])

        def invalid_update_columns(desc, existing, new_row):
            cols = []
            for i, d in enumerate(desc):
                if d[0] == 'registreringTil' and not existing[i]:
                    continue  # Allowed
                if d[0] in ['file_extract_id',
                            # Allowed edits:
                            'update_file_extract_id',
                            # Ignore synthetic edits:
                            'registreringFra_UTC', 'registreringTil_UTC', 'virkningFra_UTC', 'virkningTil_UTC'
                            ]:
                    continue
                if existing[i] != new_row[d[0]]:
                    cols.append((d[0], existing[i]))
            return cols
        invalid_update_cols = invalid_update_columns(cursor.description, rows[0], row)
        if invalid_update_cols:
            db_functions['Log violation'](cursor, row, 'Ugyldig opdatering af værdier',
                                          f"({','.join([n for (n,v) in invalid_update_cols])}) opdateret."
                                          " Tidligere værdi(er): (" +
                                          ','.join([f"'{v}'" for (n, v) in invalid_update_cols]) +
                                          ")",
                                          None)
            if set([n for (n,v) in invalid_update_cols]).intersection(['registreringTil', 'virkningTil']) is not set():
                check_bitemporal_entity_integrity = True
        db_functions['Update DAF row'](cursor, row)
        result = 0
    else:
        check_bitemporal_entity_integrity = True
        db_functions['Insert row'](cursor, row)
        result = 1
    if check_bitemporal_entity_integrity:
        update_data_integrity(cursor, db_functions, row)
    return result


def update_data_integrity(cursor, db_functions, row):
    # Eventually Clear entity integrity violation
    db_functions['Find overlaps'](cursor, row)
    violations = cursor.fetchall()
    if len(violations) > 0:
        violation_columns = [des[0] for des in cursor.description]
        if 'file_extract_id' not in row.keys():
            row['file_extract_id'] = row['update_file_extract_id']
        for v in violations:
            db_functions['Log violation'](cursor, row, "Bitemporal entitets-integritet", 'Se bitemporalitet',
                                          dict(zip(violation_columns, v)))
            # Eventually Register entity integrity violation


def prepare_bitemp_table(table, registry, reg_spec):
    table_name = table['name']
    column_names = [c['name'] for c in table['columns']]
    extra_column_names = [c['name'] for c in table['extra_columns']]
    table_names[table_name] = {POSTGRESQL: {},
                               SQLITE: {}}
    table_names[table_name]['row'] = dict(zip(column_names, [None] * len(column_names)))
    table_names[table_name]['registry'] = registry

    table_names[table_name][SQLITE]['Insert row'] = lambda cursor, row: insert_db_row(cursor, table_name, row)

    #  TODO: ensure timestamps are comparable
    def find_row_psql(cursor, row):
        cursor.execute("select * "
                       f"from {table_name} where true "
                       f"AND id_lokalId = %(id_lokalId)s "
                       f"AND registreringFra_UTC = %(registreringFra_UTC)s "
                       f"AND virkningFra_UTC = %(virkningFra_UTC)s",  # TODO: ensure timestamps are comparable
                       {k: row[k] for k in ['id_lokalId', 'registreringFra_UTC', 'virkningFra_UTC']})
    table_names[table_name][POSTGRESQL]['Find row'] = find_row_psql
    table_names[table_name][SQLITE]['Find row'] = find_row_psql

    def update_daf_row(cursor, row):
        row['update_file_extract_id'] = row.pop('file_extract_id')
        cursor.execute(f"update {table_name} set " +
                       ", ".join([f"{c} = %({c})s " for c in row.keys()]) +
                       " where true "
                       f"AND id_lokalId = %(id_lokalId)s "
                       f"AND registreringFra_UTC = %(registreringFra_UTC)s "
                       f"AND virkningFra_UTC = %(virkningFra_UTC)s", row)
    # table_names[table_name][POSTGRESQL]['Update DAF row'] = update_daf_row     # FIXME: update ranges
    table_names[table_name][SQLITE]['Update DAF row'] = update_daf_row

    violation_columns = [f'id_lokalId',
                         f'registreringFra_UTC', f'registreringTil_UTC',
                         f'virkningFra_UTC', f'virkningTil_UTC']

    # FIXME: use ranges
    def find_overlaps_sqlite(cursor, row):
        cursor.execute(f"select id_lokalId, registreringFra_UTC, virkningFra_UTC "
                       f"from {table_name} where true "
                       # Same bitemporal primary key:
                       f"AND id_lokalId = %(id_lokalId)s "
                       # Ensure another (instance) primary key:
                       f"AND (registreringFra_UTC != %(registreringFra_UTC)s OR virkningFra_UTC != %(virkningFra_UTC)s) "
                       # Ignoring/compensating for non-positive intervals:
                       f"AND (registreringFra_UTC < registreringTil_UTC OR registreringTil_UTC is NULL) "
                       f"AND (%(registreringFra_UTC)s < %(registreringTil_UTC)s OR %(registreringTil_UTC)s is NULL) "
                       f"AND (virkningFra_UTC < virkningTil_UTC OR virkningTil_UTC is NULL) "
                       f"AND (%(virkningFra_UTC)s < %(virkningTil_UTC)s OR %(virkningTil_UTC)s is NULL) "
                       # The actual bitemporal intersection:
                       f"AND ((       registreringFra_UTC   <= %(registreringFra_UTC)s"
                       f"  AND (%(registreringFra_UTC)s <    registreringTil_UTC   OR   registreringTil_UTC is NULL)) "
                       f" OR (     %(registreringFra_UTC)s <=   registreringFra_UTC "
                       f"  AND (  registreringFra_UTC   <  %(registreringTil_UTC)s OR %(registreringTil_UTC)s is NULL)) " 
                       f")"
                       f"AND ((       virkningFra_UTC   <= %(virkningFra_UTC)s "
                       f"  AND (%(virkningFra_UTC)s <    virkningTil_UTC   OR   virkningTil_UTC is NULL)) " 
                       f" OR (     %(virkningFra_UTC)s <=   virkningFra_UTC "
                       f"  AND (  virkningFra_UTC   <  %(virkningTil_UTC)s OR %(virkningTil_UTC)s is NULL))"
                       f") ", {k: row[k] for k in violation_columns})
    table_names[table_name][SQLITE]['Find overlaps'] = find_overlaps_sqlite

    # FIXME: use ranges
    def find_overlaps_psql(cursor, row):
        cursor.execute(f"select id_lokalId, registreringFra, virkningFra "
                       f"from {table_name} where true "
                       f"AND id_lokalId = %(id_lokalId)s "
                       f"AND registreringTid_UTC && tsrange(%(registreringFra_UTC)s, %(registreringTil_UTC)s, '[)')"
                       f"AND virkningTid_UTC     && tsrange(    %(virkningFra_UTC)s,     %(virkningTil_UTC)s, '[)')",
                       {k: row[k] for k in violation_columns})
    table_names[table_name][POSTGRESQL]['Find overlaps'] = find_overlaps_psql

    def log_violation(cursor, row, violation_type, message, vio):
        if vio is None:
            vio = {'registreringFra_UTC': None, 'virkningFra_UTC': None}
        cursor.execute(f"insert into violation_log (table_name, file_extract_id, id_lokalId,"
                       f" registreringFra_UTC, virkningFra_UTC, violation_type, violation_text,"
                       f" conflicting_registreringFra_UTC, conflicting_virkningFra_UTC) "
                       f" VALUES(?, ?,  ?, ?, ?,  ?, ?, ?, ?)",
                       (table_name, row['file_extract_id'], row['id_lokalId'], row['registreringFra_UTC'],
                        row['virkningFra_UTC'], violation_type, message,
                        vio['registreringFra_UTC'], vio['virkningFra_UTC']))
    table_names[table_name][SQLITE]['Log violation'] = log_violation
    table_names[table_name][POSTGRESQL]['Log violation'] = log_violation


def insert_db_row(cursor, table_name, row):
    return cursor.execute(f" INSERT into {table_name} ({', '.join(row.keys())})"
                          f" VALUES(" + ', '.join([f"%({c})s" for c in row.keys()]) + ");", row)


def update_db_row(cursor, table_name, row):
    cursor.execute(f"update {table_name} set " +
                   ", ".join([f"{c} = %({c})s " for c in row.keys() if c != 'id']) +
                   " where true "
                   "AND id = %(id)s ",
                   row)


SQLITE_TYPE_MAPPING = {
    'string': 'TEXT',
    'uri': 'TEXT',
    'datetimetz': 'TEXT',  # TODO: This could be improved
    'datetime': 'TEXT',  # TODO: This could be improved
    'integer': 'INTEGER',  # This is important, so that integer primary key becomes rowid.
    'boolean': 'BOOLEAN',
    'tsrange': None,
    'number': 'NUMERIC'  # This will ensure affinity and trigger the converter
}


def sqlite3_create_table(table, fail):
    sql = f"CREATE TABLE{'' if fail else ' IF NOT EXISTS'} {table['name']} (\n"
    extra_columns = []
    indexes = []
    for column in table['extra_columns']:
        if column['type'] == 'tsrange':
            assert column['name'][-7:] == 'Tid_UTC'
            for ex in ['Fra', 'Til']:
                col_name = column['name'].replace('Tid', ex)
                extra_columns += [{'name': col_name,
                                   'type': 'datetime',
                                   'nullable': 'null',  # column['nullable'],
                                   'description': f"Expansion of '{column['name']}. {column['description']}"
                                   }]
                indexes += [f"CREATE INDEX{'' if fail else ' IF NOT EXISTS'} "
                            f"{table['name']}_{col_name}_idx ON {table['name']} ({col_name});"]
        else:
            extra_columns.append(column)
    table['extra_columns'] = extra_columns
    for column in table['columns'] + table['extra_columns']:
        # table_content['items']['properties'].items()
        type_spec = ''
        if column['type'] not in SQLITE_TYPE_MAPPING:
            raise NotImplementedError(f"Unknown columns type '{column['type']}' on column {repr(column)}.")
        type_spec += SQLITE_TYPE_MAPPING[column['type']]
        if 'nullable' in column:
            if column['nullable'] == 'null':
                type_spec += ' NULL'
            elif column['nullable'] == 'notnull':
                type_spec += ' NOT NULL'
            else:
                raise NotImplementedError(
                    f"Unknown column nullification '{column['nullable']}' on column {repr(column)}.")
        comment = f"  --  {column['description']}" if 'description' in column else ''
        sql += f"  {column['name']: <20} {type_spec: <10},{comment}\n"
    sql += "\n"
    table['primary_keys'] = [(x + '_UTC') if x[-3:] == 'Fra' else x for x in table['primary_keys']]
    sql += "  PRIMARY KEY(" + ','.join(table['primary_keys']) + ")"
    if 'foreign_keys' in table.keys():
        for fk in table['foreign_keys']:
            sql += f",\n  FOREIGN KEY({', '.join(fk[0])}) REFERENCES {fk[1]}({', '.join(fk[2])})"
    sql += "\n);\n"
    return [sql] + indexes


PSQL_TYPE_MAPPING = {
    'string': 'text',
    'uri': 'text',
    'datetimetz': 'timestamp(6) with time zone',
    'integer': 'integer',
    'boolean': 'boolean',
    'tsrange': 'tsrange',
    'number': 'double precision'  # This will ensure affinity and trigger the converter
}


def psql_create_table(table, fail):
    sql = f"CREATE TABLE{'' if fail else ' IF NOT EXISTS'} {table['name']} (\n"
    indexes = []
    for (column) in table['columns'] + table['extra_columns']:
        # table_content['items']['properties'].items()
        type_spec = ''
        if column['type'] not in PSQL_TYPE_MAPPING:
            raise NotImplementedError(f"Unknown columns type '{column['type']}' on column {repr(column)}.")
        type_spec += PSQL_TYPE_MAPPING[column['type']]
        if type_spec == 'tsrange':
            indexes += [f"CREATE INDEX{'' if fail else ' IF NOT EXISTS'} {table['name']}_{column['name']}_idx "
                        f"ON {table['name']} USING GIST ({column['name']});"]
        if 'nullable' in column:
            if column['nullable'] == 'null':
                type_spec += ' null'
            elif column['nullable'] == 'notnull':
                type_spec += ' not null'
            else:
                raise NotImplementedError(
                    f"Unknown column nullification '{column['nullable']}' on column {repr(column)}.")
        comment = f"  --  {column['description']}" if 'description' in column else ''
        sql += f"  {column['name']: <20} {type_spec: <10},{comment}\n"
    sql += "\n"
    sql += "  PRIMARY KEY(" + ','.join(table['primary_keys']) + ")"
    if 'foreign_keys' in table.keys():
        for fk in table['foreign_keys']:
            sql += f",\n  FOREIGN KEY({', '.join(fk[0])}) REFERENCES {fk[1]}({', '.join(fk[2])})"
    sql += "\n);\n"
    return [sql] + indexes


def jsonschema2table(table_name, table_content):
    print(f"Parsing schema for {table_name}")
    table = {'name': table_name,
             'columns': [],
             'primary_keys': []
             }
    for (att_name, att_content) in table_content.items():
        att_type = att_content['type'][0] if isinstance(att_content['type'], list) else att_content['type']
        if att_type == 'string':
            if 'format' in att_content:
                if att_content['format'] == 'date-time':
                    column_type = 'datetimetz'
                elif att_content['format'] == 'uri':
                    column_type = 'uri'
                else:
                    raise NotImplementedError(
                        f"Unknown attribute format '{att_content['format']}' on attribute {att_name} on table {table_name}.")
            else:
                column_type = 'string'
        elif att_type == 'boolean':
            column_type = 'boolean'
        elif att_type == 'integer':
            column_type = 'integer'
        elif att_type == 'number':
            column_type = 'number'  # This will trigger the converter
        else:
            raise NotImplementedError(f"Unknown attribute type '{att_type}' on attribute {att_name}.")
        if isinstance(att_content['type'], list):
            if att_content['type'][1] == 'null':
                nullable = 'null'
            else:
                raise NotImplementedError(
                    f"Unknown attribute nullification '{att_content['type'][1]}' on attribute {att_name}.")
        else:
            nullable = 'null'
        column = {'name': att_name,
                  'type': column_type,
                  'nullable': nullable,
                  'description': att_content['description'] if 'description' in att_content else None
                  }
        table['columns'] += [column]
    #  Create bitemporal colums
    table['extra_columns'] = []
    if len({'registreringFra', 'virkningFra', 'registreringTil', 'virkningTil'}
                   .intersection(table_content.keys())) != 4:
        raise ValueError(f"one of 'registreringFra', 'virkningFra', 'registreringTil', 'virkningTil' is not in {list(table_content.keys())}")
    for tid in ['registrering', 'virkning']:
        table['extra_columns'] += [{'name': f'{tid}Tid_UTC',
                                    'type': 'tsrange',
                                    'description': f'({tid}Fra, {tid}Til) i UTC',
                                    'nullable': 'notnull'
                                    }]
    table['extra_columns'] += [{'name': 'file_extract_id',
                                'type': 'integer',
                                'nullable': 'notnull'
                                },
                               {'name': 'update_file_extract_id',
                                'type': 'integer',
                                'nullable': 'null'
                                }]
    table['primary_keys'] = ['id_lokalId', 'registreringFra', 'virkningFra']
    table['foreign_keys'] = [(['file_extract_id'], 'file_extract', ['id']),
                             (['update_file_extract_id'], 'file_extract', ['id'])]
    return table


def initialise_db(conn, sql_create_table, initialise_tables):
    tables = list()
    tables.append({
        'name': 'registry',
        'columns': [{'name': 'short_name', 'type': 'string', 'nullable': 'notnull'},
                    ],
        'extra_columns': [],
        'primary_keys': ['short_name'],
    })
    # prepare_table(tables[-1])
    tables.append({
        'name': 'registry_table',
        'columns': [{'name': 'registry', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'table_name', 'type': 'string', 'nullable': 'notnull'},
                    ],
        'extra_columns': [],
        'primary_keys': ['registry', 'table_name'],
        'foreign_keys': [(['registry'], 'registry', ['short_name'])],
    })
    # prepare_table(tables[-1])
    tables.append({
        'name': 'subscription',
        'columns': [{'name': 'subscription_name', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'registry', 'type': 'string', 'nullable': 'notnull'},
                    ],
        'extra_columns': [],
        'primary_keys': ['subscription_name'],
        'foreign_keys': [(['registry'], 'registry', ['short_name'])],
    })
    # prepare_table(tables[-1])
    tables.append({
        'name': 'file_extract',
        'columns': [{'name': 'id', 'type': 'integer'},
                    {'name': 'zip_file_name', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'zip_file_timestamp', 'type': 'datetimetz', 'nullable': 'notnull'},
                    {'name': 'zip_file_size', 'type': 'integer', 'nullable': 'notnull'},
                    {'name': 'zip_file_md5', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'metadata_file_name', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'metadata_file_timestamp', 'type': 'datetimetz', 'nullable': 'notnull'},
                    {'name': 'data_file_timestamp', 'type': 'datetimetz', 'nullable': 'notnull'},
                    {'name': 'data_file_size', 'type': 'integer', 'nullable': 'notnull'},
                    {'name': 'job_begin', 'type': 'datetimetz', 'nullable': 'notnull'},
                    {'name': 'job_end', 'type': 'datetimetz', 'nullable': 'null'},
                    ],
        'extra_columns': [],
        'primary_keys': ['id'],
    })
#    prepare_bitemp_table(tables[-1])
    tables.append({
        'name': 'metadata',
        'columns': [{'name': 'id', 'type': 'integer'},
                    {'name': 'file_extract_id', 'type': 'integer', 'nullable': 'notnull'},
                    {'name': 'key', 'type': 'string'},
                    {'name': 'value', 'type': 'string'},
                    ],
        'extra_columns': [],
        'primary_keys': ['id'],
        'foreign_keys': [(['file_extract_id'], 'file_extract', ['id'])],
    })
 #   prepare_bitemp_table(tables[-1])
    tables.append({
        'name': 'violation_log',
        'columns': [{'name': 'id', 'type': 'integer', 'nullable': 'notnull'},
                    {'name': 'file_extract_id', 'type': 'integer', 'nullable': 'notnull'},
                    {'name': 'table_name', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'id_lokalId', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'registreringFra_UTC', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'virkningFra_UTC', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'violation_type', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'violation_text', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'conflicting_registreringFra_UTC', 'type': 'string', 'nullable': 'null'},
                    {'name': 'conflicting_virkningFra_UTC', 'type': 'string', 'nullable': 'null'},
                    ],
        'extra_columns': [],
        'primary_keys': ['id'],
        'foreign_keys': [(['file_extract_id'], 'file_extract', ['id'])],
    })
    #  Consider prepare_table(tables[-1])
    if initialise_tables:
        cur = conn.cursor()
        for table in tables:
            for sql in sql_create_table(table, True):
                # print(sql)
                cur.execute(sql)
            print(f"Table {table['name']} created.")
        if True:  # Workaround
            try:
                conn.execute('insert into file_extract (id) values(10)')
            except:
                pass
#        conn.commit()


def initialise_registry_tables(conn, sql_create_table, registry, specification, initialise_tables):
    print(f"Initialising {registry}")
    with open(specification["json_schema"], 'rb') as json_schema_file:
        jsonschema = json.load(json_schema_file)
    assert sorted(jsonschema['required']) == sorted(jsonschema['properties'].keys())
    if initialise_tables:
        conn.execute("insert into registry ('short_name') values (?)", [registry])
    tables = list()
    if specification["schema_style"] == "plain":
        for (list_name, table_content) in jsonschema['properties'].items():
            assert (list_name[-4:] == 'List')
            assert (table_content['type'] == 'array')
            table_name = list_name[:-4]
            if "obsolete_entities" in specification.keys() and table_name in specification["obsolete_entities"]:
                continue
            tables.append(jsonschema2table(table_name, table_content['items']['properties']))
    else:
        for list_name, table_name in specification["feature_entities"].items():
            tables.append(jsonschema2table(table_name,jsonschema['properties']['features']['items']['properties']['properties']['properties']))
    for table_spec in tables:
        prepare_bitemp_table(table_spec, registry, specification)
        if initialise_tables:
            sqls = sql_create_table(table_spec, True)
            for sql in sqls:
                # print(sql)
                conn.execute(sql)
            conn.execute("insert into registry_table ('registry', 'table_name') values (?,?)", [registry, table_spec['name']])
#    conn.commit()


def main(initialise: ("Initialise (DROP and CREATE) statistics tables", 'flag', 'i'),
         db_backend: ("DB backend. Supported is 'sqlite', 'psql'", 'option', 'b'),
         db_host: ("Database host", 'option', 'H'),
         db_port: ("Database port", 'option', 'p'),
         db_name: ('Database name, defaults to DAF', 'option', 'd'),
         db_user: ("Database user", 'option', 'u'),
         db_password: ("Database password", 'option', 'X'),
         *data_package: 'file path to the zip datapackage'):
    """Loads DAF data files into database
    """

    database_options = {
        'backend': db_backend,
        'host': db_host,
        'port': db_port,
        'database': db_name if db_name else 'DAF',
        'user': db_user,
        'password': db_password
    }

    if database_options['backend'] == SQLITE:
        sqlite3.register_adapter(decimal.Decimal, decimal2text)
        sqlite3.register_converter('NUMERIC', text2decimal)  # It is most efficient to use storage class NUMERIC
        conn = sqlite3paramstyle.connect(database_options['database'] + '.db', detect_types=sqlite3.PARSE_DECLTYPES)
        conn.execute("PRAGMA encoding = 'UTF-8';")
        conn.execute("PRAGMA foreign_keys = ON;")
        conn.commit()
        sql_create_table = sqlite3_create_table
    elif database_options['backend'] == POSTGRESQL:
        conn = psycopg2.connect(host=database_options['host'],
                                port=database_options['port'],
                                user=database_options['user'],
                                password=database_options['password'],
                                dbname=database_options['database'])
        sql_create_table = psql_create_table
    else:
        raise NotImplementedError(
            f"Unknown database backend '{database_options['backend']}'.")

    initialise_db(conn, sql_create_table, initialise)
    registry_spec = json.load(open('registry_specification.json',"r"));
    for registry, specification in registry_spec.items():
        with open(specification["json_schema"], 'rb') as json_schema_file:
            initialise_registry_tables(conn, sql_create_table, registry, specification, initialise)
    if not data_package:
        conn.commit()
        conn.close()
        return
    database_options['connection'] = conn

    data_package = sorted(list(data_package), key=lambda x: x[-18:-4]+x[:-18])
    print(f"File extracts to load")
    print("\n".join(data_package))
    for dp in data_package:
        load_data_package(database_options, dp)
    conn.close()


def load_data_package(database_options, data_package):
    conn = database_options['connection']
    if not data_package[-4:] == '.zip':
        raise ValueError("data_package must be a zip file and end with '.zip'")

    cursor = conn.cursor()

    md5 = hashlib.md5()
    with open(data_package, 'rb') as content_file:
        while buf := content_file.read(md5.block_size):
            md5.update(buf)
    zip_file_md5 = md5.hexdigest()
    rows = cursor.execute('select * from file_extract where zip_file_md5 = %(zip_file_md5)s',
                          {'zip_file_md5': zip_file_md5}).fetchall()
    if len(rows) != 0:
        print(f"This file ({data_package}) with md5 ({zip_file_md5}) has already been loaded. Ignoring")
        return

    print(f'Loading data from {data_package[:-4]}')
    with ZipFile(data_package, 'r') as myzip:
        # for info in myzip.infolist():
        #    print(info.filename)
        meta_data_name = next(x for x in myzip.namelist() if 'Metadata' in x)
        json_data_name = next(x for x in myzip.namelist() if 'Metadata' not in x)
        zip2iso = lambda ts: datetime.datetime(*ts).isoformat()
        data_file_zipinfo = myzip.getinfo(json_data_name)
        file_extract = {
            'zip_file_name': os.path.basename(data_package),
            'zip_file_timestamp': datetime.datetime.fromtimestamp(
                os.path.getmtime(data_package)).astimezone().isoformat(),
            'zip_file_size': os.path.getsize(data_package),
            'zip_file_md5': zip_file_md5,
            'metadata_file_name': meta_data_name,
            'metadata_file_timestamp': zip2iso(myzip.getinfo(meta_data_name).date_time),
            'data_file_timestamp': zip2iso(data_file_zipinfo.date_time),
            'data_file_size': data_file_zipinfo.file_size,
            'job_begin': datetime.datetime.now(datetime.timezone.utc).isoformat()
        }
        file_extract_id = insert_db_row(cursor, 'file_extract', file_extract).lastrowid
        with myzip.open(meta_data_name) as file:
            metadata = json.load(file)

            def flatten_dict(d):
                def items():
                    for k, v in d.items():
                        if isinstance(v, dict):
                            for subkey, subvalue in flatten_dict(v).items():
                                yield k + "." + subkey, subvalue
                        elif isinstance(v, list):
                            for idx, item in enumerate(v):
                                for subkey, subvalue in flatten_dict(item).items():
                                    yield k + f"[{idx}]." + subkey, subvalue
                        else:
                            yield k, v

                return dict(items())

            values = flatten_dict(metadata)
            tjenestenavn2registry = {'DAR-Totaludtraek': 'DAR',
                                     'BBR-Totaludtraek': 'BBR',
                                     'MUTotalUdtraekFlad': 'MAT',
                                     'EBREjendomsbeliggenhedSimpel': 'EBR',
                                     }
            registry = tjenestenavn2registry[metadata['AbonnementsOplysninger'][0]['tjenestenavn']]
            abonnementnavn = values['AbonnementsOplysninger[0].abonnementnavn']
            deltavindue_start = values['DatafordelerUdtraekstidspunkt[0].deltavindueStart']

            latest_deltavindue_slut_sql = """
            select max(value) latest_deltavindue_slut from metadata
            join (select file_extract.*
                from file_extract
                         join metadata on file_extract.id = file_extract_id
                where key = 'AbonnementsOplysninger[0].abonnementnavn'
                  and value = %(abonnementnavn)s
               ) sub_file_extract on metadata.file_extract_id = sub_file_extract.id
            where key = 'DatafordelerUdtraekstidspunkt[0].deltavindueSlut';
            """
            rows = cursor.execute(latest_deltavindue_slut_sql, {'abonnementnavn': abonnementnavn}).fetchall()
            if len(rows) != 1:
                raise ValueError("More than one row!")
            latest_deltavindue_slut = rows[0][0]
            if latest_deltavindue_slut is None:
                # This is the first file of a subscription:
                if deltavindue_start != '1900-01-01T00:00:00.000+00:00':
                    raise ValueError(
                        f"deltavindueStart ({deltavindue_start}) "
                        "skal være '1900-01-01T00:00:00.000+00:00' på en tom DB")
                conn.execute("insert into subscription (subscription_name, registry) VALUES(?,?)",
                             [abonnementnavn, registry])
            elif latest_deltavindue_slut > deltavindue_start:
                raise ValueError(
                    f"deltavindueStart ({deltavindue_start}) skal være efter seneste deltavindueSlut "
                    "({latest_deltavindue_slut})")
            else:
                (reg_name,) = conn.execute("select registry from subscription where subscription_name = ?",
                                           [abonnementnavn]).fetchone()
                if reg_name != registry:
                    raise ValueError(
                        f"deltavindueStart (Abonnement '{abonnementnavn}' er registreret som abonnement på {reg_name},"
                        " men filen hører til {registry}. ")

            for key, value in values.items():
                insert_db_row(cursor, 'metadata', {'key': key,
                                                   'value': value,
                                                   'file_extract_id': file_extract_id})
        with myzip.open(json_data_name) as data_file:
            parser = ijson.parse(data_file)
            db_table_name = None
            db_row = None
            db_column = None
            row_inserts = 0
            row_updates = 0
            data_errors = 0
            step_time = time.time()
            for prefix, event, value in parser:
                if prefix == '' and event == 'start_map':
                    pass  # The top level
                elif prefix == '' and event == 'end_map':
                    pass  # The top level
                elif event == 'map_key':
                    if '.' in prefix:
                        db_column = value
                    else:
                        assert value[-4:] == 'List'
                        db_table_name = value[:-4]
                        step_time = time.time()
                        if db_table_name in table_names:  # Ignoring obsolete tables
                            print(f"Inserting into {db_table_name}")
                        else:
                            print(f"Ignoring obsolete table {db_table_name}")
                elif event == 'start_array':
                    pass
                elif event == 'end_array':
                    if db_table_name in table_names:  # Ignoring obsolete tables
                        print(f"{ row_inserts:>10} rows inserted into  {db_table_name}")
                        print(f"{ row_updates:>10} rows updated in     {db_table_name}")
                        print(f"{ data_errors:>10} data errors in      {db_table_name}")
                    else:
                        print(f"{ignored_rows:>10} ignored rows in     {db_table_name}")
                    row_inserts = 0
                    row_updates = 0
                    data_errors = 0
                    ignored_rows = 0
                    db_table_name = None
                elif '.' in prefix and event == 'start_map':
                    if db_table_name in table_names:  # Ignoring obsolete tables
                        db_row = dict(table_names[db_table_name]['row'])
                elif '.' in prefix and event == 'end_map':
                    if db_table_name not in table_names:  # Ignoring obsolete tables
                        ignored_rows += 1
                        continue
                    ret = insert_row(cursor, table_names[db_table_name][database_options['backend']],
                                     {**db_row, 'file_extract_id': file_extract_id})
                    db_row = None
                    if ret == 0:
                        row_updates += 1
                    elif ret == 1:
                        row_inserts += 1
                    else:
                        raise NotImplementedError
                    if (row_inserts + row_updates) % STEP_ROWS == 0:
                        prev_step_time = step_time
                        step_time = time.time()
                        print(
                            f"{(row_inserts + row_updates):>10} rows inserted/updated in {db_table_name}."
                            f" {int(STEP_ROWS // (step_time - prev_step_time))} rows/sec")
                elif event in ['null', 'boolean', 'integer', 'double', 'number', 'string']:
                    if db_table_name in table_names:  # Ignoring obsolete tables
                        db_row[db_column] = value
                    db_column = None
                else:
                    raise NotImplementedError("What situation is this?")
        update_db_row(cursor, 'file_extract',
                      {'id': file_extract_id, 'job_end': datetime.datetime.now(datetime.timezone.utc).isoformat()})
    conn.commit()


if __name__ == '__main__':
    import plac
    plac.call(main)
