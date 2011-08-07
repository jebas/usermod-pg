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
* PostgreSQL Contrib (specifically uuid_ossp and pgcrypto)

###Development
* Jasmine-node
* pgTAP

## ToDo 
* Figure out how to test for SQL errors. (Left a place marker for these.)
* How to use pgTap for installing an upgrading the database.
* Adding the group functions: create, delete, add user, add owner.
* Adding a group for admin functions.  
* Make the admin user part of the admin group.