select * from file_extract;

select * from metadata;
select * from violation_log;
SELECT name FROM sqlite_master WHERE type='table';


delete from Adresse where file_extract_id >2 or update_file_extract_id > 2;
delete from Adressepunkt where file_extract_id >2 or update_file_extract_id > 2;
delete from Husnummer where file_extract_id >2 or update_file_extract_id > 2;
delete from NavngivenVej where file_extract_id >2 or update_file_extract_id > 2;
delete from NavngivenVejKommunedel where file_extract_id >2 or update_file_extract_id > 2;
delete from NavngivenVejPostnummer where file_extract_id >2 or update_file_extract_id > 2;
delete from NavngivenVejSupplerendeBynavn where file_extract_id >2 or update_file_extract_id > 2;
delete from Postnummer where file_extract_id >2 or update_file_extract_id > 2;
delete from SupplerendeBynavn where file_extract_id >2 or update_file_extract_id > 2;
delete from BBRSag where file_extract_id >2 or update_file_extract_id > 2;
delete from Bygning where file_extract_id >2 or update_file_extract_id > 2;
delete from BygningEjendomsrelation where file_extract_id >2 or update_file_extract_id > 2;
delete from Ejendomsrelation where file_extract_id >2 or update_file_extract_id > 2;
delete from Enhed where file_extract_id >2 or update_file_extract_id > 2;
delete from EnhedEjendomsrelation where file_extract_id >2 or update_file_extract_id > 2;
delete from Etage where file_extract_id >2 or update_file_extract_id > 2;
delete from FordelingAfFordelingsareal where file_extract_id >2 or update_file_extract_id > 2;
delete from Fordelingsareal where file_extract_id >2 or update_file_extract_id > 2;
delete from Grund where file_extract_id >2 or update_file_extract_id > 2;
delete from GrundJordstykke where file_extract_id >2 or update_file_extract_id > 2;
delete from Opgang where file_extract_id >2 or update_file_extract_id > 2;
delete from Sagsniveau where file_extract_id >2 or update_file_extract_id > 2;
delete from TekniskAnlæg where file_extract_id >2 or update_file_extract_id > 2;

delete from violation_log where file_extract_id >2;
delete from metadata where file_extract_id >2;
delete from file_extract where id >2;

