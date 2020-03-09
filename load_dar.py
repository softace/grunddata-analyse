import ijson
from zipfile import ZipFile
from pprint import pprint


def readAdresseList(list):
    for elem in list:
        pprint(elem)

def readAdressepunktList(list):
    for elem in list:
        pprint(elem)

def readHusnummerList(list):
    for elem in list:
        pprint(elem)

def readNavngivenVejList(list):
    for elem in list:
        pprint(elem)

def readNavngivenVejKommunedelList(list):
    for elem in list:
        pprint(elem)

def readNavngivenVejPostnummerList(list):
    for elem in list:
        pprint(elem)

def readNavngivenVejSupplerendeBynavnList(list):
    for elem in list:
        pprint(elem)

def readPostnummerList(list):
    for elem in list:
        pprint(elem)

def readSupplerendeBynavnList(list):
    for elem in list:
        pprint(elem)


def main(data_package):
    if not data_package[-4:] == '.zip':
        raise ValueError("data_package must be a zip file and end with '.zip'")
    package_name = data_package[:-4]
    print(f'Loading data fro {package_name}')
    with ZipFile(data_package, 'r') as myzip:

        for info in myzip.infolist():
            print(info.filename)
        json_data_name = next(x for x in myzip.namelist() if not 'Metadata' in x)
        with myzip.open(json_data_name) as file:
            for (listName, list) in ijson.kvitems(file, ''):
                eval('read' + listName)(list)

if __name__ == '__main__':
    import plac; plac.call(main)
