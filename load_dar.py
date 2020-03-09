#!/usr/bin/env/python
import ijson
from zipfile import ZipFile
from pprint import pprint
import sqlite3


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
        except Exception as e:
            print(SQL)
            raise e
    print(f'populating {listName} done with {rows} rows.')


def main(data_package):
    if not data_package[-4:] == '.zip':
        raise ValueError("data_package must be a zip file and end with '.zip'")
    package_name = data_package[:-4]
    print(f'Loading data from {package_name}')
    conn = sqlite3.connect('example.db')
    with ZipFile(data_package, 'r') as myzip:

        for info in myzip.infolist():
            print(info.filename)
        json_data_name = next(x for x in myzip.namelist() if not 'Metadata' in x)
        with myzip.open(json_data_name) as file:
            for (listName, list) in ijson.kvitems(file, ''):
                populate(conn, listName, list)
                conn.commit()
    conn.close()

if __name__ == '__main__':
    import plac; plac.call(main)
