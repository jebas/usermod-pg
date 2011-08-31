# User Module for Node.js Connect using PostgreSQL

This module creates, controls, and tracks users in a Connect
session.  It also links users to a specific session id without
releasing the information outside of the database.  

## Feature List
* Add User
* Validate New User
* Delete User
* Login
* Logout
* Update User Name
* Update User Password
* Update Email Address
* Forgot password
* Add Group
* Delete Group
* Assign User to Group
* Assign Another Group to a Group
* Control permissions
* Set Controls for User Function Permissions

This module does not include features like avatars, descriptions, 
biographies, ect.  Those features should be added in a profile module.  

## Requirements
###Production
* Connect-PG
* Express
* PostgreSQL
* PostgreSQL Contrib (specifically uuid_ossp and pgcrypto)
* pgTAP

###Development
* Jasmine-node

## ToDo 
* Figure out how to test for SQL errors. (Left a place marker for these.)
* How to use pgTap for installing an upgrading the database.
* Adding the group functions: create, delete, add user, add owner.
* Adding a group for admin functions.  
* Make the admin user part of the admin group.