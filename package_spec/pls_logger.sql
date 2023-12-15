CREATE OR REPLACE EDITIONABLE PACKAGE "PLS_LOGGER" 
AS 

    --   1.FATAL
    --   2.ERROR
    --   3.WARN
    --   4.INFO
    --   5.DEBUG
    --   6.TRACE

    FUNCTION log_error (
        p_proc_name            IN VARCHAR2,
        p_diagnostic_level     IN VARCHAR2 DEFAULT 'ERROR',
        p_additional_parameter IN VARCHAR2 DEFAULT NULL,
        p_request              IN CLOB DEFAULT NULL,
        p_responce             IN CLOB DEFAULT NULL
    ) RETURN NUMBER;

    PROCEDURE add_log_details (
        p_log_id IN NUMBER,
        p_key    IN VARCHAR2,
        p_values IN VARCHAR2
    );

    PROCEDURE add_log_clob (
        p_log_id   IN NUMBER,
        p_request  IN CLOB DEFAULT NULL,
        p_responce IN CLOB DEFAULT NULL
    );

END pls_logger;
/
