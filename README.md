# plsql-Gmail-API
This project is an example of Google Gmail API. 

![Oracle version](https://img.shields.io/badge/Oracle%20version-12.0.4-blue+)

To get authorization code in google past in browser following link
```
https://accounts.google.com/o/oauth2/v2/auth?client_id=<client id>&redirect_uri=urn:ietf:wg:oauth:2.0:oob&scope=https://www.googleapis.com/auth/gmail.readonly&response_type=code
```
You will get Authorization code in the browser for readonly scope. Please refer to Google API docu for more [authorization scopes][scopes].

In order to use Google API or any other API on the Internet you need to create an oracle wallet and add certificates in there. Hier is [article][wallet] on how to do so, and also how to save certificates from browsers.

Run script createTablespaceandUser.sql from SYS user to create tablespace and user. If you already have a user and tablespace then you can omit this step. Run script setupACL.sql from SYS user to create and assign ACL Lists in the database in order to access public websites on the internet. Run script setupSchema.sql to create objects in Google API schema.

You have to enable and set up your google account Gmail API to use this project. Get Client credentials data and put it into credentials.store.properties on your server where the oracle database is running. Get authorization code from the link posted above and put it in credentials.store.properties as well. You can use authorization code only once for another operation you have to get a new one.


[scopes]: https://developers.google.com/identity/protocols/oauth2/scopes
[wallet]: https://oracle-base.com/articles/misc/utl_http-and-ssl
