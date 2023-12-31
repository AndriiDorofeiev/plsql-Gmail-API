CREATE TABLESPACE "GOOGLE_MAIL" DATAFILE
  '/u03/oradata/CDB1/pdb1/google_mail_001.dbf' SIZE 10485760 -- adjust you path to files
  AUTOEXTEND ON NEXT 10485760 MAXSIZE 32767M,
  '/u03/oradata/CDB1/pdb1/google_mail_002.dbf' SIZE 10485760 -- adjust you path to files
  AUTOEXTEND ON NEXT 10485760 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS SEGMENT SPACE MANAGEMENT AUTO;

CREATE USER "GOOGLE_MAIL" IDENTIFIED BY <<PASSWORD>>
 DEFAULT TABLESPACE "GOOGLE_MAIL" TEMPORARY TABLESPACE "TEMP";

GRANT "CONNECT" TO "GOOGLE_MAIL";

GRANT "RESOURCE" TO "GOOGLE_MAIL";

GRANT CREATE ANY VIEW TO "GOOGLE_MAIL";

GRANT CREATE ANY JOB TO "GOOGLE_MAIL";

