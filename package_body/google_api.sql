CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GOOGLE_API" 
AS

    l_authorization_url  constant varchar2(80):='https://accounts.google.com/o/oauth2/token';
    l_client_id	       constant varchar2(80):=get_propertie('googlemail.client_id');
    l_client_secret      constant varchar2(80):=get_propertie('googlemail.client_secret');
    l_redirect_uri	    constant varchar2(25):='urn:ietf:wg:oauth:2.0:oob';
    l_response_type      constant varchar2(5) :='code';
    
    l_user_id            constant varchar2(30):='dorofeyev.andrey@gmail.com';
    g_messages_url       constant varchar2(80):='https://gmail.googleapis.com/gmail/v1/users/'||l_user_id||'/messages';    
    g_labels_url         constant varchar2(80):='https://gmail.googleapis.com/gmail/v1/users/'||l_user_id||'/labels';    
    
    l_authorization_code constant varchar2(62):=get_propertie('googlemail.authorization_code');
    
    l_token_endpoint constant varchar2(5):='code';
    
    l_access_token   varchar2(218);
    l_refresh_token  varchar2(103);

  wallet_path      constant varchar2(64):= get_propertie('wallet.path');
  wallet_pwd       constant varchar2(64):= get_propertie('wallet.pwd');

  v_logs_id number;

  dml_errors EXCEPTION;
  PRAGMA EXCEPTION_INIT (dml_errors, -24381);

  ErrCode             NUMBER;
  errindex            NUMBER;
  errmsg              VARCHAR2 (4000);


  function getACCESSTocken return CLOB
  AS
    l_clob            CLOB;
    l_request_body    varchar2(1000 CHAR);
    l_grant_type      constant varchar2(30):= 'authorization_code';
  BEGIN

   apex_web_service.g_request_headers.delete;
   apex_web_service.g_request_headers(1).name  := 'Content-Type';
   apex_web_service.g_request_headers(1).value := 'application/x-www-form-urlencoded';

   l_request_body:='code='||l_authorization_code||'&'||'client_id='||l_client_id||'&'||'client_secret='||l_client_secret||'&'||'redirect_uri='||l_redirect_uri||'&'||'grant_type='||l_grant_type;

   l_clob := apex_web_service.make_rest_request(
        p_url         => l_authorization_url,
        p_http_method => 'POST',
        p_wallet_path => wallet_path,
        p_wallet_pwd  => wallet_pwd,
        p_body        => l_request_body);

       return l_clob;

  exception when others then
    return '{"status":"error", "code": "'||SQLCODE||'", "message": "'||SQLERRM||'", "http_detailed_message":"'||UTL_HTTP.get_detailed_sqlerrm||'"}';
  END;


    procedure refreshToken
    as
        l_clob            CLOB;
        l_request_body    varchar2(1000 CHAR);
        l_token           JSON_OBJECT_T;
        l_grant_type      constant varchar2(30):= 'refresh_token';
        l_error_text      VARCHAR2(512 CHAR);
        l_error_desc      VARCHAR2(1024 CHAR);
    begin
    
       apex_web_service.g_request_headers.delete;
       apex_web_service.g_request_headers(1).name  := 'Content-Type';
       apex_web_service.g_request_headers(1).value := 'application/x-www-form-urlencoded';

       l_request_body:='client_id='||l_client_id||'&'||'client_secret='||l_client_secret||'&'||'refresh_token='||l_refresh_token||'&'||'grant_type='||l_grant_type;

       l_clob := apex_web_service.make_rest_request(
            p_url         => l_authorization_url,
            p_http_method => 'POST',
            p_wallet_path => wallet_path,
            p_wallet_pwd  => wallet_pwd,
            p_body        => l_request_body);

       l_token:=JSON_OBJECT_T(l_clob);

        if l_token.has('error') then
           l_error_text:=l_token.get_String('error');
           l_error_desc:=l_token.get_String('error_description');

        v_logs_id := pls_logger.log_error(p_proc_name             => 'refreshToken', 
                                          p_diagnostic_level      => 'ERROR', 
                                          p_additional_parameter  => 'error='||l_error_text||', error_description='||l_error_desc, 
                                          p_request               => null, 
                                          p_responce              => l_clob);

        else
           l_access_token  := l_token.get_String('access_token');
        end if;
    
    end;

  procedure setACCESSTocken
  AS
    l_clob CLOB;
    l_HTTP_error_message  VARCHAR2(512 CHAR);
    l_token               JSON_OBJECT_T;
    l_error_text  VARCHAR2(128 CHAR);
    l_error_desc  VARCHAR2(128 CHAR);
  BEGIN
        l_clob := getACCESSTocken;

        l_token:=JSON_OBJECT_T(l_clob);
        
        if l_token.has('error') then
           l_error_text:=l_token.get_String('error');
           l_error_desc:=l_token.get_String('error_description');

        v_logs_id := pls_logger.log_error(p_proc_name             => 'setACCESSTocken', 
                                          p_diagnostic_level      => 'ERROR', 
                                          p_additional_parameter  => 'error='||l_error_text||', error_description='||l_error_desc, 
                                          p_request               => null, 
                                          p_responce              => l_clob);
        else
           l_access_token  := l_token.get_String('access_token');
           l_refresh_token := l_token.get_String('refresh_token');
        end if;
  END;

    function base64url_normalise (p_par in CLOB) return CLOB
    as
    begin
     return REGEXP_REPLACE (REGEXP_REPLACE (p_par, '-', '+'), '_', '/');
    end;

    function get_attachment_local (p_attachment_id in varchar2) return blob
    as
      l_att_body  JSON_OBJECT_T;
      l_body      CLOB;
      l_ret       BLOB;
    begin
    
        select ATTACHMENT_BODY into l_body from attachment_original where id = p_attachment_id;
        l_att_body:=JSON_OBJECT_T(l_body);
        l_ret:=apex_web_service.clobbase642blob(base64url_normalise(l_att_body.get_Clob('data'))); 
        return l_ret;
    exception when no_data_found then
         return null;
              when others then 
            v_logs_id := pls_logger.log_error(p_proc_name         => 'get_attachment_local', 
                                          p_diagnostic_level      => 'ERROR', 
                                          p_additional_parameter  => 'attachment_id='||p_attachment_id, 
                                          p_request               => null, 
                                          p_responce              => l_body);
         return null;
    end;

    procedure parts_process (p_message_id in varchar2, p_parts_array in JSON_ARRAY_T)
    as
       l_attachments_rec         message_attachments%rowtype;
       l_parts_rec               JSON_OBJECT_T;
       l_partsHeaders_rec        JSON_OBJECT_T;
       l_attachment_body         JSON_OBJECT_T;
       l_attachment_headers_rec  attachment_headers%rowtype;
       l_partsArray              JSON_ARRAY_T;
       l_partsHeadersArray       JSON_ARRAY_T;
       l_clob_body               CLOB;
       l_dummy                   CLOB;
    begin
               FOR i IN 0 .. p_parts_array.get_size - 1 LOOP
                    l_parts_rec:=TREAT(p_parts_array.get(i) AS JSON_OBJECT_T); 
                    
                    if l_parts_rec.has('parts') then
                       l_partsArray:=l_parts_rec.get_Array('parts'); 
                       parts_process(p_message_id, l_partsArray);
                    end if;
                    
                    l_attachments_rec:=null;
                    l_clob_body:=null;
                    l_attachments_rec.id       := p_message_id;
                    l_attachments_rec.PART_ID  := l_parts_rec.get_string('partId');
                    l_attachments_rec.MIMETYPE := l_parts_rec.get_string('mimeType');
                    l_attachments_rec.FILENAME := l_parts_rec.get_string('filename');

                    if l_parts_rec.has('body') then
                       l_attachment_body:=l_parts_rec.get_object('body');
                       l_attachments_rec.body_size:= l_attachment_body.get_number('size');

                       if l_attachment_body.has('attachmentId') then
                          l_attachments_rec.ATTACHMENT_ID:=l_attachment_body.get_String('attachmentId');
                       end if;   
                       if l_attachment_body.has('data') then
                          l_clob_body:=l_attachment_body.get_Clob('data');
                       end if;

                        if l_clob_body is not null or l_attachments_rec.ATTACHMENT_ID is not null then
                            if l_clob_body is not null then
                              if l_attachments_rec.MIMETYPE = 'text' or l_attachments_rec.MIMETYPE like 'text/%' then 
                                 l_attachments_rec.attachment_clob:=BLOB_TO_CLOB(apex_web_service.clobbase642blob(base64url_normalise(l_clob_body))); 
                              else  
                                 l_attachments_rec.ATTACHMENT:=apex_web_service.clobbase642blob(base64url_normalise(l_clob_body)); 
                              end if; 
                            end if; 

                            if l_attachments_rec.ATTACHMENT_ID is not null then
                              if l_attachments_rec.MIMETYPE = 'text' or l_attachments_rec.MIMETYPE like 'text/%' then 
                                 l_attachments_rec.attachment_clob:=BLOB_TO_CLOB(get_attachment_local(l_attachments_rec.ATTACHMENT_ID)); 
                              else  
                                 l_attachments_rec.ATTACHMENT:=get_attachment_local(l_attachments_rec.ATTACHMENT_ID); 
                              end if; 
                            end if; 

                        insert /*+ ignore_row_on_dupkey_index (message_attachments MESSAGE_ATTACHMENTS_UK) */ into message_attachments values l_attachments_rec;

                        end if; 
                    end if;

                 if l_parts_rec.has('headers') then
                    l_partsHeadersArray  := l_parts_rec.get_Array('headers');

                    FOR i IN 0 .. l_partsHeadersArray.get_size - 1 LOOP
                        l_partsHeaders_rec:=TREAT(l_partsHeadersArray.get(i) AS JSON_OBJECT_T); 
                        l_attachment_headers_rec.id           := p_message_id;
                        l_attachment_headers_rec.PART_ID      := l_attachments_rec.PART_ID;
                        l_attachment_headers_rec.HEADER_NAME  := l_partsHeaders_rec.get_string('name');
                        l_attachment_headers_rec.HEADER_VALUE := l_partsHeaders_rec.get_Clob('value');

                        insert into attachment_headers values l_attachment_headers_rec;

                    END LOOP;
                end if;

               END LOOP;                
        end;



    function get_message_attachment (p_message_id in varchar2, p_attachment_id in varchar2) RETURN BLOB
    as
       l_resp        JSON_OBJECT_T;
       l_error_text  VARCHAR2(512 CHAR);
       l_error_desc  VARCHAR2(1024 CHAR);       
       l_clob        CLOB;    
       l_ret         BLOB;
    begin
         if l_access_token is null then
            setACCESSTocken;
         end if;

        apex_web_service.g_request_headers.delete;
        apex_web_service.g_request_headers(1).name  := 'Authorization';
        apex_web_service.g_request_headers(1).value := 'Bearer '||l_access_token;

        apex_web_service.g_request_headers(2).name  := 'Accept';
        apex_web_service.g_request_headers(2).value := 'application/json';
        
       l_clob := apex_web_service.make_rest_request(
            p_url         => g_messages_url||'/'||p_message_id||'/attachments/'||p_attachment_id,
            p_http_method => 'GET',
            p_wallet_path => wallet_path,
            p_wallet_pwd  => wallet_pwd);

       l_resp:=JSON_OBJECT_T(l_clob);

        if l_resp.has('error') then
           l_error_text:=l_resp.get_String('error');
           l_error_desc:=l_resp.get_String('error_description');

           v_logs_id := pls_logger.log_error(p_proc_name             => 'get_message', 
                                             p_diagnostic_level      => 'ERROR', 
                                             p_additional_parameter  => 'error='||l_error_text||', error_description='||l_error_desc, 
                                             p_request               => null, 
                                             p_responce              => l_clob);
        else
            l_ret:=apex_web_service.clobbase642blob(base64url_normalise(l_resp.get_Clob('data'))); 

            insert /*+ ignore_row_on_dupkey_index (attachment_original ATTACHMENT_ORIGINAL_PK) */ into attachment_original (ID, ATTACHMENT_BODY) values (p_attachment_id, l_clob);
            commit;

       end if;
       return l_ret;       
    exception when others then 
    
            v_logs_id := pls_logger.log_error(p_proc_name         => 'get_message', 
                                          p_diagnostic_level      => 'ERROR', 
                                          p_additional_parameter  => 'message_id='||p_message_id||', attachment_id='||p_attachment_id, 
                                          p_request               => null, 
                                          p_responce              => l_clob);
       return null;
    end;

    procedure get_message_attachment (p_message_id in varchar2, p_attachment_id in varchar2)
    as
       l_resp                 JSON_OBJECT_T;
       l_error_text           VARCHAR2(512 CHAR);
       l_error_desc           VARCHAR2(1024 CHAR);       
       l_clob                 CLOB;
    begin
         if l_access_token is null then
            setACCESSTocken;
         end if;

        apex_web_service.g_request_headers.delete;
        apex_web_service.g_request_headers(1).name  := 'Authorization';
        apex_web_service.g_request_headers(1).value := 'Bearer '||l_access_token;

        apex_web_service.g_request_headers(2).name  := 'Accept';
        apex_web_service.g_request_headers(2).value := 'application/json';
        
       l_clob := apex_web_service.make_rest_request(
            p_url         => g_messages_url||'/'||p_message_id||'/attachments/'||p_attachment_id,
            p_http_method => 'GET',
            p_wallet_path => wallet_path,
            p_wallet_pwd  => wallet_pwd);

       l_resp:=JSON_OBJECT_T(l_clob);

        if l_resp.has('error') then
           l_error_text:=l_resp.get_String('error');
           l_error_desc:=l_resp.get_String('error_description');

        v_logs_id := pls_logger.log_error(p_proc_name             => 'get_message', 
                                          p_diagnostic_level      => 'ERROR', 
                                          p_additional_parameter  => 'error='||l_error_text||', error_description='||l_error_desc, 
                                          p_request               => null, 
                                          p_responce              => l_clob);
        else

          
        insert /*+ ignore_row_on_dupkey_index (attachment_original ATTACHMENT_ORIGINAL_PK) */ into attachment_original (ID, ATTACHMENT_BODY) values (p_attachment_id, l_clob);
        commit;
        
       end if;
       
    exception when others then 
    
            v_logs_id := pls_logger.log_error(p_proc_name         => 'get_message', 
                                          p_diagnostic_level      => 'ERROR', 
                                          p_additional_parameter  => 'message_id='||p_message_id||', attachment_id='||p_attachment_id, 
                                          p_request               => null, 
                                          p_responce              => l_clob);
    end;

 procedure parse_message (p_message_id in varchar2, p_message_body in JSON_OBJECT_T)
 AS
       l_rec                     messages%rowtype;
       l_headers_rec             message_headers%rowtype;
       l_attachments_rec         message_attachments%rowtype;
       l_clob                    CLOB;
       l_clob_body               CLOB;
       l_payload                 JSON_OBJECT_T;
       l_payload_body            JSON_OBJECT_T;
       l_header_rec              JSON_OBJECT_T;
       l_dummy                   CLOB;
       l_headersArray            JSON_ARRAY_T;
       l_partsArray              JSON_ARRAY_T;
       l_nextPageToken           VARCHAR2(30 CHAR);       
       l_resultSizeEstimate      number;
       l_cnt                     number:=0;
 BEGIN
 
         if p_message_body.has('labelIds') then
            l_rec.LABELIDS:=p_message_body.get_Array('labelIds').stringify; 
         end if;
         if p_message_body.has('snippet') then
            l_rec.SNIPPET:=p_message_body.get_String('snippet'); 
         end if;
         if p_message_body.has('sizeEstimate') then
            l_rec.SIZEESTIMATE:=p_message_body.get_Number('sizeEstimate'); 
         end if;         
         if p_message_body.has('historyId') then
            l_rec.HISTORYID:=p_message_body.get_String('historyId'); 
         end if;         
         if p_message_body.has('internalDate') then
            l_rec.INTERNALDATE:=CAST(from_tz(to_timestamp('19700101000000','YYYYMMDDHH24MISS') + numtodsinterval(p_message_body.get_String('internalDate') / 1000,'SECOND'), 'GMT') AT TIME ZONE SESSIONTIMEZONE AS TIMESTAMP); 
         end if;
         
         if p_message_body.has('payload') then
            l_payload:=p_message_body.get_Object('payload'); 
            
            if l_payload.has('partId') then
               l_rec.PARTID:=l_payload.get_String('partId'); 
            end if;         
            if l_payload.has('filename') then
               l_rec.FILENAME:=l_payload.get_String('filename'); 
            end if;         
            if l_payload.has('mimeType') then
               l_rec.mime_Type:=l_payload.get_String('mimeType'); 
            end if;         
            
            if l_payload.has('body') then
               l_payload_body:=l_payload.get_Object('body'); 

               if l_payload_body.has('size') then
                  l_rec.BODY_SIZE:=l_payload_body.get_Number('size'); 
               end if;         
               if l_payload_body.has('attachmentId') then
                  l_attachments_rec.ATTACHMENT_ID:=l_payload_body.get_String('attachmentId');
               end if;   
               if l_payload_body.has('data') then
                  l_clob_body:=l_payload_body.get_Clob('data');                  
               end if;

                if l_clob_body is not null or l_attachments_rec.ATTACHMENT_ID is not null then 

                    if l_clob_body is not null then
                       if l_rec.mime_Type = 'text' or l_rec.mime_Type like 'text/%' then 
                          l_rec.EMAIL_BODY:=BLOB_TO_CLOB(apex_web_service.clobbase642blob(base64url_normalise(l_clob_body))); 
                       else  
                          l_attachments_rec.ATTACHMENT:=apex_web_service.clobbase642blob(base64url_normalise(l_clob_body)); 
                       end if; 
                    end if; 

                    if l_attachments_rec.ATTACHMENT_ID is not null then
                       if l_attachments_rec.MIMETYPE = 'text' or l_attachments_rec.MIMETYPE like 'text/%' then 
                          l_attachments_rec.attachment_clob:=BLOB_TO_CLOB(get_attachment_local(l_attachments_rec.ATTACHMENT_ID)); 
                       else  
                          l_attachments_rec.ATTACHMENT:=get_attachment_local(l_attachments_rec.ATTACHMENT_ID); 
                       end if; 
                    end if; 

                l_attachments_rec.id := p_message_id;
                l_attachments_rec.PART_ID := l_rec.PARTID;

                insert /*+ ignore_row_on_dupkey_index (message_attachments MESSAGE_ATTACHMENTS_UK) */ into message_attachments values l_attachments_rec;                  

                end if; 
            end if;

            if l_payload.has('parts') then
               l_partsArray:=l_payload.get_Array('parts'); 
               parts_process(p_message_id, l_partsArray);
            end if;

             if l_payload.has('headers') then
                l_headersArray  := l_payload.get_Array('headers');

                FOR i IN 0 .. l_headersArray.get_size - 1 LOOP
                    l_header_rec:=TREAT(l_headersArray.get(i) AS JSON_OBJECT_T); 
                    l_headers_rec.id           := p_message_id;
                    l_headers_rec.HEADER_NAME  := l_header_rec.get_String('name');
                    l_headers_rec.HEADER_VALUE := l_header_rec.get_Clob('value');
                    
                    if l_headers_rec.HEADER_NAME = 'Delivered-To' then
                       l_rec.DELIVERED_TO:=l_headers_rec.HEADER_VALUE;
                    end if;
                    if l_headers_rec.HEADER_NAME = 'Date' then
                       l_rec.MESSAGE_DATE:=l_headers_rec.HEADER_VALUE;
                    end if;                
                    if l_headers_rec.HEADER_NAME = 'From' then
                       l_rec.MESSAGE_FROM:=l_headers_rec.HEADER_VALUE;
                    end if;
                    if l_headers_rec.HEADER_NAME = 'Subject' then
                       l_rec.SUBJECT:=l_headers_rec.HEADER_VALUE;
                    end if;
                    if l_headers_rec.HEADER_NAME = 'To' then
                       l_rec.MESSAGE_TO:=l_headers_rec.HEADER_VALUE;
                    end if;
                    
                    insert into message_headers values l_headers_rec;
                     
                END LOOP;
            
            end if;
         end if;         
       
       update messages m
          set m.LABELIDS = l_rec.LABELIDS,
              m.SNIPPET = l_rec.SNIPPET,
              m.PARTID = l_rec.PARTID,
              m.FILENAME = l_rec.FILENAME,
              m.DELIVERED_TO = l_rec.DELIVERED_TO,
              m.MESSAGE_DATE = l_rec.MESSAGE_DATE,
              m.MESSAGE_FROM = l_rec.MESSAGE_FROM,
              m.SUBJECT = l_rec.SUBJECT,
              m.MESSAGE_TO = l_rec.MESSAGE_TO,
              m.BODY_SIZE = l_rec.BODY_SIZE,
              m.SIZEESTIMATE = l_rec.SIZEESTIMATE,
              m.HISTORYID = l_rec.HISTORYID,
              m.EMAIL_BODY = l_rec.EMAIL_BODY,
              m.INTERNALDATE = l_rec.INTERNALDATE,
              m.MODIFY_TIME = sysdate
        where m.id = p_message_id;
        
        insert /*+ ignore_row_on_dupkey_index (message_original MESSAGE_ORIGINAL_PK) */ into message_original (id, message_body) values (p_message_id, l_clob);        
        
        commit;
 
 END;

    procedure parse_label (p_label in JSON_OBJECT_T)
    as
       l_rec        labels%rowtype;
       l_color_obj  JSON_OBJECT_T;
    begin
    
        l_rec.ID   := p_label.get_String('id');
        l_rec.NAME := p_label.get_String('name');
        
        if p_label.has('messageListVisibility') then
           l_rec.MESSAGELISTVISIBILITY:= p_label.get_String('messageListVisibility');
        end if;
        if p_label.has('labelListVisibility') then
           l_rec.LABELLISTVISIBILITY:= p_label.get_String('labelListVisibility');
        end if;
        if p_label.has('type') then
           l_rec.TYPE:= p_label.get_String('type');
        end if;
        if p_label.has('messagesTotal') then
           l_rec.MESSAGESTOTAL:= p_label.get_Number('messagesTotal');
        end if;
        if p_label.has('messagesUnread') then
           l_rec.MESSAGESUNREAD:= p_label.get_Number('messagesUnread');
        end if;
        if p_label.has('threadsTotal') then
           l_rec.THREADSTOTAL:= p_label.get_Number('threadsTotal');
        end if;
        if p_label.has('threadsUnread') then
           l_rec.THREADSUNREAD:= p_label.get_Number('threadsUnread');
        end if;    
    
        if p_label.has('color') then
           l_color_obj:= p_label.get_Object('color');
           if l_color_obj.has('textColor') then
              l_rec.TEXTCOLOR:= l_color_obj.get_String('textColor');
           end if;    
           if l_color_obj.has('backgroundColor') then
              l_rec.BACKGROUNDCOLOR:= l_color_obj.get_String('backgroundColor');
           end if;       
        end if;    
        
        l_rec.change_time:=systimestamp;
        
        begin
          insert into labels values l_rec;
        
        exception when dup_val_on_index then
          update labels l 
             set l.NAME = l_rec.NAME,
                 l.MESSAGELISTVISIBILITY = l_rec.MESSAGELISTVISIBILITY,
                 l.LABELLISTVISIBILITY = l_rec.LABELLISTVISIBILITY,
                 l.TYPE = l_rec.TYPE,
                 l.MESSAGESTOTAL = l_rec.MESSAGESTOTAL,
                 l.MESSAGESUNREAD = l_rec.MESSAGESUNREAD,
                 l.THREADSTOTAL = l_rec.THREADSTOTAL,
                 l.THREADSUNREAD = l_rec.THREADSUNREAD,
                 l.TEXTCOLOR = l_rec.TEXTCOLOR,
                 l.BACKGROUNDCOLOR = l_rec.BACKGROUNDCOLOR,
                 l.CHANGE_TIME = systimestamp
           where l.id = l_rec.ID;
        end;
    end;

    procedure get_label (p_label_id in varchar2)
    as
      l_clob         CLOB;
      l_resp         JSON_OBJECT_T;
      l_label        JSON_OBJECT_T;
      l_labelsArray  JSON_ARRAY_T;
      l_error_text   VARCHAR2(512 CHAR);
      l_error_desc   VARCHAR2(1024 CHAR);             
    begin
    
       if l_access_token is null then
          setACCESSTocken;
       end if;
    
       apex_web_service.g_request_headers.delete;
       apex_web_service.g_request_headers(1).name  := 'Authorization';
       apex_web_service.g_request_headers(1).value := 'Bearer '||l_access_token;
    
       apex_web_service.g_request_headers(2).name  := 'Accept';
       apex_web_service.g_request_headers(2).value := 'application/json';
    
           l_clob := apex_web_service.make_rest_request(
                p_url         => g_labels_url||'/'||p_label_id,
                p_http_method => 'GET',
                p_wallet_path => wallet_path,
                p_wallet_pwd  => wallet_pwd);
                
      l_resp:=JSON_OBJECT_T(l_clob);
      
      if l_resp.has('error') then
         l_error_text:=l_resp.get_String('error');
         l_error_desc:=l_resp.get_String('error_description');

         v_logs_id := pls_logger.log_error(p_proc_name             => 'get_labels ', 
                                           p_diagnostic_level      => 'ERROR', 
                                           p_additional_parameter  => 'error='||l_error_text||', error_description='||l_error_desc||', label_id='||p_label_id, 
                                           p_request               => null, 
                                           p_responce              => l_clob);
      else
         parse_label(l_resp);
      end if;
   
    exception when others then 
    
            v_logs_id := pls_logger.log_error(p_proc_name         => 'get_labels', 
                                          p_diagnostic_level      => 'ERROR', 
                                          p_additional_parameter  => 'label_id='||p_label_id, 
                                          p_request               => null, 
                                          p_responce              => l_clob);  
    end;

    procedure get_labels_list
    as
      l_clob         CLOB;
      l_resp         JSON_OBJECT_T;
      l_label        JSON_OBJECT_T;
      l_labelsArray  JSON_ARRAY_T;
      l_error_text   VARCHAR2(512 CHAR);
      l_error_desc   VARCHAR2(1024 CHAR);             
    begin
    
       if l_access_token is null then
          setACCESSTocken;
       end if;
    
       apex_web_service.g_request_headers.delete;
       apex_web_service.g_request_headers(1).name  := 'Authorization';
       apex_web_service.g_request_headers(1).value := 'Bearer '||l_access_token;
    
       apex_web_service.g_request_headers(2).name  := 'Accept';
       apex_web_service.g_request_headers(2).value := 'application/json';
    
           l_clob := apex_web_service.make_rest_request(
                p_url         => g_labels_url,
                p_http_method => 'GET',
                p_wallet_path => wallet_path,
                p_wallet_pwd  => wallet_pwd);
                
      l_resp:=JSON_OBJECT_T(l_clob);
      
      if l_resp.has('error') then
         l_error_text:=l_resp.get_String('error');
         l_error_desc:=l_resp.get_String('error_description');

         v_logs_id := pls_logger.log_error(p_proc_name             => 'get_labels_list', 
                                           p_diagnostic_level      => 'ERROR', 
                                           p_additional_parameter  => 'error='||l_error_text||', error_description='||l_error_desc, 
                                           p_request               => null, 
                                           p_responce              => l_clob);
      else
         if l_resp.has('labels') then
            l_labelsArray  := l_resp.get_Array('labels');
            
              FOR i IN 0 .. l_labelsArray.get_size - 1 LOOP
                 l_label:=TREAT(l_labelsArray.get(i) AS JSON_OBJECT_T);                  
                 parse_label(l_label);
              END LOOP;   

         end if;

       commit;

      end if;
   
    exception when others then 
    
            v_logs_id := pls_logger.log_error(p_proc_name         => 'get_labels_list', 
                                          p_diagnostic_level      => 'ERROR', 
                                          p_additional_parameter  => null, 
                                          p_request               => null, 
                                          p_responce              => l_clob);  
    end;

    PROCEDURE get_users_messages_list 
    AS
       l_rec                  messages%rowtype;
       l_clob                 CLOB;
       l_resp                 JSON_OBJECT_T;
       l_message              JSON_OBJECT_T;
       l_error_text           VARCHAR2(512 CHAR);
       l_error_desc           VARCHAR2(1024 CHAR);       
       l_messageArray         JSON_ARRAY_T;
       l_nextPageToken        VARCHAR2(30 CHAR);       
       l_resultSizeEstimate   number;
       l_cnt                  number:=0;
       l_messages_url         varchar2(256);
    BEGIN

         if l_access_token is null then
            setACCESSTocken;
         end if;

        apex_web_service.g_request_headers.delete;
        apex_web_service.g_request_headers(1).name  := 'Authorization';
        apex_web_service.g_request_headers(1).value := 'Bearer '||l_access_token;

        apex_web_service.g_request_headers(2).name  := 'Accept';
        apex_web_service.g_request_headers(2).value := 'application/json';

    loop

      if l_nextPageToken is not null then
         l_messages_url:=g_messages_url||'?maxResults=1000&pageToken='||l_nextPageToken;
      else 
         l_messages_url:=g_messages_url||'?maxResults=1000';
      end if;
      
      l_nextPageToken:=null;
      
       l_clob := apex_web_service.make_rest_request(
            p_url         => l_messages_url,
            p_http_method => 'GET',
            p_wallet_path => wallet_path,
            p_wallet_pwd  => wallet_pwd);

       l_resp:=JSON_OBJECT_T(l_clob);

        if l_resp.has('error') then
           l_error_text:=l_resp.get_String('error');
           l_error_desc:=l_resp.get_String('error_description');

        v_logs_id := pls_logger.log_error(p_proc_name             => 'get_users_messages_list', 
                                          p_diagnostic_level      => 'ERROR', 
                                          p_additional_parameter  => 'error='||l_error_text||', error_description='||l_error_desc, 
                                          p_request               => null, 
                                          p_responce              => l_clob);
             exit;
        else

           if l_resp.has('messages') then
              l_messageArray  := l_resp.get_Array('messages');
              
              
              if l_resp.has('nextPageToken') then
                 l_nextPageToken:=l_resp.get_String('nextPageToken');
              end if;

              if l_resp.has('resultSizeEstimate') then
                 l_resultSizeEstimate:=l_resp.get_Number('resultSizeEstimate');
              end if;
              l_cnt:=l_cnt+l_resultSizeEstimate;

              FOR i IN 0 .. l_messageArray.get_size - 1 LOOP
                 l_message:=TREAT(l_messageArray.get(i) AS JSON_OBJECT_T); 
                 
                 l_rec.id       := l_message.get_String('id');
                 l_rec.threadid := l_message.get_String('threadId');
                 l_rec.MODIFY_TIME := sysdate;
                 l_rec.MARKED_FOR_DELETE := 'N';
                 
                 insert /*+ ignore_row_on_dupkey_index (messages MESSAGES_PK) */ into messages values l_rec;
                 
              end loop;

              commit;
           
           end if;   
         exit when l_nextPageToken is null;
        end if;
     end loop;
     
    exception when others then 
    
            v_logs_id := pls_logger.log_error(p_proc_name         => 'get_users_messages_list', 
                                          p_diagnostic_level      => 'ERROR', 
                                          p_additional_parameter  => 'message_id='||l_rec.id, 
                                          p_request               => null, 
                                          p_responce              => l_clob);  
    END get_users_messages_list;

    procedure get_message (p_message_id in varchar2)
    as
       l_resp                 JSON_OBJECT_T;
       l_error_text           VARCHAR2(512 CHAR);
       l_error_desc           VARCHAR2(1024 CHAR);       
       l_clob                 CLOB;
    begin
         if l_access_token is null then
            setACCESSTocken;
         end if;

        apex_web_service.g_request_headers.delete;
        apex_web_service.g_request_headers(1).name  := 'Authorization';
        apex_web_service.g_request_headers(1).value := 'Bearer '||l_access_token;

        apex_web_service.g_request_headers(2).name  := 'Accept';
        apex_web_service.g_request_headers(2).value := 'application/json';
        
       l_clob := apex_web_service.make_rest_request(
            p_url         => g_messages_url||'/'||p_message_id,
            p_http_method => 'GET',
            p_wallet_path => wallet_path,
            p_wallet_pwd  => wallet_pwd);

       l_resp:=JSON_OBJECT_T(l_clob);

        if l_resp.has('error') then
           l_error_text:=l_resp.get_String('error');
           l_error_desc:=l_resp.get_String('error_description');

        v_logs_id := pls_logger.log_error(p_proc_name             => 'get_message', 
                                          p_diagnostic_level      => 'ERROR', 
                                          p_additional_parameter  => 'error='||l_error_text||', error_description='||l_error_desc, 
                                          p_request               => null, 
                                          p_responce              => l_clob);
        else

          parse_message (p_message_id, l_resp);
        
       end if;
       
    exception when others then 
    
            v_logs_id := pls_logger.log_error(p_proc_name         => 'get_message', 
                                          p_diagnostic_level      => 'ERROR', 
                                          p_additional_parameter  => 'message_id='||p_message_id, 
                                          p_request               => null, 
                                          p_responce              => l_clob);
    end;

    procedure modify_labels (p_email in varchar2, p_addlabel_ids in varchar2, p_removeLabels_id in varchar2)
    as
      l_addLabels     JSON_ARRAY_T:=JSON_ARRAY_T(p_addlabel_ids);
      l_removeLabels  JSON_ARRAY_T:=JSON_ARRAY_T(p_removeLabels_id);
      l_IDs           JSON_ARRAY_T:=JSON_ARRAY_T();
      l_request       JSON_OBJECT_T:=JSON_OBJECT_T();
      l_resp          JSON_OBJECT_T;
      l_clob          CLOB;
      l_error_text    VARCHAR2(512 CHAR);
      l_error_desc    VARCHAR2(1024 CHAR);       
       cursor cur(l_email VARCHAR2) is select id from messages where MESSAGE_FROM = l_email;  
       l_ids_local     dbms_sql.varchar2s;
    begin

        if l_access_token is null then
           setACCESSTocken;
        end if;

        apex_web_service.g_request_headers.delete;
        apex_web_service.g_request_headers(1).name  := 'Authorization';
        apex_web_service.g_request_headers(1).value := 'Bearer '||l_access_token;
        apex_web_service.g_request_headers(2).name  := 'Accept';
        apex_web_service.g_request_headers(2).value := 'application/json';
        apex_web_service.g_request_headers(3).name  := 'Content-Type';
        apex_web_service.g_request_headers(3).value := 'application/json';

         open cur(p_email);
             loop
              FETCH cur BULK COLLECT INTO l_ids_local LIMIT 1000;
                EXIT WHEN l_ids_local.COUNT = 0;
                  l_request :=JSON_OBJECT_T();
                  l_IDs     :=JSON_ARRAY_T();
        
                for x in 1 .. l_ids_local.count loop
                    l_IDs.append(l_ids_local(x));
                end loop;

         l_request.put('ids', l_IDs);
         l_request.put('addLabelIds',l_addLabels);
         l_request.put('removeLabelIds',l_removeLabels);

         l_clob := apex_web_service.make_rest_request(p_url         => g_messages_url||'/batchModify',
                                                     p_http_method => 'POST',
                                                     p_body        => l_request.stringify,
                                                     p_wallet_path => wallet_path,
                                                     p_wallet_pwd  => wallet_pwd);

        if l_clob is not null then
           l_resp:=JSON_OBJECT_T(l_clob);

           if l_resp.has('error') then
              l_error_text:=l_resp.get_String('error');
              l_error_desc:=l_resp.get_String('error_description');

              v_logs_id := pls_logger.log_error(p_proc_name             => 'modify_labels', 
                                                p_diagnostic_level      => 'ERROR', 
                                                p_additional_parameter  => 'error='||l_error_text||', error_description='||l_error_desc, 
                                                p_request               => l_request.stringify, 
                                                p_responce              => l_clob);
           end if;
         exit;
        end if;

        if apex_web_service.g_status_code <> 204 then
        
            v_logs_id := pls_logger.log_error(p_proc_name             => 'modify_labels', 
                                              p_diagnostic_level      => 'ERROR', 
                                              p_additional_parameter  => 'status_code='||apex_web_service.g_status_code, 
                                              p_request               => l_request.stringify, 
                                              p_responce              => l_clob);
            exit;
        end if;
        end loop;
       close cur;
    exception when others then 
    
            v_logs_id := pls_logger.log_error(p_proc_name         => 'modify_labels', 
                                          p_diagnostic_level      => 'ERROR', 
                                          p_additional_parameter  => 'email='||p_email||', addlabel_ids='||p_addlabel_ids||', removeLabels_id='||p_removeLabels_id, 
                                          p_request               => l_request.stringify, 
                                          p_responce              => l_clob);
    end;

    procedure modify_labels (p_ids in JSON_ARRAY_T, p_addlabel_ids in varchar2, p_removeLabels_id in varchar2)
    as
      l_addLabels     JSON_ARRAY_T:=JSON_ARRAY_T(p_addlabel_ids);
      l_removeLabels  JSON_ARRAY_T:=JSON_ARRAY_T(p_removeLabels_id);
      l_request       JSON_OBJECT_T:=JSON_OBJECT_T();
      l_resp          JSON_OBJECT_T;
      l_clob          CLOB;
      l_error_text    VARCHAR2(512 CHAR);
      l_error_desc    VARCHAR2(1024 CHAR);       
    begin

        if l_access_token is null then
           setACCESSTocken;
        end if;

        apex_web_service.g_request_headers.delete;
        apex_web_service.g_request_headers(1).name  := 'Authorization';
        apex_web_service.g_request_headers(1).value := 'Bearer '||l_access_token;
        apex_web_service.g_request_headers(2).name  := 'Accept';
        apex_web_service.g_request_headers(2).value := 'application/json';
        apex_web_service.g_request_headers(3).name  := 'Content-Type';
        apex_web_service.g_request_headers(3).value := 'application/json';

         l_request.put('ids', p_ids);
         l_request.put('addLabelIds',l_addLabels);
         l_request.put('removeLabelIds',l_removeLabels);

         l_clob := apex_web_service.make_rest_request(p_url         => g_messages_url||'/batchModify',
                                                     p_http_method => 'POST',
                                                     p_body        => l_request.stringify,
                                                     p_wallet_path => wallet_path,
                                                     p_wallet_pwd  => wallet_pwd);

        if l_clob is not null then
           l_resp:=JSON_OBJECT_T(l_clob);

           if l_resp.has('error') then
              l_error_text:=l_resp.get_String('error');
              l_error_desc:=l_resp.get_String('error_description');

              v_logs_id := pls_logger.log_error(p_proc_name             => 'modify_labels array', 
                                                p_diagnostic_level      => 'ERROR', 
                                                p_additional_parameter  => 'error='||l_error_text||', error_description='||l_error_desc, 
                                                p_request               => l_request.stringify, 
                                                p_responce              => l_clob);
           end if;
        end if;

        if apex_web_service.g_status_code <> 204 then
        
            v_logs_id := pls_logger.log_error(p_proc_name             => 'modify_labels array', 
                                              p_diagnostic_level      => 'ERROR', 
                                              p_additional_parameter  => 'status_code='||apex_web_service.g_status_code, 
                                              p_request               => l_request.stringify, 
                                              p_responce              => l_clob);
        end if;

    exception when others then 
    
            v_logs_id := pls_logger.log_error(p_proc_name         => 'modify_labels array', 
                                          p_diagnostic_level      => 'ERROR', 
                                          p_additional_parameter  => 'addlabel_ids='||p_addlabel_ids||', removeLabels_id='||p_removeLabels_id, 
                                          p_request               => l_request.stringify, 
                                          p_responce              => l_clob);
    end;


    procedure delete_messages (p_email in varchar2)
    as
       l_IDs           JSON_ARRAY_T:=JSON_ARRAY_T();
       l_request       JSON_OBJECT_T:=JSON_OBJECT_T();
       l_resp          JSON_OBJECT_T;       
       l_clob          CLOB;
       l_error_text    VARCHAR2(512 CHAR);
       l_error_desc    VARCHAR2(1024 CHAR);
       cursor cur(l_email VARCHAR2) is select id from messages where MESSAGE_FROM = l_email and MARKED_FOR_DELETE = 'Y' and DELETED_AT is null;  
       l_ids_local     dbms_sql.varchar2s;
    begin

        if l_access_token is null then
           setACCESSTocken;
        end if;

        apex_web_service.g_request_headers.delete;
        apex_web_service.g_request_headers(1).name  := 'Authorization';
        apex_web_service.g_request_headers(1).value := 'Bearer '||l_access_token;
        apex_web_service.g_request_headers(2).name  := 'Accept';
        apex_web_service.g_request_headers(2).value := 'application/json';
        apex_web_service.g_request_headers(3).name  := 'Content-Type';
        apex_web_service.g_request_headers(3).value := 'application/json';
    
    open cur(p_email);
     loop
      FETCH cur BULK COLLECT INTO l_ids_local LIMIT 1000;
        EXIT WHEN l_ids_local.COUNT = 0;
          l_request :=JSON_OBJECT_T();
          l_IDs     :=JSON_ARRAY_T();

        for x in 1 .. l_ids_local.count loop
            l_IDs.append(l_ids_local(x));
        end loop;

        l_request.put('ids', l_IDs);

                l_clob := apex_web_service.make_rest_request(p_url         => g_messages_url||'/batchDelete',
                                                             p_http_method => 'POST',
                                                             p_body        => l_request.stringify,
                                                             p_wallet_path => wallet_path,
                                                             p_wallet_pwd  => wallet_pwd);

                if l_clob is not null then
                   l_resp:=JSON_OBJECT_T(l_clob);
        
                   if l_resp.has('error') then
                      l_error_text:=l_resp.get_String('error');
                      l_error_desc:=l_resp.get_String('error_description');
        
                      v_logs_id := pls_logger.log_error(p_proc_name             => 'delete_messages', 
                                                        p_diagnostic_level      => 'ERROR', 
                                                        p_additional_parameter  => 'error='||l_error_text||', error_description='||l_error_desc||', email='||p_email, 
                                                        p_request               => l_request.stringify, 
                                                        p_responce              => l_clob);
                   end if;
                 exit;   
                end if;
        
                if apex_web_service.g_status_code <> 204 then
                
                    v_logs_id := pls_logger.log_error(p_proc_name             => 'delete_messages', 
                                                      p_diagnostic_level      => 'ERROR', 
                                                      p_additional_parameter  => 'status_code='||apex_web_service.g_status_code||', email='||p_email, 
                                                      p_request               => l_request.stringify, 
                                                      p_responce              => l_clob);
                 exit;   
                end if;
                
            forall indx in l_ids_local.first .. l_ids_local.last
            update messages m set m.DELETED_AT = sysdate where m.id = l_ids_local(indx);
            commit;
        end loop;
        close cur;

    exception when others then 
    
            v_logs_id := pls_logger.log_error(p_proc_name         => 'delete_messages', 
                                          p_diagnostic_level      => 'ERROR', 
                                          p_additional_parameter  => 'email='||p_email, 
                                          p_request               => l_request.stringify, 
                                          p_responce              => l_clob);
        rollback;
    end;

    procedure delete_messages_scheduled
    as
       l_IDs           JSON_ARRAY_T:=JSON_ARRAY_T();
       l_request       JSON_OBJECT_T:=JSON_OBJECT_T();
       l_resp          JSON_OBJECT_T;       
       l_clob          CLOB;
       l_error_text    VARCHAR2(512 CHAR);
       l_error_desc    VARCHAR2(1024 CHAR);
       cursor cur is select id from messages where MARKED_FOR_DELETE = 'Y' and DELETED_AT is null; 
       l_ids_local     dbms_sql.varchar2s;
    begin

        if l_access_token is null then
           setACCESSTocken;
        end if;

        apex_web_service.g_request_headers.delete;
        apex_web_service.g_request_headers(1).name  := 'Authorization';
        apex_web_service.g_request_headers(1).value := 'Bearer '||l_access_token;
        apex_web_service.g_request_headers(2).name  := 'Accept';
        apex_web_service.g_request_headers(2).value := 'application/json';
        apex_web_service.g_request_headers(3).name  := 'Content-Type';
        apex_web_service.g_request_headers(3).value := 'application/json';
    
    open cur;
     loop
      FETCH cur BULK COLLECT INTO l_ids_local LIMIT 1000;
        EXIT WHEN l_ids_local.COUNT = 0;
          l_request :=JSON_OBJECT_T();
          l_IDs     :=JSON_ARRAY_T();

        for x in 1 .. l_ids_local.count loop
            l_IDs.append(l_ids_local(x));
        end loop;

        l_request.put('ids', l_IDs);

                l_clob := apex_web_service.make_rest_request(p_url         => g_messages_url||'/batchDelete',
                                                             p_http_method => 'POST',
                                                             p_body        => l_request.stringify,
                                                             p_wallet_path => wallet_path,
                                                             p_wallet_pwd  => wallet_pwd);

                if l_clob is not null then
                   l_resp:=JSON_OBJECT_T(l_clob);
        
                   if l_resp.has('error') then
                      l_error_text:=l_resp.get_String('error');
                      l_error_desc:=l_resp.get_String('error_description');
        
                      v_logs_id := pls_logger.log_error(p_proc_name             => 'delete_messages_scheduled', 
                                                        p_diagnostic_level      => 'ERROR', 
                                                        p_additional_parameter  => 'error='||l_error_text||', error_description='||l_error_desc, 
                                                        p_request               => l_request.stringify, 
                                                        p_responce              => l_clob);
                   end if;
                 exit;   
                end if;
        
                if apex_web_service.g_status_code <> 204 then
                
                    v_logs_id := pls_logger.log_error(p_proc_name             => 'delete_messages_scheduled', 
                                                      p_diagnostic_level      => 'ERROR', 
                                                      p_additional_parameter  => 'status_code='||apex_web_service.g_status_code, 
                                                      p_request               => l_request.stringify, 
                                                      p_responce              => l_clob);
                 exit;   
                end if;
                
            forall indx in l_ids_local.first .. l_ids_local.last
            update messages m set m.DELETED_AT = sysdate where m.id = l_ids_local(indx);
            commit;
        end loop;
        close cur;

    exception when others then 
            v_logs_id := pls_logger.log_error(p_proc_name         => 'delete_messages_scheduled', 
                                          p_diagnostic_level      => 'ERROR', 
                                          p_additional_parameter  => null, 
                                          p_request               => l_request.stringify, 
                                          p_responce              => l_clob);
        rollback;
    end;

END google_api;
/
