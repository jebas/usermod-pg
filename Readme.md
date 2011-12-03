# User Module for Node.js Connect using PostgreSQL

This module creates, controls, and tracks users in a Connect
session.  It also links users to a specific session id without
releasing the information outside of the database.  

## Feature List

<table>
	<tr>
		<th>Features</th>
		<th>Database</th>
		<th>Node</th>
		<th>Client</th>
	</tr>
	<tr>
		<td>Add User</td>
		<td>done</td>
	</tr>
	<tr>
		<td>Validate User</td>
		<td>done</td>
	</tr>
	<tr>
		<td>Login</td>
		<td>done</td>
	</tr>
	<tr>
		<td>Logout</td>
		<td>done</td>
	</tr>
	<tr>
		<td>Change User Name</td>
		<td>done</td>
	</tr>
	<tr>
		<td>Change User Password</td>
		<td>done</td>
	</tr>
	<tr> 
		<td>Change User Email</td>
		<td>done</td>
	</tr>
		<td>Validate New User Email</td>
		<td>done</td>
	<tr>
		<td>User name and password retrieval request</td>
		<td>done</td>
	</tr>
	<tr>
		<td>User name and password retrieval</td>
		<td>done</td>
	</tr>
</table>

This module is used only to establish a valid user to the web site.  
Therefore only the most basic login, log out, and information functions 
are available here.

This module does not include features like avatars, descriptions, 
biographies, ect.  Those features will be added in a profile module.  

Additionally group functions are also placed into a different 
module.  Since administration is given to a group of people, 
the basis of the permissions functions will be a part of the group
module.  

## Requirements
###Production
* Connect-PG
* Express
* PostgreSQL
* PostgreSQL Contrib (specifically uuid_ossp and pgcrypto)
* pgTAP

###Development
* Jasmine-node
