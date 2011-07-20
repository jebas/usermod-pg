# User Module for Node.js Connect using PostgreSQL

This module creates, controls, and tracks users in a Connect
session.  It also links users to a specific session id without
releasing the information outside of the database.  

## Requirements
###Production
* Connect-PG
* Nodemailer
* Express
* PostgreSQL
* PostgreSQL Contrib (specifically uuid_ossp)

###Development
* Jasmine-node
* pgTAP

## ToDo 
* <del>Add user from a form.</del>
* Have the system use email to check the new user (Spam protection).
* Add Delete user functions (This is to remove pg from the JavaScript tests.)
* Create a basic template for the user pages.
* Add a hidden field to the new user form to catch spammers.
* Add a reset password function.
* Protect user anonymous from changes.
* Add functions to activate and deactivate users.
* Make sure user.sessions remained linked if user name changes.
* Give the users the ability to log in.  
* Add the ability to create user groups.  