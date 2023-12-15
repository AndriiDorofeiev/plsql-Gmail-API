CREATE OR REPLACE EDITIONABLE PACKAGE "GOOGLE_API" 
AS 

 
 procedure get_labels_list;
 procedure get_label (p_label_id in varchar2);
 procedure modify_labels (p_email in varchar2, p_addlabel_ids in varchar2, p_removeLabels_id in varchar2);
 procedure modify_labels (p_ids in JSON_ARRAY_T, p_addlabel_ids in varchar2, p_removeLabels_id in varchar2);
 
 procedure get_users_messages_list;
 procedure get_message (p_message_id in varchar2);
 
 procedure get_message_attachment (p_message_id in varchar2, p_attachment_id in varchar2);
 function  get_message_attachment (p_message_id in varchar2, p_attachment_id in varchar2) RETURN BLOB;
 
 procedure parse_message (p_message_id in varchar2, p_message_body in JSON_OBJECT_T);
 
 procedure delete_messages (p_email in varchar2);
 procedure delete_messages_scheduled;
  
END google_api;
/
