import ijson
from zipfile import ZipFile
from pprint import pprint


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
            # AdresseList
            # AdressepunktList
            # HusnummerList
            # NavngivenVejList
            # NavngivenVejKommunedelList
            # NavngivenVejPostnummerList
            # NavngivenVejSupplerendeBynavnList
            # PostnummerList
            # SupplerendeBynavnList
            entities = ijson.items(file, 'AdresseList')
            pprint(entities)
            for e in entities:
                for adresse in e:
                    print(adresse['adressebetegnelse'])


if __name__ == '__main__':
    import plac; plac.call(main)
