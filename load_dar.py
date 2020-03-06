import json
from zipfile import ZipFile

from pprint import pprint

def main(data_package):
    if not data_package[-4:] == '.zip':
        raise ValueError("data_package must be a zip file and end with '.zip'")
    package_name = data_package[:-4]
    print(f'Loading data fro {package_name}')
    with ZipFile(data_package, 'r') as myzip:
        myzip
    # ...

if __name__ == '__main__':
    import plac; plac.call(main)
