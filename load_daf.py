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


def insert_row(cursor, db_functions, bitemporal_primary_key, row):
    primary_key = bitemporal_primary_key+['registreringFra', 'virkningFra']
    row['registreringFra_UTC'] = dateutil.parser.isoparse(row['registreringFra']).astimezone(
        timezone.utc).isoformat(timespec='microseconds')
    row['registreringTil_UTC'] = dateutil.parser.isoparse(row['registreringTil']).astimezone(
        timezone.utc).isoformat(timespec='microseconds') if row['registreringTil'] else None
    row['virkningFra_UTC'] = dateutil.parser.isoparse(row['virkningFra']).astimezone(
        timezone.utc).isoformat(timespec='microseconds')
    row['virkningTil_UTC'] = dateutil.parser.isoparse(row['virkningTil']).astimezone(
        timezone.utc).isoformat(timespec='microseconds') if row['virkningTil'] else None
    if not all([row[p] for p in primary_key]):
        raise ValueError(
            f"Forventet primærnøgle ({', '.join(primary_key)})"
            f" har egentlig værdier, men fandt "
            f"({', '.join([row[p] for p in primary_key])})")
    if row['registreringTil_UTC'] and row['registreringTil_UTC'] <= row['registreringFra_UTC']:
        db_functions['Log violation'](cursor, row, 'Ikke-positivt registreringsinterval',
                                      f"{row['registreringTil']} <= {row['registreringFra']}")
    if row['virkningTil_UTC'] and row['virkningTil_UTC'] <= row['virkningFra_UTC']:
        db_functions['Log violation'](cursor, row, 'Ikke-positivt virkningsinterval',
                                      f"{row['virkningTil']} <= {row['virkningFra']}")
    db_functions['Find row'](cursor, row)
    rows = cursor.fetchall()
    check_bitemporal_entity_integrity = False
    if(len(rows)) > 1:
        raise ValueError(
            f"Fundet mere end een række for ({', '.join(primary_key)}) = "
            f"({', '.join([row[p] for p in primary_key])}).")
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
                                          ")")
        db_functions['Update DAF row'](cursor, row)
        result = 0
    else:
        db_functions['Insert row'](cursor, row)
        result = 1
    return result


