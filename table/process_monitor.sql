CREATE TABLE "PROCESS_MONITOR" (
	"ID" NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1027478 CACHE 20 NOORDER NOCYCLE NOKEEP NOSCALE NOT NULL ENABLE,
	"PROCESSNAME" VARCHAR2(128 CHAR),
	"DIAGNOSTIC_LEVEL" VARCHAR2(10 CHAR),
	"ERROR_CODE" NUMBER,
	"ERROR_TEXT" VARCHAR2(4000 CHAR),
	"EXCEPTIONPATH" VARCHAR2(2048 CHAR),
	"ADDITIONAL_PARAMETERS" VARCHAR2(2000 CHAR),
	"INSERT_TIME" DATE DEFAULT SYSDATE NOT NULL ENABLE,
	CONSTRAINT "DIAGN_LEV_CHECK" CHECK (DIAGNOSTIC_LEVEL IN ('FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG', 'TRACE')) ENABLE,
	CONSTRAINT "PM_PK" PRIMARY KEY ("ID") USING INDEX ENABLE
);