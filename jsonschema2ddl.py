import os
import json
import sqlite3

from pprint import pprint

# read JSON into data structure
with open("DAR_v2.3.6_2019.08.18_DLS/DAR_v2.3.6_2019.08.19_DARTotal.schema.json") as file:
    jsonschema = json.load(file)

conn = sqlite3.connect('example.db')

# print DDL
for (table_name, table_content) in jsonschema['properties'].items():
    assert(table_content['type'] == 'array')
    SQL = "CREATE TABLE " + table_name + "(\n"
    for (att_name, att_content) in table_content['items']['properties'].items():
#        print(f"  {att_name: <20} {att_content['type'][0]: <10} {att_content['type'][1]},")
        SQL += f"  {att_name: <20} {'TEXT': <10},\n"
    SQL += "\n"
    SQL += "  PRIMARY KEY(id_lokalId, registreringFra, virkningFra)\n"
    SQL += ");\n"
    print(SQL)
    conn.execute(SQL)
conn.commit()
conn.close()