def prepare_bitemp_table(table, registry, reg_spec):
    table_name = table['name']
    column_names = [c['name'] for c in table['columns']]
    extra_column_names = [c['name'] for c in table['extra_columns']]
    table_names[table_name] = {POSTGRESQL: {},
                               SQLITE: {},
                               None: {}}
    table_names[table_name]['row'] = dict(zip(column_names, [None] * len(column_names)))
    table_names[table_name]['registry'] = registry

    bitemporal_primary_key = sorted(list(set(reg_spec['bitemporal_primary_key']).intersection(set([t['name'] for t in table['columns']]))))
    table_names[table_name][None]['bitemporal_primary_key'] = bitemporal_primary_key
    table_names[table_name][SQLITE]['Insert row'] = lambda cursor, row: insert_db_row(cursor, table_name, row)

    primary_key = bitemporal_primary_key+['registreringFra_UTC', 'virkningFra_UTC']
    #  TODO: ensure timestamps are comparable
    def find_row_psql(cursor, row):
        cursor.execute("select * "
                       f"from {table_name} where true "
                       f"AND " +
                       ' AND '.join([f"{k} = %({k})s" for k in primary_key])
                       ,
                       {k: row[k] for k in primary_key})
    table_names[table_name][POSTGRESQL]['Find row'] = find_row_psql
    table_names[table_name][SQLITE]['Find row'] = find_row_psql

    def update_daf_row(cursor, row):
        row['update_file_extract_id'] = row.pop('file_extract_id')
        cursor.execute(f"update {table_name} set " +
                       ", ".join([f" {c} = %({c})s " for c in row.keys()]) +
                       " where true "
                       f"AND " +
                       ' AND '.join([f" {k} = %({k})s " for k in primary_key])
                       , row)
    # table_names[table_name][POSTGRESQL]['Update DAF row'] = update_daf_row     # FIXME: update ranges
    table_names[table_name][SQLITE]['Update DAF row'] = update_daf_row

    violation_columns = primary_key + ['registreringTil_UTC', 'virkningTil_UTC']

    # FIXME: use ranges
    def find_overlaps_sqlite(cursor, row):
        cursor.execute(f"select {', '.join(bitemporal_primary_key)} , registreringFra_UTC, virkningFra_UTC "
                       f"from {table_name} where true "
                       # Same bitemporal primary key:
                       f"AND " + ' AND '.join([f" {k} = %({k})s " for k in bitemporal_primary_key]) +
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

    def log_violation(cursor, row, violation_type, message):
        cursor.execute(f"insert into violation_log (table_name, file_extract_id, {', '.join(bitemporal_primary_key)},"
                       f" registreringFra_UTC, virkningFra_UTC, violation_type, violation_text)"
                       f" VALUES(?, ?,  " + ("?, "*len(bitemporal_primary_key)) + "?, ?,  ?, ?)",
                       (table_name, row['file_extract_id']) +
                       tuple(row[p] for p in bitemporal_primary_key) +
                       (row['registreringFra_UTC'],
                        row['virkningFra_UTC'], violation_type, message))
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
    # for index in table['indexes']:
    #     sql += f"CREATE INDEX"
    sql += "\n);\n"
    if 'indexes' in table.keys():
        for index in table['indexes']:
            idx_name = table['name'] + '_' + "_".join(index) + '_idx'
            indexes += [f"CREATE INDEX{'' if fail else ' IF NOT EXISTS'} {idx_name} ON {table['name']} (" + ",".join(index) + ");"]
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


def jsonschema2table(table_name, table_content, temporal_primary_keys):
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
    existing_temporal_primary_keys = list(set(temporal_primary_keys).intersection(set([t['name'] for t in table['columns']])))
    table['primary_keys'] = existing_temporal_primary_keys + ['registreringFra', 'virkningFra']
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
                    {'name': 'subscription_name', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'zip_file_name', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'zip_file_timestamp', 'type': 'datetimetz', 'nullable': 'notnull'},
                    {'name': 'zip_file_size', 'type': 'integer', 'nullable': 'notnull'},
                    {'name': 'zip_file_md5', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'metadata_file_name', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'metadata_file_timestamp', 'type': 'datetimetz', 'nullable': 'notnull'},
                    {'name': 'data_file_timestamp', 'type': 'datetimetz', 'nullable': 'notnull'},
                    {'name': 'data_file_size', 'type': 'integer', 'nullable': 'notnull'},
                    {'name': 'load_begin', 'type': 'datetimetz', 'nullable': 'notnull'},
                    {'name': 'load_end', 'type': 'datetimetz', 'nullable': 'null'},
                    {'name': 'stats_end', 'type': 'datetimetz', 'nullable': 'null'},
                    ],
        'extra_columns': [],
        'primary_keys': ['id'],
        'foreign_keys': [(['subscription_name'], 'subscription', ['subscription_name'])],
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
                    {'name': 'status', 'type': 'string', 'nullable': 'null'},
                    {'name': 'senesteSagLokalId', 'type': 'string', 'nullable': 'null'},
                    {'name': 'registreringFra_UTC', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'virkningFra_UTC', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'violation_type', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'violation_text', 'type': 'string', 'nullable': 'notnull'},
                    ],
        'extra_columns': [],
        'primary_keys': ['id'],
        'foreign_keys': [(['file_extract_id'], 'file_extract', ['id'])],
    })
    #  Consider prepare_table(tables[-1])
    tables.append({
        'name': 'entity_integrity_violation',
        'columns': [{'name': 'id', 'type': 'integer', 'nullable': 'notnull'},
                    {'name': 'table_name', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'bitemporal_primary_key', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'ent1_file_extract_id', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'ent1_registreringFra_UTC', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'ent1_virkningFra_UTC', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'ent2_file_extract_id', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'ent2_registreringFra_UTC', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'ent2_virkningFra_UTC', 'type': 'string', 'nullable': 'notnull'},
                    ],
        'extra_columns': [],
        'primary_keys': ['id'],
        'indexes': [['table_name'],
                    ['table_name', 'bitemporal_primary_key'],
                    ['table_name', 'bitemporal_primary_key', 'ent1_registreringFra_UTC', 'ent1_virkningFra_UTC'],
                    ['table_name', 'bitemporal_primary_key', 'ent2_registreringFra_UTC', 'ent2_virkningFra_UTC']
                    ],
        'uniques': [['table_name', 'bitemporal_primary_key',
                   'ent1_registreringFra_UTC', 'ent1_virkningFra_UTC',
                   'ent2_registreringFra_UTC', 'ent2_virkningFra_UTC']],
    })
    #  Consider prepare_table(tables[-1])
    tables.append({
        'name': 'status_report',
        'columns': [{'name': 'file_extract_id', 'type': 'integer', 'nullable': 'notnull'},
                    {'name': 'registry', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'table_name', 'type': 'string', 'nullable': 'notnull'},
                    {'name': 'instance_count', 'type': 'integer', 'nullable': 'notnull'},
                    {'name': 'object_count', 'type': 'integer', 'nullable': 'notnull'},
                    {'name': 'invalid_update_count', 'type': 'integer', 'nullable': 'notnull'},
                    {'name': 'non_positive_interval_registrering', 'type': 'integer', 'nullable': 'notnull'},
                    {'name': 'non_positive_interval_virkning', 'type': 'integer', 'nullable': 'notnull'},
                    {'name': 'bitemporal_entity_integrity_count', 'type': 'integer', 'nullable': 'notnull'},
                    {'name': 'bitemporal_entity_integrity_instances', 'type': 'integer', 'nullable': 'notnull'},
                    {'name': 'bitemporal_entity_integrity_objects', 'type': 'integer', 'nullable': 'notnull'},
                    {'name': 'total_instance_count', 'type': 'integer', 'nullable': 'notnull'},
                    {'name': 'total_object_count', 'type': 'integer', 'nullable': 'notnull'},
                    {'name': 'total_non_positive_interval_registrering', 'type': 'integer', 'nullable': 'notnull'},
                    {'name': 'total_non_positive_interval_virkning', 'type': 'integer', 'nullable': 'notnull'},
                    {'name': 'total_bitemporal_entity_integrity_count', 'type': 'integer', 'nullable': 'notnull'},
                    {'name': 'total_bitemporal_entity_integrity_instances', 'type': 'integer', 'nullable': 'notnull'},
                    {'name': 'total_bitemporal_entity_integrity_objects', 'type': 'integer', 'nullable': 'notnull'},
                    ],
        'extra_columns': [],
        'primary_keys': ['table_name', 'file_extract_id'],
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
            tables.append(jsonschema2table(table_name, table_content['items']['properties'], sorted(specification['bitemporal_primary_key'])))
    else:
        for list_name, table_name in specification["feature_entities"].items():
            tables.append(jsonschema2table(table_name,jsonschema['properties']['features']['items']['properties']['properties']['properties'], specification['bitemporal_primary_key']))
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
        conn.execute("PRAGMA secure_delete = OFF")
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
        load_data_package(database_options, registry_spec, dp)
    conn.close()


def update_entity_integrity(cursor, bitemporal_primary_key, table_name):
    print("Updating entity integrity violations")
    cursor.execute(f"delete from entity_integrity_violation where table_name = '{table_name}';")
    sql_entity = f"""
    insert into entity_integrity_violation (table_name, bitemporal_primary_key, ent1_file_extract_id, ent1_registreringFra_UTC, ent1_virkningFra_UTC, ent2_file_extract_id, ent2_registreringFra_UTC, ent2_virkningFra_UTC)
    -- Overlappende forekomster
    select '{table_name}' as table_name,
           {"||':'||".join([f"ent1.{k}" for k in bitemporal_primary_key])},
           COALESCE(ent1.update_file_extract_id, ent1.file_extract_id) as ent1_file_extract_id, 
           ent1.registreringFra_UTC as ent1_registreringFra_UTC,
    --       ent1.registreringTil_UTC as ent1_registreringTil_UTC,
           ent1.virkningFra_UTC as ent1_virkningFra_UTC,
    --       ent1.virkningTil_UTC as ent1_virkningTil_UTC,
           COALESCE(ent2.update_file_extract_id, ent2.file_extract_id) as ent2_file_extract_id, 
           ent2.registreringFra_UTC as ent2_registreringFra_UTC,
    --       ent2.registreringTil_UTC as ent2_registreringTil_UTC,
           ent2.virkningFra_UTC as ent2_virkningFra_UTC
    --       ent2.virkningTil_UTC as ent2_virkningTil_UTC
    from {table_name} ent1
    -- Same bitemporal primary key:
    join {table_name} ent2 on {' AND '.join([f" ent1.{k} = ent2.{k} " for k in bitemporal_primary_key])}
    -- Ensure another (instance) primary key:
    AND (ent1.registreringFra_UTC != ent2.registreringFra_UTC OR ent1.virkningFra_UTC != ent2.virkningFra_UTC)
    -- Ignoring/compensating for non-positive intervals:
    AND (ent1.registreringFra_UTC < ent1.registreringTil_UTC OR ent1.registreringTil_UTC is NULL)
    AND (ent2.registreringFra_UTC < ent2.registreringTil_UTC OR ent2.registreringTil_UTC is NULL)
    AND (ent1.virkningFra_UTC < ent1.virkningTil_UTC OR ent1.virkningTil_UTC is NULL)
    AND (ent2.virkningFra_UTC < ent2.virkningTil_UTC OR ent2.virkningTil_UTC is NULL)
    -- order
    -- and ( ent1.file_extract_id < ent2.file_extract_id OR (ent1.file_extract_id = ent2.file_extract_id AND ((ent1.registreringFra_UTC || ent1.virkningFra_UTC) < (ent2.registreringFra_UTC || ent2.virkningFra_UTC))))
    and (ent1.registreringFra_UTC || ent1.virkningFra_UTC) < (ent2.registreringFra_UTC || ent2.virkningFra_UTC)
    -- The actual bitemporal intersection:
                           AND ((       ent1.registreringFra_UTC   <= ent2.registreringFra_UTC
                                 AND (ent2.registreringFra_UTC <    ent1.registreringTil_UTC   OR   ent1.registreringTil_UTC is NULL))
                             OR (     ent2.registreringFra_UTC <=   ent1.registreringFra_UTC
                                 AND (  ent1.registreringFra_UTC   <  ent2.registreringTil_UTC OR ent2.registreringTil_UTC is NULL))
                               )
                           AND ((       ent1.virkningFra_UTC   <= ent2.virkningFra_UTC
                                 AND (ent2.virkningFra_UTC <    ent1.virkningTil_UTC   OR   ent1.virkningTil_UTC is NULL))
                             OR (     ent2.virkningFra_UTC <=   ent1.virkningFra_UTC
                                 AND (  ent1.virkningFra_UTC   <  ent2.virkningTil_UTC OR ent2.virkningTil_UTC is NULL))
                               )
    """
    cursor.execute(sql_entity)



def load_data_package(database_options, registry_spec, data_package):
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

            file_extract = {
                'subscription_name': abonnementnavn,
                'zip_file_name': os.path.basename(data_package),
                'zip_file_timestamp': datetime.datetime.fromtimestamp(
                    os.path.getmtime(data_package)).astimezone().isoformat(),
                'zip_file_size': os.path.getsize(data_package),
                'zip_file_md5': zip_file_md5,
                'metadata_file_name': meta_data_name,
                'metadata_file_timestamp': zip2iso(myzip.getinfo(meta_data_name).date_time),
                'data_file_timestamp': zip2iso(data_file_zipinfo.date_time),
                'data_file_size': data_file_zipinfo.file_size,
                'load_begin': datetime.datetime.now(datetime.timezone.utc).isoformat()
            }
            file_extract_id = insert_db_row(cursor, 'file_extract', file_extract).lastrowid
            for key, value in values.items():
                insert_db_row(cursor, 'metadata', {'key': key,
                                                   'value': value,
                                                   'file_extract_id': file_extract_id})
        plain_schema = registry_spec[registry]['schema_style'] == 'plain'
        dirty_table_names = []
        with myzip.open(json_data_name) as data_file:
            parser = ijson.parse(data_file)
            db_table_name = None
            db_row = None
            db_column_name = None
            step_time = time.time()

            def finish_row():
                nonlocal ignored_rows, db_row, row_updates, row_inserts, step_time
                if db_table_name not in table_names:  # Ignoring obsolete tables
                    ignored_rows += 1
                    return
                ret = insert_row(cursor, table_names[db_table_name][database_options['backend']],
                                 table_names[db_table_name][None]['bitemporal_primary_key'],
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

            if plain_schema:
                for prefix, event, value in parser:
                    if prefix == '' and event == 'start_map':
                        pass  # The top level
                    elif prefix == '' and event == 'end_map':
                        pass  # The top level
                    elif event == 'map_key':
                        if '.' in prefix:
                            db_column_name = value
                        else:
                            assert value[-4:] == 'List'
                            db_table_name = value[:-4]
                            step_time = time.time()
                            if db_table_name in table_names:  # Ignoring obsolete tables
                                dirty_table_names.append(db_table_name)
                                print(f"Inserting into {db_table_name}")
                            else:
                                print(f"Ignoring obsolete table {db_table_name}")
                    elif event == 'start_array':
                        row_inserts = 0
                        row_updates = 0
                        data_errors = 0
                        ignored_rows = 0
                    elif event == 'end_array':
                        if db_table_name in table_names:  # Ignoring obsolete tables
                            print(f"{ row_inserts:>10} rows inserted into  {db_table_name}")
                            print(f"{ row_updates:>10} rows updated in     {db_table_name}")
                            print(f"{ data_errors:>10} data errors in      {db_table_name}")
                            if row_inserts + row_updates > 0:
                                update_entity_integrity(cursor, table_names[db_table_name][None]['bitemporal_primary_key'], db_table_name)
                        else:
                            print(f"{ignored_rows:>10} ignored rows in     {db_table_name}")
                        db_table_name = None
                    elif '.' in prefix and event == 'start_map':
                        if db_table_name in table_names:  # Ignoring obsolete tables
                            db_row = dict(table_names[db_table_name]['row'])
                    elif '.' in prefix and event == 'end_map':
                        finish_row()
                    elif event in ['null', 'boolean', 'integer', 'double', 'number', 'string']:
                        if db_table_name in table_names:  # Ignoring obsolete tables
                            db_row[db_column_name] = value
                        db_column_name = None
                    else:
                        raise NotImplementedError(f"What situation is this? prefix = '{prefix}', event = '{event}', value = '{value}'")
            else: #  not plain_schema
                for prefix, event, value in parser:
                    if prefix == '' and event == 'start_map':
                        pass  # The top level
                    elif prefix == '' and event == 'map_key' and value == 'type':
                        pass
                    elif prefix == 'type' and event == 'string' and value == 'FeatureCollection':
                        pass
                    elif prefix == '' and event == 'map_key' and value == 'features':
                        row_inserts = 0
                        row_updates = 0
                        data_errors = 0
                        ignored_rows = 0
                    elif prefix == 'features' and event == 'start_array':
                        pass
                    elif prefix == 'features.item' and event == 'start_map':
                        pass
                    elif prefix == 'features.item' and event == 'map_key' and value == 'type':
                        pass
                    elif prefix == 'features.item.type' and event == 'string':
                        db_table_name = registry_spec[registry]['feature_entities'][value]
                        if db_table_name in table_names:  # Ignoring obsolete tables
                            db_row = dict(table_names[db_table_name]['row'])
                        else:
                            ignored_rows +=1
                    elif prefix == 'features.item' and event == 'map_key' and value == 'properties':
                        pass
                    elif prefix == 'features.item.properties' and event == 'start_map':
                        pass
                    elif prefix == 'features.item.properties' and event == 'map_key':
                        db_column_name = value
                    elif prefix.startswith('features.item.properties') and event in ['null', 'boolean', 'integer', 'double', 'number', 'string']:
                        if db_table_name in table_names:  # Ignoring obsolete tables
                            db_row[db_column_name] = value
                        db_column_name = None
                    elif prefix == 'features.item.properties' and event == 'end_map':
                        finish_row()
                        db_row = None
                    elif prefix == 'features.item' and event == 'end_map':
                        pass
                    elif prefix == 'features' and event == 'end_array':
                        #  Only handles one table.
                        print(f"{ row_inserts:>10} rows inserted")
                        print(f"{ row_updates:>10} rows updated")
                        print(f"{ data_errors:>10} data errors")
                        print(f"{ignored_rows:>10} ignored rows in")
                        if row_inserts + row_updates > 0:
                            update_entity_integrity(cursor, table_names[db_table_name][None]['bitemporal_primary_key'], db_table_name)
                        db_table_name = None
                    elif prefix == '' and event == 'end_map':
                        pass  # The top level
                    else:
                        raise NotImplementedError
        update_db_row(cursor, 'file_extract',
                      {'id': file_extract_id, 'load_end': datetime.datetime.now(datetime.timezone.utc).isoformat()})
        create_status_report(cursor, file_extract_id, registry)
        update_db_row(cursor, 'file_extract',
                      {'id': file_extract_id, 'stats_end': datetime.datetime.now(datetime.timezone.utc).isoformat()})
    print("Done...")
    conn.commit()

def create_status_report(cursor, file_extract_id, registry):
    print("Creating status report...")
    SQL = f"""
        insert into status_report
--(table_name, bitemporal_entity_integrity_count,
--       bitemporal_entity_integrity_objects,
--       bitemporal_entity_integrity_instances)
select %(file_extract_id)s as file_extract_id,
       registry_table.registry,
       registry_table.table_name as table_name,
       COALESCE(instance_count,0),
       COALESCE(object_count,0),
       COALESCE(invalid_update_count,0),
       COALESCE(non_positive_interval_registrering,0),
       COALESCE(non_positive_interval_virkning,0),
       COALESCE(bitemporal_entity_integrity_count,0),
       COALESCE(bitemporal_entity_integrity_instances,0),
       COALESCE(bitemporal_entity_integrity_objects,0),
       total_instance_count,
       total_object_count,
       COALESCE(total_non_positive_interval_registrering,0),
       COALESCE(total_non_positive_interval_virkning,0),
       COALESCE(total_bitemporal_entity_integrity_count,0),
       COALESCE(total_bitemporal_entity_integrity_instances,0),
       COALESCE(total_bitemporal_entity_integrity_objects,0)
from registry_table
 left join
    (
         select table_name,
                count(*)                               as bitemporal_entity_integrity_count,
                count(distinct bitemporal_primary_key) as bitemporal_entity_integrity_objects
         from entity_integrity_violation
         where ent1_file_extract_id = %(file_extract_id)s OR ent2_file_extract_id = %(file_extract_id)s
         group by table_name
     ) file_simple_stats on file_simple_stats.table_name = registry_table.table_name
         left join (
    select table_name, count(*) as bitemporal_entity_integrity_instances
    from (
             select distinct table_name,
                             bitemporal_primary_key || ent1_registreringFra_UTC || ent1_virkningFra_UTC as primary_key
             from entity_integrity_violation
             where ent1_file_extract_id = %(file_extract_id)s OR ent2_file_extract_id = %(file_extract_id)s
             union
             select distinct table_name,
                             bitemporal_primary_key || ent2_registreringFra_UTC || ent2_virkningFra_UTC as primary_key
             from entity_integrity_violation
             where ent1_file_extract_id = %(file_extract_id)s OR ent2_file_extract_id = %(file_extract_id)s
         )
    group by table_name
) file_instance_stats on file_instance_stats.table_name = registry_table.table_name
left join (select file_extract_id, table_name, 
                  count(*) as invalid_update_count,
                  SUM(case when violation_type ='Ugyldig opdatering af værdier' THEN 1 ELSE 0 END) as invalid_update_count,
                  SUM(case when violation_type ='Ikke-positivt registreringsinterval' THEN 1 ELSE 0 END) as non_positive_interval_registrering,
                  SUM(case when violation_type ='Ikke-positivt virkningsinterval' THEN 1 ELSE 0 END) as non_positive_interval_virkning
                  from violation_log
                  where violation_log.file_extract_id = %(file_extract_id)s)
          violation_counts 
         on violation_counts.table_name = registry_table.table_name
         and  violation_counts.file_extract_id = %(file_extract_id)s
left join ("""
    tables = [n for n in table_names.keys() if table_names[n]['registry'] == registry]
    SQL += " union ".join(map(lambda t_name: f"""
select '{t_name}' as table_name,
count(*) as instance_count,
count(distinct {"||':'||".join([k for k in table_names[t_name][None]['bitemporal_primary_key']])}) as object_count
from {t_name}
where coalesce(update_file_extract_id, file_extract_id) = %(file_extract_id)s
            """,tables))
    SQL += """
    ) file_table_counts on file_table_counts.table_name = registry_table.table_name 
 left join
    (
         select table_name,
                count(*)                               as total_bitemporal_entity_integrity_count,
                count(distinct bitemporal_primary_key) as total_bitemporal_entity_integrity_objects
         from entity_integrity_violation
         group by table_name
     ) total_simple_stats on total_simple_stats.table_name = registry_table.table_name
         left join (
    select table_name, count(*) as total_bitemporal_entity_integrity_instances
    from (
             select distinct table_name,
                             bitemporal_primary_key || ent1_registreringFra_UTC || ent1_virkningFra_UTC as primary_key
             from entity_integrity_violation
             union
             select distinct table_name,
                             bitemporal_primary_key || ent2_registreringFra_UTC || ent2_virkningFra_UTC as primary_key
             from entity_integrity_violation
         )
    group by table_name
) total_instance_stats on total_instance_stats.table_name = registry_table.table_name
left join ("""
    tables = [n for n in table_names.keys() if table_names[n]['registry'] == registry]
    SQL += " union ".join(map(lambda t_name: f"""
select '{t_name}' as table_name,
count(*) as total_instance_count,
count(distinct {"||':'||".join([k for k in table_names[t_name][None]['bitemporal_primary_key']])}) as total_object_count,
SUM(case when registreringTil_UTC <= registreringFra_UTC THEN 1 ELSE 0 END) as total_non_positive_interval_registrering,
SUM(case when virkningTil_UTC <= virkningFra_UTC THEN 1 ELSE 0 END) as total_non_positive_interval_virkning
from {t_name}
            """,tables))
    SQL += """
    ) total_table_counts on total_table_counts.table_name = registry_table.table_name 
    """
    SQL += "where registry_table.registry = %(registry)s;"
    cursor.execute(SQL,{'file_extract_id': file_extract_id,'registry':registry})


if __name__ == '__main__':
    import plac
    plac.call(main)
