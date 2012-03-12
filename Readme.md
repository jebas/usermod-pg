# UserMod-PG

Using the connect-pg module, this module will link the user to a session as he logs in and out of the system.  It also provides a series of basic functions for creating and maintaining users.

This module does not include functions for biographies, avatars, and other related information.  This is strictly an access control module.  

## Requirements
* Production
* * [connect-pg](https://github.com/jebas/connect-pg) 1.1.0 or later.
* * [Connect](https://github.com/senchalabs/connect) 1.5.0 or later, or [Express](http://expressjs.com/) 2.30 or later.
* * [PostgreSQL](http://www.postgresql.org) 9.0 or later.
* * PostgreSQL Contrib (specifically uuid_ossp and pgcrypto).
* * [pgtap](http://pgtap.org) 
* Development
* * [jasmine-node](https://github.com/mhevery/jasmine-node)

## Feature List

* Create New User
* Validate New User Email
* Log into a session
* Log out of a session
* Change User's name
* Change User's password
* Change User's email
* Validate User's new email address
* Request forgotten User name and password retrieval
* Retrieve User's name and assign new password 

## Installation

1. *Standard Method:* npm install usermod-pg
	
	*Manual Method:* [Download](https://github.com/jebas/usermod-pg) the files to your server.  The only file your script needs access to is usermod-pg.js found in the lib directory.
  
1. Follow the installation procedure for installing [connect-pg](https://github.com/jebas/connect-pg).

1. Follow the directions for installing uuid_ossp and pgcrypto into root schema of the database.

1. As the superuser for the database, install the functions that test, install, and upgrade the database. As shown in the following example:
	
	`psql -d {database name} -U postgres -f {path to file}/usermod-install.sql`

1. As the database's superuser, run the database correction function.  This will install the tables and functions into a new database, or it will update an existing database to add the new features.  The following is an example of the command:

	`psql -d {database name} -U postgres -c 'select correct_user()'`

##Usage

This module is only bound to connect-pg for session information.  The actual function calls are independent of both Express and Connect. They could easily be called through Socket.IO functions as long as the session information is established.

All of the functions listed here use a standard callback function style.  `callback(err, result)`.  If the function is successful, err will be null.  If the function fails, err will have error information.

###Functions

* `getUser(sessionID, callback)`

	Returns the user name for the present session.

* `login(sessionID, username, password, callback)`

	This logs a user into an existing session.

* `logout(sessionID, callback)`

	This logs the user out of the session, and reassigns the session back to anonymous.

* `addUser(name, password, email, callback)`

	This function adds an inactive user to the database.  This user cannot log into the system until the email is verified.  The function returns the email address and a uuid.  Additional code can be written to email the uuid as a link that can be used verify a user and not some SPAM engine.

* `validateUser(link, callback)`

	This takes the link provided in addUser, and makes the user active.  Once the link is entered, the user can log into the system.

	If you don't want to validate the email address, you can take the link provided in addUser, and immediately run it through validateUser.  This will make the user active without requiring any additional steps.

* `changeName(sessionID, name, password, callback)`

	This function allows the logged in user to change their user name to something else, as long as it does not exist in the database.  The password is required to prevent someone from changing the user name of a user who left their session unattended.

* `changePassword(sessionID, newPassword, oldPassword, callback)`

	This function allows a logged in user to change their password.  The old password is required to prevent someone from taking advantage of an unattended session.

* `changeEmail(sessionID, email, password, callback)`

	This function allows the logged in user to request a change in the email address.  The password is required to prevent someone from taking advantage of an unattended session.

	This function returns a the new email address and a uuid that can be used to create a verification link.

* `validateEmail(link, email)`

	Once this function receives the link from the changeEmail function, it will update the user's email address.

* `retreiveUserRequest(email, callback)`

	This function is for the people who have forgotten their user names or passwords.  It returns an email address and a uuid that can be used to create a link to this request.  It does nothing more than create the request.

* `retreiveUser(link, callback)`

	Once this function receives the link from the above function, it returns the user name and a newly created password for the user.  With that information, the user should be able to log into the system.

##Development

To run tests for the database run `pg_prove -d {database} --runtests` as the database superuser.

To run the JavaScript tests, follow the directions in the spec file found in the spec directory.  This will set up the database for running the tests.  Once done, run `jasmine-node spec` to run the tests.

## LICENSE

This software is using the [MIT](./usermod-pg/blob/master/LICENSE) to match 
the connect-pg license.
