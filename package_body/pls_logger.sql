CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PLS_LOGGER" 
AS

    FUNCTION log_error (
        p_proc_name            IN VARCHAR2,
        p_diagnostic_level     IN VARCHAR2 DEFAULT 'ERROR',
        p_additional_parameter IN VARCHAR2 DEFAULT NULL,
        p_request              IN CLOB DEFAULT NULL,
        p_responce             IN CLOB DEFAULT NULL
    ) RETURN NUMBER 
    AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        l_rec           process_monitor%rowtype;
        l_ret           number;
    BEGIN
    
        l_rec.PROCESSNAME := p_proc_name;
        l_rec.DIAGNOSTIC_LEVEL := p_diagnostic_level;
        l_rec.ERROR_CODE := SQLCODE;
        
        if p_diagnostic_level = ('INFO') then        
           l_rec.ERROR_TEXT := 'Ok'; 
        else
           l_rec.ERROR_TEXT := SQLERRM;
           l_rec.EXCEPTIONPATH := DBMS_UTILITY.format_error_stack||' '||chr(10)||DBMS_UTILITY.format_error_backtrace;
        end if;

        l_rec.ADDITIONAL_PARAMETERS := p_additional_parameter;
        l_rec.INSERT_TIME := sysdate;

        insert into process_monitor values l_rec returning id into l_ret;
        commit;

        if p_request is not null or p_responce is not null then 
           insert into process_monitor_detail (PR_MON_ID, REQUEST, RESPONCE) values (l_ret, p_request, p_responce);
           commit;
        end if;

        RETURN l_ret;

    END log_error;

    PROCEDURE add_log_details (
        p_log_id IN NUMBER,
        p_key    IN VARCHAR2,
        p_values IN VARCHAR2
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;    
    BEGIN
        insert into process_monitor_detail (PR_MON_ID, PAR_KEY, PAR_VALUE) values (p_log_id, p_key, p_values);
        commit;
    END add_log_details;

    PROCEDURE add_log_clob (
        p_log_id   IN NUMBER,
        p_request  IN CLOB DEFAULT NULL,
        p_responce IN CLOB DEFAULT NULL
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;    
    BEGIN
        insert into process_monitor_detail (PR_MON_ID, REQUEST, RESPONCE) values (p_log_id, p_request, p_responce);
        commit;
    END add_log_clob;

END pls_logger;
/
