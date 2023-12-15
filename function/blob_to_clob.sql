
  CREATE OR REPLACE EDITIONABLE FUNCTION "BLOB_TO_CLOB" (p_data  IN  BLOB)
  RETURN CLOB
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/blob_to_clob.sql
-- Author       : Tim Hall
-- Description  : Converts a BLOB to a CLOB.
-- Last Modified: 26/12/2016
-- -----------------------------------------------------------------------------------
AS
  l_clob         CLOB;
  l_dest_offset  PLS_INTEGER := 1;
  l_src_offset   PLS_INTEGER := 1;
  l_lang_context PLS_INTEGER := DBMS_LOB.default_lang_ctx;
  l_warning      PLS_INTEGER;
  v_logs_id      number;
BEGIN

  DBMS_LOB.createTemporary(
    lob_loc => l_clob,
    cache   => TRUE);

  DBMS_LOB.converttoclob(
   dest_lob      => l_clob,
   src_blob      => p_data,
   amount        => DBMS_LOB.lobmaxsize,
   dest_offset   => l_dest_offset,
   src_offset    => l_src_offset, 
   blob_csid     => DBMS_LOB.default_csid,
   lang_context  => l_lang_context,
   warning       => l_warning);

   RETURN l_clob;
EXCEPTION when others then

       v_logs_id := pls_logger.log_error(p_proc_name             => 'blob_to_clob', 
                                          p_diagnostic_level      => 'ERROR', 
                                          p_additional_parameter  => 'p_data size='||dbms_lob.getlength(p_data), 
                                          p_request               => null, 
                                          p_responce              => l_clob);
   RETURN null;
END;
/
