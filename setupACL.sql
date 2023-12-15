BEGIN
    DBMS_NETWORK_ACL_ADMIN.DROP_ACL (
        ACL => '/sys/acls/googleAPI.xml'
    );
    COMMIT;
END;
/

BEGIN
    DBMS_NETWORK_ACL_ADMIN.CREATE_ACL (
        ACL => '/sys/acls/googleAPI.xml',
        DESCRIPTION => '/sys/acls/googleAPI.xml',
        PRINCIPAL => 'APEX_PUBLIC_USER',
        IS_GRANT => TRUE,
        PRIVILEGE => 'connect',
        START_DATE => NULL,
        END_DATE => NULL
    );
    COMMIT;
END;
/

BEGIN
    DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL (
        ACL => '/sys/acls/googleAPI.xml',
        HOST => '*.googleapis.com',
        LOWER_PORT => 80,
        UPPER_PORT => 1024
    );
    COMMIT;
END;
/

BEGIN
    DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE (
        ACL => '/sys/acls/googleAPI.xml',
        PRINCIPAL => 'APEX_210200', -- adjust you APEX Installation schema
        IS_GRANT => TRUE,
        PRIVILEGE => 'connect',
        START_DATE => NULL,
        END_DATE => NULL
    );
    COMMIT;
END;
/

BEGIN
    DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE (
        ACL => '/sys/acls/googleAPI.xml',
        PRINCIPAL => 'GOOGLE_MAIL', -- adjust you oracle user
        IS_GRANT => TRUE,
        PRIVILEGE => 'connect',
        START_DATE => NULL,
        END_DATE => NULL
    );
    COMMIT;
END;
/

BEGIN
    DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL (
        ACL => '/sys/acls/googleAPI.xml',
        HOST => 'accounts.google.com',
        LOWER_PORT => 80,
        UPPER_PORT => 1024
    );
    COMMIT;
END;
/

BEGIN
    DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE (
        ACL => '/sys/acls/googleAPI.xml',
        PRINCIPAL => 'APEX_210200', -- adjust you APEX Installation schema
        IS_GRANT => TRUE,
        PRIVILEGE => 'connect',
        START_DATE => NULL,
        END_DATE => NULL
    );
    COMMIT;
END;
/

BEGIN
    DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE (
        ACL => '/sys/acls/googleAPI.xml',
        PRINCIPAL => 'APEX_PUBLIC_USER',
        IS_GRANT => TRUE,
        PRIVILEGE => 'connect',
        START_DATE => NULL,
        END_DATE => NULL
    );
    COMMIT;
END;
/

BEGIN
    DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE (
        ACL => '/sys/acls/googleAPI.xml',
        PRINCIPAL => 'APEX_210200', -- adjust you APEX Installation schema
        IS_GRANT => TRUE,
        PRIVILEGE => 'connect',
        START_DATE => NULL,
        END_DATE => NULL
    );
    COMMIT;
END;
/

BEGIN
    DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL (
        ACL => '/sys/acls/googleAPI.xml',
        HOST => 'gmail.googleapis.com',
        LOWER_PORT => 80,
        UPPER_PORT => 1024
    );
    COMMIT;
END;
/

BEGIN
    DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE (
        ACL => '/sys/acls/googleAPI.xml',
        PRINCIPAL => 'APEX_PUBLIC_USER',
        IS_GRANT => TRUE,
        PRIVILEGE => 'connect',
        START_DATE => NULL,
        END_DATE => NULL
    );
    COMMIT;
END;
/

BEGIN
    DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE (
        ACL => '/sys/acls/googleAPI.xml',
        PRINCIPAL => 'GOOGLE_MAIL', -- adjust you oracle user
        IS_GRANT => TRUE,
        PRIVILEGE => 'connect',
        START_DATE => NULL,
        END_DATE => NULL
    );
    COMMIT;
END;
/