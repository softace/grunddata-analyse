-- This requires privileges
CREATE DATABASE DAF;
CREATE USER daf_admin WITH ENCRYPTED PASSWORD 'daf_admin';
GRANT ALL ON DATABASE DAF TO daf_admin;
