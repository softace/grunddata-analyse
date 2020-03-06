import os
import json
from pprint import pprint

# read JSON into data structure
with open("DAR_v2.3.6_2019.08.19_DARTotal.schema.json") as file:
    jsonschema = json.load(file)

# print DDL
#pprint(jsonschema)

for (table_name, table_content) in jsonschema['properties'].items():
    assert(table_content['type'] == 'array')
    print("CREATE TABLE " + table_name + "(")
    for (att_name, att_content) in table_content['items']['properties'].items():
#        print(f"  {att_name: <20} {att_content['type'][0]: <10} {att_content['type'][1]},")
        print(f"  {att_name: <20} {'TEXT': <10},")
#        pprint(att_content['type'])
    print("PRIMARY KEY(id_lokalId (ASC)")
    print(");")

#json.dump(jsonschema)
