CREATE OR REPLACE EDITIONABLE FUNCTION "GET_PROPERTIE" (
  P_PROPERTIE IN VARCHAR2
) RETURN VARCHAR2 AS
  LANGUAGE JAVA NAME 'getPropertie.getProp(java.lang.String) return String';
/